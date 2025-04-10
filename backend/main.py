from fastapi import FastAPI, Depends, HTTPException, status, Body, UploadFile, File, Form, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
import os
import socket
from dotenv import load_dotenv
import shutil
import uuid
from pathlib import Path
from fastapi.staticfiles import StaticFiles
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# MongoDB connection
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
client = AsyncIOMotorClient(MONGODB_URL)
db = client.learnlive

# File upload settings
UPLOAD_DIR = "uploads"
Path(UPLOAD_DIR).mkdir(exist_ok=True)

# JWT settings
SECRET_KEY = os.getenv("SECRET_KEY", "your-very-secret-key-123")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

app = FastAPI(title="LearnLive API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class UserBase(BaseModel):
    email: str
    name: str
    role: str
    class_level: Optional[str] = None

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class CourseBase(BaseModel):
    title: str
    description: str
    grade: str
    price: float

class CourseCreate(CourseBase):
    pass

class Course(CourseBase):
    id: str
    teacher_id: str
    teacher_name: str
    students: Optional[List[str]] = []
    thumbnail: Optional[str] = None
    modules: Optional[List[str]] = []
    created_at: datetime

    class Config:
        from_attributes = True

class SessionBase(BaseModel):
    title: str
    description: str
    module_id: Optional[str] = None
    course: Optional[str] = None
    date: str
    time: str
    duration: int
    teacher: str

class SessionCreate(SessionBase):
    pass

class Session(SessionBase):
    id: str
    meeting_link: Optional[str] = None
    recording_link: Optional[str] = None
    attendees: Optional[List[str]] = []

    class Config:
        from_attributes = True

class PaymentRequest(BaseModel):
    course_id: str
    amount: float
    payment_method: Optional[str] = "card"
    card_details: Optional[Dict[str, Any]] = None

class PaymentResponse(BaseModel):
    payment_id: str
    status: str
    message: str
    transaction_date: datetime
    course_id: str
    amount: float

class CourseMaterialBase(BaseModel):
    title: str
    description: str
    type: str  # 'note', 'pdf', 'video', 'link', etc.

class CourseMaterialCreate(CourseMaterialBase):
    content: Optional[str] = None
    file_url: Optional[str] = None
    external_url: Optional[str] = None

class CourseMaterial(CourseMaterialBase):
    id: str
    course_id: str
    content: Optional[str] = None
    file_url: Optional[str] = None
    external_url: Optional[str] = None
    created_at: datetime
    created_by: str
    file_name: Optional[str] = None
    file_size: Optional[int] = None

    class Config:
        from_attributes = True

# Helper functions
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

async def get_user(email: str):
    user = await db.users.find_one({"email": email})
    if user:
        user["id"] = str(user["_id"])
        return user
    return None

async def authenticate_user(email: str, password: str):
    user = await get_user(email)
    if not user:
        return False
    if not verify_password(password, user["password"]):
        return False
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    user = await get_user(email=token_data.email)
    if user is None:
        raise credentials_exception
    return user

# Routes
@app.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    user = await authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["email"]}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/users", response_model=User)
async def create_user(user: UserCreate):
    db_user = await get_user(user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = get_password_hash(user.password)
    user_dict = user.dict()
    user_dict.pop("password")
    user_dict["password"] = hashed_password
    user_dict["created_at"] = datetime.utcnow()
    
    result = await db.users.insert_one(user_dict)
    user_dict["id"] = str(result.inserted_id)
    
    return user_dict

@app.get("/users/me", response_model=User)
async def read_users_me(current_user: dict = Depends(get_current_user)):
    current_user["id"] = str(current_user["_id"])
    return current_user

@app.put("/users/me/class")
async def update_class_level(class_data: dict = Body(...), current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "student":
        raise HTTPException(status_code=400, detail="Only students can update class level")
    
    await db.users.update_one(
        {"_id": ObjectId(current_user["_id"])},
        {"$set": {"class_level": class_data["class_level"]}}
    )
    
    updated_user = await db.users.find_one({"_id": ObjectId(current_user["_id"])})
    updated_user["id"] = str(updated_user["_id"])
    
    return updated_user

@app.get("/courses", response_model=List[Course])
async def get_courses(grade: Optional[str] = None, current_user: dict = Depends(get_current_user)):
    query = {}
    if grade:
        query["grade"] = grade
    
    courses = []
    async for course in db.courses.find(query):
        course["id"] = str(course["_id"])
        courses.append(course)
    return courses

@app.get("/courses/{course_id}", response_model=Course)
async def get_course(course_id: str, current_user: dict = Depends(get_current_user)):
    if not ObjectId.is_valid(course_id):
        raise HTTPException(status_code=400, detail="Invalid course ID format")
    
    course = await db.courses.find_one({"_id": ObjectId(course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    course["id"] = str(course["_id"])
    return course

@app.get("/course/enrolled", response_model=List[Course])
async def get_enrolled_courses(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    
    courses = []
    async for course in db.courses.find({"students": user_id}):
        course["id"] = str(course["_id"])
        courses.append(course)
    
    return courses

@app.post("/courses", response_model=Course)
async def create_course(course: CourseCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=400, detail="Only teachers can create courses")
    
    course_dict = course.dict()
    course_dict["teacher_id"] = str(current_user["_id"])
    course_dict["teacher_name"] = current_user["name"]
    course_dict["students"] = []
    course_dict["created_at"] = datetime.utcnow()
    
    result = await db.courses.insert_one(course_dict)
    course_dict["id"] = str(result.inserted_id)
    
    return course_dict

@app.post("/courses/{course_id}/enroll")
async def enroll_in_course(course_id: str, current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    
    if not ObjectId.is_valid(course_id):
        raise HTTPException(status_code=400, detail="Invalid course ID format")
    
    course = await db.courses.find_one({"_id": ObjectId(course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    if "students" in course and user_id in course["students"]:
        raise HTTPException(status_code=400, detail="Already enrolled in this course")
    
    await db.courses.update_one(
        {"_id": ObjectId(course_id)},
        {"$push": {"students": user_id}}
    )
    
    return {"message": "Successfully enrolled in course"}

@app.post("/payments", response_model=PaymentResponse)
async def process_payment(payment: PaymentRequest, current_user: dict = Depends(get_current_user)):
    if not ObjectId.is_valid(payment.course_id):
        raise HTTPException(status_code=400, detail="Invalid course ID format")
    
    course = await db.courses.find_one({"_id": ObjectId(payment.course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    payment_id = str(ObjectId())
    
    payment_record = {
        "payment_id": payment_id,
        "user_id": str(current_user["_id"]),
        "course_id": payment.course_id,
        "amount": payment.amount,
        "status": "success",
        "payment_method": payment.payment_method,
        "transaction_date": datetime.utcnow()
    }
    
    await db.payments.insert_one(payment_record)
    
    user_id = str(current_user["_id"])
    if user_id not in course.get("students", []):
        await db.courses.update_one(
            {"_id": ObjectId(payment.course_id)},
            {"$push": {"students": user_id}}
        )
    
    return {
        "payment_id": payment_id,
        "status": "success",
        "message": "Payment processed successfully",
        "transaction_date": datetime.utcnow(),
        "course_id": payment.course_id,
        "amount": payment.amount
    }

# Course Materials Endpoints
@app.get("/courses/{course_id}/materials", response_model=List[CourseMaterial])
async def get_course_materials(course_id: str, current_user: dict = Depends(get_current_user)):
    if not ObjectId.is_valid(course_id):
        raise HTTPException(status_code=400, detail="Invalid course ID format")
    
    course = await db.courses.find_one({"_id": ObjectId(course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    user_id = str(current_user["_id"])
    is_teacher = current_user["role"] == "teacher"
    is_course_teacher = course.get("teacher_id") == user_id
    is_enrolled = user_id in course.get("students", [])
    
    if not (is_teacher or is_course_teacher or is_enrolled):
        raise HTTPException(
            status_code=403, 
            detail="You must be the teacher or enrolled in the course to view materials"
        )
    
    materials = []
    async for material in db.course_materials.find({"course_id": course_id}).sort("created_at", -1):
        material["id"] = str(material["_id"])
        materials.append(material)
    
    return materials

@app.post("/courses/{course_id}/materials", response_model=CourseMaterial)
async def create_course_material(
    course_id: str,
    title: str = Form(...),
    description: str = Form(...),
    type: str = Form(...),
    content: Optional[str] = Form(None),
    external_url: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    current_user: dict = Depends(get_current_user)
):
    logger.info(f"Creating material for course {course_id}")
    
    if not ObjectId.is_valid(course_id):
        raise HTTPException(status_code=400, detail="Invalid course ID format")
    
    course = await db.courses.find_one({"_id": ObjectId(course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    user_id = str(current_user["_id"])
    if course.get("teacher_id") != user_id:
        raise HTTPException(
            status_code=403, 
            detail="Only the course teacher can add materials"
        )
    
    file_url = None
    file_name = None
    file_size = None
    
    if file:
        try:
            file_ext = file.filename.split(".")[-1] if "." in file.filename else ""
            unique_filename = f"{uuid.uuid4()}.{file_ext}"
            file_path = os.path.join(UPLOAD_DIR, unique_filename)
            
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            
            file_url = f"/uploads/{unique_filename}"
            file_name = file.filename
            file_size = os.path.getsize(file_path)
            
            if not type:
                if file_ext.lower() in ["pdf", "doc", "docx"]:
                    type = "document"
                elif file_ext.lower() in ["jpg", "jpeg", "png", "gif"]:
                    type = "image"
                elif file_ext.lower() in ["mp4", "mov", "avi"]:
                    type = "video"
                else:
                    type = "file"
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error saving file: {str(e)}")
    
    material_dict = {
        "title": title,
        "description": description,
        "type": type,
        "content": content,
        "external_url": external_url,
        "file_url": file_url,
        "file_name": file_name,
        "file_size": file_size,
        "course_id": course_id,
        "created_at": datetime.utcnow(),
        "created_by": user_id
    }
    
    result = await db.course_materials.insert_one(material_dict)
    material_dict["id"] = str(result.inserted_id)
    
    return material_dict

@app.get("/courses/{course_id}/materials/{material_id}", response_model=CourseMaterial)
async def get_course_material(
    course_id: str,
    material_id: str,
    current_user: dict = Depends(get_current_user)
):
    if not ObjectId.is_valid(course_id) or not ObjectId.is_valid(material_id):
        raise HTTPException(status_code=400, detail="Invalid ID format")
    
    course = await db.courses.find_one({"_id": ObjectId(course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    user_id = str(current_user["_id"])
    is_teacher = current_user["role"] == "teacher"
    is_course_teacher = course.get("teacher_id") == user_id
    is_enrolled = user_id in course.get("students", [])
    
    if not (is_teacher or is_course_teacher or is_enrolled):
        raise HTTPException(
            status_code=403, 
            detail="You must be the teacher or enrolled in the course to view this material"
        )
    
    material = await db.course_materials.find_one({
        "_id": ObjectId(material_id),
        "course_id": course_id
    })
    
    if not material:
        raise HTTPException(status_code=404, detail="Material not found")
    
    material["id"] = str(material["_id"])
    return material

@app.delete("/courses/{course_id}/materials/{material_id}")
async def delete_course_material(
    course_id: str,
    material_id: str,
    current_user: dict = Depends(get_current_user)
):
    if not ObjectId.is_valid(course_id) or not ObjectId.is_valid(material_id):
        raise HTTPException(status_code=400, detail="Invalid ID format")
    
    course = await db.courses.find_one({"_id": ObjectId(course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    user_id = str(current_user["_id"])
    if course.get("teacher_id") != user_id:
        raise HTTPException(
            status_code=403, 
            detail="Only the course teacher can delete materials"
        )
    
    material = await db.course_materials.find_one({
        "_id": ObjectId(material_id),
        "course_id": course_id
    })
    
    if not material:
        raise HTTPException(status_code=404, detail="Material not found")
    
    if material.get("file_url"):
        try:
            file_path = material["file_url"].lstrip("/")
            if os.path.exists(file_path):
                os.remove(file_path)
        except Exception as e:
            logger.error(f"Error deleting file: {str(e)}")
    
    result = await db.course_materials.delete_one({
        "_id": ObjectId(material_id),
        "course_id": course_id
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Material not found")
    
    return {"message": "Material deleted successfully"}

# Sessions Endpoints
@app.get("/sessions/upcoming", response_model=List[Session])
async def get_upcoming_sessions(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    today = datetime.utcnow().strftime("%Y-%m-%d")
    
    query = {}
    if current_user["role"] == "student":
        enrolled_courses = []
        async for course in db.courses.find({"students": user_id}):
            enrolled_courses.append(str(course["_id"]))
            enrolled_courses.append(course["title"])
        
        query = {
            "date": {"$gte": today},
            "$or": [
                {"course_id": {"$in": enrolled_courses}},
                {"course": {"$in": enrolled_courses}}
            ]
        }
    else:
        query = {
            "date": {"$gte": today},
            "teacher_id": user_id
        }
    
    sessions = []
    async for session in db.sessions.find(query).sort("date", 1).sort("time", 1):
        session["id"] = str(session["_id"])
        sessions.append(session)
    
    return sessions

@app.post("/sessions", response_model=Session)
async def create_session(session: SessionCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "teacher":
        raise HTTPException(status_code=400, detail="Only teachers can create sessions")
    
    session_dict = session.dict()
    session_dict["teacher_id"] = str(current_user["_id"])
    session_dict["attendees"] = []
    session_dict["meeting_link"] = f"https://meet.jit.si/learnlive-session-{ObjectId()}"
    
    result = await db.sessions.insert_one(session_dict)
    session_dict["id"] = str(result.inserted_id)
    
    return session_dict

@app.get("/sessions/{session_id}", response_model=Session)
async def get_session(session_id: str, current_user: dict = Depends(get_current_user)):
    session = await db.sessions.find_one({"_id": ObjectId(session_id)})
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    session["id"] = str(session["_id"])
    
    if current_user["role"] == "student":
        enrolled_courses = []
        async for course in db.courses.find({"students": str(current_user["_id"])}):
            enrolled_courses.append(str(course["_id"]))
            enrolled_courses.append(course["title"])
        
        if session.get("course_id") not in enrolled_courses and session.get("course") not in enrolled_courses:
            raise HTTPException(
                status_code=403, 
                detail="You must be enrolled in the course to access this session"
            )
    
    return session

# Root endpoint
@app.get("/")
async def root():
    return {"message": "Welcome to LearnLive API"}

# Static files serving
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Port finding and server startup
def find_available_port(start_port: int, max_port: int = 65535) -> Optional[int]:
    for port in range(start_port, max_port + 1):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('0.0.0.0', port))
                return port
        except OSError:
            continue
    return None

if __name__ == "__main__":
    import uvicorn
    
    port = find_available_port(5000)
    if port is None:
        raise RuntimeError("No available ports found")
    
    print(f"Starting server on port {port}")
    uvicorn.run(app, host="192.168.29.176", port=port)