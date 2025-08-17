// learnflow_ai/flutter_app/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/screens/lessons_screen.dart';
import 'package:learnflow_ai/screens/add_lesson_screen.dart';
import 'package:learnflow_ai/screens/add_question_screen.dart';
import 'package:learnflow_ai/screens/tutor_ai_screen.dart';
// import 'package:learnflow_ai/screens/admin_panel_screen.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:learnflow_ai/models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _apiService.fetchCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch user data.';
        _isLoading = false;
      });
    }
  }

  void _onLogout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _downloadReport() async {
    try {
      await _apiService.downloadQuizAttemptsReport();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report download started.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LearnFlow AI'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _onLogout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade900,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LearnFlow AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  if (_currentUser != null)
                    Text(
                      'Welcome, ${_currentUser!.username}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Lessons'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LessonsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('AI Chatbot'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TutorAIScreen()),
                );
              },
            ),
            if (_currentUser?.isStaff ?? false)
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.library_add),
                    title: const Text('Add Lesson'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddLessonScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.question_answer),
                    title: const Text('Add Question'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddQuestionScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Download Report'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      _downloadReport();
                    },
                  ),
                  // ListTile(
                  //   leading: const Icon(Icons.admin_panel_settings),
                  //   title: const Text('Admin Panel'),
                  //   onTap: () {
                  //     Navigator.pop(context); // Close the drawer
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                  //     );
                  //   },
                  // ),
                ],
              ),
          ],
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
                ? Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Welcome to LearnFlow AI!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LessonsScreen()),
                          );
                        },
                        child: const Text('Go to Lessons'),
                      ),
                    ],
                  ),
      ),
    );
  }
}