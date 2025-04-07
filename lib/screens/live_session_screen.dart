import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({Key? key}) : super(key: key);

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  bool _hasJoined = false;
  String? _error;
  LiveSession? _session;

  @override
  void initState() {
    super.initState();
    // Initialize session when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  Future<void> _initializeSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final sessionId = args['sessionId'] as String;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null) {
        throw Exception('API_URL not found in environment variables');
      }
      
      final url = Uri.parse('$apiUrl/sessions/$sessionId');
      print('Fetching session details from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Fetch session details response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final sessionData = json.decode(response.body);
        setState(() {
          _session = LiveSession.fromJson(sessionData);
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'You must be enrolled in the course to access this session';
          _isLoading = false;
        });
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _error = responseData['detail'] ?? 'Failed to fetch session details';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Initialize session error: $e');
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinMeeting() async {
    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      // Use the meeting link from the session if available, otherwise generate one
      final meetingUrl = _session?.meetingLink ?? 'https://meet.jit.si/learnlive-session-${DateTime.now().millisecondsSinceEpoch}';
      
      // Launch the meeting URL in browser
      if (await canLaunchUrl(Uri.parse(meetingUrl))) {
        await launchUrl(Uri.parse(meetingUrl), mode: LaunchMode.externalApplication);
        setState(() {
          _isJoining = false;
          _hasJoined = true;
        });
      } else {
        throw 'Could not launch $meetingUrl';
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Session'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Session'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_session?.title ?? 'Live Session'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _session?.title ?? '',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _session?.description ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Make sure your camera and microphone are working properly before joining.',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Join meeting button
              if (_isJoining)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Joining the session...'),
                    ],
                  ),
                )
              else if (_hasJoined)
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Session joined successfully',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The session is now open in your browser.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _joinMeeting,
                      child: const Text('Rejoin Session'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    // Video preview placeholder
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.videocam,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _joinMeeting,
                        icon: const Icon(Icons.video_call),
                        label: const Text('Join Live Session'),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF8852E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 24),
              
              // Session details
              const Text(
                'Session Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Teacher'),
                subtitle: Text(_session?.teacher ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Course'),
                subtitle: Text(_session?.course ?? ''),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Duration'),
                subtitle: Text('${_session?.duration ?? 0} minutes'),
              ),
              
              const SizedBox(height: 24),
              
              // Session controls
              const Text(
                'Session Controls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.mic,
                    label: 'Mute',
                    onPressed: () {},
                  ),
                  _buildControlButton(
                    icon: Icons.videocam,
                    label: 'Video',
                    onPressed: () {},
                  ),
                  _buildControlButton(
                    icon: Icons.screen_share,
                    label: 'Share',
                    onPressed: () {},
                  ),
                  _buildControlButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

