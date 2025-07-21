// learnflow_ai/flutter_app/lib/screens/lessons_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart'; // ADDED: Import DatabaseService
import 'package:learnflow_ai/screens/lesson_detail_screen.dart'; // Ensure this is imported

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance; // Get singleton instance
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLessons(); // Call a new method to handle both local and API fetching
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Try to load from local database first
      print('LessonsScreen: Attempting to load lessons from local database...');
      List<Lesson> localLessons = await _databaseService.getAllLessons();

      if (localLessons.isNotEmpty) {
        setState(() {
          _lessons = localLessons;
          _isLoading = false;
        });
        print('LessonsScreen: Loaded ${localLessons.length} lessons from local database.');
        // Optionally, fetch from API in background to update local data
        _fetchLessonsFromApi(backgroundSync: true);
      } else {
        // 2. If no local data, fetch from API
        print('LessonsScreen: No local lessons found. Fetching from API...');
        await _fetchLessonsFromApi(backgroundSync: false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load lessons: $e';
        _isLoading = false;
      });
      print('LessonsScreen: Error loading lessons (local or API): $e');
    }
  }

  Future<void> _fetchLessonsFromApi({bool backgroundSync = false}) async {
    try {
      final fetchedLessons = await _apiService.fetchLessons();
      if (fetchedLessons.isNotEmpty) {
        setState(() {
          _lessons = fetchedLessons;
          if (!backgroundSync) _isLoading = false; // Only set loading to false if it's the primary fetch
        });
        print('LessonsScreen: Fetched ${fetchedLessons.length} lessons from API.');

        // 3. Save/update lessons in local database
        print('LessonsScreen: Saving/updating lessons to local database...');
        for (var lesson in fetchedLessons) {
          await _databaseService.insertLesson(lesson); // insert or replace
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.purpleAccent.shade400],
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
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _lessons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books, size: 80, color: Colors.white70),
                            SizedBox(height: 20),
                            Text(
                              'No lessons available yet. Check back later!',
                              style: TextStyle(fontSize: 18, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadLessons, // Allows retrying fetch
                              icon: Icon(Icons.refresh),
                              label: Text('Refresh Lessons'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.4),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LessonDetailScreen(lesson: lesson),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      lesson.description ?? 'No description available.',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoChip(Icons.subject, lesson.subject ?? 'N/A', Colors.blueGrey),
                                        _buildInfoChip(Icons.bar_chart, lesson.difficultyLevel ?? 'N/A', Colors.orange),
                                        _buildInfoChip(Icons.numbers, 'v${lesson.version}', Colors.green),
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
      avatar: Icon(icon, size: 18, color: color),
      label: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: color.withOpacity(0.5), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
// This code is part of the LearnFlow AI Flutter application, which provides a lessons screen