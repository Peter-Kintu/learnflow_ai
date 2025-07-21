// learnflow_ai/flutter_app/lib/screens/teacher_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/screens/add_lesson_screen.dart';
import 'package:learnflow_ai/screens/add_question_screen.dart'; // ADDED: Import the new screen

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, Teacher!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 5.0, color: Colors.black38, offset: Offset(1.0, 1.0)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddLessonScreen()),
                  );
                },
                icon: const Icon(Icons.add_box, size: 28),
                label: const Text('Add New Lesson'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // UPDATED: Navigate to AddQuestionScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddQuestionScreen()),
                  );
                },
                icon: const Icon(Icons.quiz, size: 28),
                label: const Text('Add New Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
