// learnflow_ai/flutter_app/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/models/student.dart';
import 'package:learnflow_ai/screens/lessons_screen.dart';
import 'package:learnflow_ai/screens/teacher_dashboard_screen.dart';
import 'package:learnflow_ai/screens/sync_status_screen.dart'; // ADDED: Import SyncStatusScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Student? _currentStudent;
  bool _isLoadingStudent = true;
  String? _studentFetchError;

  @override
  void initState() {
    super.initState();
    _fetchStudentProfile();
  }

  Future<void> _fetchStudentProfile() async {
    setState(() {
      _isLoadingStudent = true;
      _studentFetchError = null;
    });
    try {
      final student = await _apiService.fetchCurrentStudentProfile();
      setState(() {
        _currentStudent = student;
        _isLoadingStudent = false;
      });
    } catch (e) {
      setState(() {
        _studentFetchError = 'Failed to load student profile.';
        _isLoadingStudent = false;
      });
      print('Error fetching student profile: $e');
    }
  }

  String _getWelcomeMessage() {
    if (_isLoadingStudent) {
      return 'Loading...';
    } else if (_studentFetchError != null) {
      return 'Welcome! (Error loading profile)';
    } else if (_currentStudent != null && _currentStudent!.user != null) {
      return 'Welcome, ${_currentStudent!.user!.username}!';
    } else {
      return 'Welcome to LearnFlow AI!';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LearnFlow AI'),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // App Icon/Logo Placeholder
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline, // A more engaging icon
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                // Welcome Message
                Text(
                  _getWelcomeMessage(),
                  style: TextStyle(
                    fontSize: size.width * 0.06, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black38,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),

                // Tagline
                Text(
                  'Your personalized learning journey awaits!',
                  style: TextStyle(
                    fontSize: size.width * 0.035, // Responsive font size
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Action Buttons
                SizedBox(
                  width: size.width * 0.7, // Responsive button width
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LessonsScreen()),
                      );
                    },
                    icon: const Icon(Icons.menu_book, size: 28), // Updated icon
                    label: const Text('Explore Lessons'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // More rounded
                      textStyle: TextStyle(
                        fontSize: size.width * 0.04, // Responsive font size
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 8, // Add shadow
                      shadowColor: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: size.width * 0.7, // Responsive button width
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // UPDATED: Navigate to SyncStatusScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SyncStatusScreen()),
                      );
                    },
                    icon: const Icon(Icons.sync_alt, size: 28), // Updated icon
                    label: const Text('View Sync Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.teal.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      textStyle: TextStyle(
                        fontSize: size.width * 0.04, // Responsive font size
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 8,
                      shadowColor: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Teacher Dashboard Button
                SizedBox(
                  width: size.width * 0.7, // Responsive button width
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to the Teacher Dashboard
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()),
                      );
                    },
                    icon: const Icon(Icons.school, size: 28), // Icon for teacher dashboard
                    label: const Text('Teacher Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700, // Different color for distinction
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
