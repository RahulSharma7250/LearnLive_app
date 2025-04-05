class CourseMaterial {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String type; // 'note', 'pdf', 'video', etc.
  final String? fileUrl;
  final String? content; // For text-based notes
  final DateTime createdAt;

  CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.type,
    this.fileUrl,
    this.content,
    required this.createdAt,
  });

  factory CourseMaterial.fromJson(Map<String, dynamic> json) {
    return CourseMaterial(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      fileUrl: json['file_url'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'title': title,
      'description': description,
      'type': type,
      'file_url': fileUrl,
      'content': content,
    };
  }
}

