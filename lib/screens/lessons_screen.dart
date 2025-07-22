// learnflow_ai/flutter_app/lib/screens/lessons_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:learnflow_ai/screens/lesson_detail_screen.dart';
import 'package:learnflow_ai/models/user.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadLessonsAndUser();
  }

  Future<void> _loadLessonsAndUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _apiService.fetchCurrentUser();
      setState(() {
        _currentUser = user;
      });
      print('LessonsScreen: Fetched current user: ${_currentUser?.username}, isStaff: ${_currentUser?.isStaff}');

      print('LessonsScreen: Attempting to load lessons from local database...');
      List<Lesson> localLessons = await _databaseService.getAllLessons();

      if (localLessons.isNotEmpty) {
        setState(() {
          _lessons = localLessons;
          _isLoading = false;
        });
        print('LessonsScreen: Loaded ${localLessons.length} lessons from local database.');
        _fetchLessonsFromApi(backgroundSync: true);
      } else {
        print('LessonsScreen: No local lessons found. Fetching from API...');
        await _fetchLessonsFromApi(backgroundSync: false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
      print('LessonsScreen: Error loading lessons or user data: $e');
    }
  }

  Future<void> _fetchLessonsFromApi({bool backgroundSync = false}) async {
    try {
      final fetchedLessons = await _apiService.fetchLessons();
      if (fetchedLessons.isNotEmpty) {
        setState(() {
          _lessons = fetchedLessons;
          if (!backgroundSync) _isLoading = false;
        });
        print('LessonsScreen: Fetched ${fetchedLessons.length} lessons from API.');

        print('LessonsScreen: Saving/updating lessons to local database...');
        for (var lesson in fetchedLessons) {
          await _databaseService.insertLesson(lesson);
        }
        print('LessonsScreen: Lessons saved/updated locally.');
      } else {
        if (!backgroundSync) {
          setState(() {
            _errorMessage = 'No lessons found from API.';
            _isLoading = false;
          });
        }
        print('LessonsScreen: No lessons found from API.');
      }
    } catch (e) {
      if (!backgroundSync) {
        setState(() {
          _errorMessage = 'Failed to fetch lessons from API: $e';
          _isLoading = false;
        });
      }
      print('LessonsScreen: Error fetching lessons from API: $e');
    }
  }

  Future<void> _launchDjangoTeacherDashboardUrl({bool downloadPdf = false}) async {
    String url = 'http://localhost:8000/api/teacher-dashboard/';
    if (downloadPdf) {
      url += '?format=pdf';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open/download the teacher dashboard. Please ensure the Django server is running and accessible: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        backgroundColor: Colors.deepPurple.shade900, // Even darker purple for app bar
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_currentUser != null && _currentUser!.isStaff)
            IconButton(
              icon: const Icon(Icons.web_asset_rounded, size: 30), // Larger, rounded icon
              tooltip: 'Go to Teacher Dashboard (Web)',
              onPressed: () => _launchDjangoTeacherDashboardUrl(downloadPdf: false),
            ),
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.download_rounded, size: 30), // Larger, rounded icon
              tooltip: 'Download Teacher Report (PDF)',
              onPressed: () => _launchDjangoTeacherDashboardUrl(downloadPdf: true),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 30), // Larger, rounded icon
            tooltip: 'Refresh Lessons',
            onPressed: _loadLessonsAndUser,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700], // Deeper, richer gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0), // Increased padding
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 19, fontWeight: FontWeight.bold), // Bolder, larger error
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _lessons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.library_books_rounded, size: 100, color: Colors.white70), // Larger, rounded icon
                            const SizedBox(height: 25), // Increased spacing
                            const Text(
                              'No lessons available yet. Check back later!',
                              style: TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w500), // Larger, medium weight
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 25),
                            ElevatedButton.icon(
                              onPressed: _loadLessonsAndUser,
                              icon: const Icon(Icons.refresh_rounded, size: 28), // Larger, rounded icon
                              label: const Text('Refresh Lessons'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurpleAccent.shade700, // More vibrant purple
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18), // Larger button
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded
                                elevation: 10,
                                shadowColor: Colors.deepPurple.shade900.withOpacity(0.7),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(25.0), // Increased padding
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 15), // Increased vertical margin
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Even more rounded
                            elevation: 12, // More shadow
                            shadowColor: Colors.black.withOpacity(0.5),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LessonDetailScreen(lesson: lesson),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(25), // Match card border radius
                              child: Padding(
                                padding: const EdgeInsets.all(30.0), // Increased padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.title,
                                      style: TextStyle(
                                        fontSize: 26, // Larger font
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple.shade800, // Darker purple
                                      ),
                                    ),
                                    const SizedBox(height: 15), // Increased spacing
                                    Text(
                                      lesson.description ?? 'No description available.',
                                      style: TextStyle(
                                        fontSize: 17, // Larger font
                                        color: Colors.grey.shade900, // Even darker grey
                                      ),
                                      maxLines: 4, // Allow more lines
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 25), // Increased spacing
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildInfoChip(Icons.subject_rounded, lesson.subject ?? 'N/A', Colors.blueGrey.shade700),
                                        _buildInfoChip(Icons.bar_chart_rounded, lesson.difficultyLevel ?? 'N/A', Colors.orange.shade700),
                                        _buildInfoChip(Icons.numbers_rounded, 'v${lesson.version}', Colors.green.shade700),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Chip(
      avatar: Icon(icon, size: 22, color: color), // Larger icon
      label: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15), // Slightly larger text
      ),
      backgroundColor: color.withOpacity(0.2), // More opaque background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // More rounded
      side: BorderSide(color: color.withOpacity(0.7), width: 2), // Thicker, clearer border
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // More padding
    );
  }
}
