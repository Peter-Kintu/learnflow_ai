// learnflow_ai/flutter_app/lib/screens/teacher_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/screens/add_lesson_screen.dart';
import 'package:learnflow_ai/screens/add_question_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.deepPurple.shade900, // Even darker purple for app bar
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700], // Deeper, richer gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, Educator!', // More formal welcome
                style: TextStyle(
                  fontSize: 40, // Even larger font
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 15.0, color: Colors.black87, offset: Offset(3.0, 3.0)), // More prominent shadow
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60), // Increased spacing
              _buildDashboardButton(
                context,
                'Add New Lesson',
                Icons.add_box_rounded,
                const AddLessonScreen(),
                Colors.amber.shade700, // Richer amber
              ),
              const SizedBox(height: 30), // Increased spacing
              _buildDashboardButton(
                context,
                'Add New Question',
                Icons.quiz_rounded,
                const AddQuestionScreen(),
                Colors.teal.shade700, // Richer teal
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context, String label, IconData icon, Widget screen, Color bgColor) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.85, // Even wider buttons
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        icon: Icon(icon, size: 35), // Even larger icon
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 22), // Even larger padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), // Larger, bolder text
          elevation: 12, // More shadow
          shadowColor: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }
}
