// learnflow_ai/flutter_app/lib/screens/add_lesson_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/services/api_service.dart';

class AddLessonScreen extends StatefulWidget {
  const AddLessonScreen({super.key});

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String? _difficultyLevel; // Dropdown for difficulty
  final TextEditingController _versionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _submitLesson() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final newLesson = Lesson(
        uuid: '', // Placeholder, Django will assign
        title: _titleController.text,
        description: _descriptionController.text,
        subject: _subjectController.text,
        difficultyLevel: _difficultyLevel,
        version: int.tryParse(_versionController.text) ?? 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdLesson = await _apiService.createLesson(newLesson);

      setState(() {
        _isLoading = false;
      });

      if (createdLesson != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lesson "${createdLesson.title}" created successfully!')),
        );
        _titleController.clear();
        _descriptionController.clear();
        _subjectController.clear();
        _difficultyLevel = null;
        _versionController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create lesson. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Lesson'),
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
          child: Padding(
            padding: const EdgeInsets.all(28.0), // Increased padding
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Card(
                  elevation: 16, // More pronounced shadow
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Even more rounded corners
                  color: Colors.white.withOpacity(0.98), // Almost opaque white for crispness
                  child: Padding(
                    padding: const EdgeInsets.all(32.0), // Increased padding inside card
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Craft a New Learning Module',
                          style: TextStyle(
                            fontSize: 28, // Larger title
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade900, // Darker title color
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30), // Increased spacing

                        _buildTextField(_titleController, 'Lesson Title', 'Please enter a title', Icons.title),
                        _buildTextField(_descriptionController, 'Description', 'Please enter a description', Icons.description, maxLines: 5),
                        _buildTextField(_subjectController, 'Subject', 'Please enter a subject', Icons.subject),

                        _buildDropdownField(
                          'Difficulty Level',
                          _difficultyLevel,
                          ['Easy', 'Medium', 'Hard'],
                          (String? newValue) {
                            setState(() {
                              _difficultyLevel = newValue;
                            });
                          },
                          Icons.bar_chart,
                        ),

                        _buildTextField(_versionController, 'Version (e.g., 1)', 'Please enter a version number', Icons.numbers, keyboardType: TextInputType.number),

                        const SizedBox(height: 50), // Increased spacing
                        Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.deepPurpleAccent) // Brighter loading indicator
                              : ElevatedButton.icon(
                                  onPressed: _submitLesson,
                                  icon: const Icon(Icons.add_box_rounded, size: 30), // Larger, rounded icon
                                  label: const Text('Add Lesson'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurpleAccent.shade700, // More vibrant purple
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20), // Even larger button
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded
                                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), // Larger, bolder text
                                    elevation: 12, // More shadow
                                    shadowColor: Colors.deepPurple.shade900.withOpacity(0.7),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String validationMessage, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0), // Increased vertical padding
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontSize: 17), // Slightly larger text
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.deepPurple.shade800, fontWeight: FontWeight.w600), // Bolder, darker label
          prefixIcon: Icon(icon, color: Colors.deepPurple.shade500), // Slightly brighter icon
          filled: true,
          fillColor: Colors.deepPurple.shade50.withOpacity(0.8), // More opaque fill color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), // Even more rounded corners
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 1.5), // Thicker, clearer border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.deepPurple.shade800, width: 3), // Even thicker focused border
          ),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15), // Adjust padding
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validationMessage;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0), // Increased vertical padding
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.deepPurple.shade800, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: Colors.deepPurple.shade500),
          filled: true,
          fillColor: Colors.deepPurple.shade50.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.deepPurple.shade800, width: 3),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        ),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 17)), // Text style for dropdown items
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a $label';
          }
          return null;
        },
        dropdownColor: Colors.white, // Dropdown background color
      ),
    );
  }
}
