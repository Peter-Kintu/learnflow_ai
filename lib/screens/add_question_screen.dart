// learnflow_ai/flutter_app/lib/screens/add_question_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:uuid/uuid.dart'; // For generating UUIDs on the client side

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final Uuid _uuid = const Uuid(); // Instantiate Uuid

  List<Lesson> _lessons = [];
  bool _isLoadingLessons = true;
  String? _lessonsErrorMessage;

  Lesson? _selectedLesson;
  final TextEditingController _questionTextController = TextEditingController();
  String? _questionType; // 'MCQ' or 'SA'
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  final TextEditingController _correctAnswerTextController = TextEditingController();
  String? _difficultyLevel; // Dropdown for difficulty
  final TextEditingController _expectedTimeSecondsController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLessons(); // Fetch lessons when the screen initializes
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _correctAnswerTextController.dispose();
    _expectedTimeSecondsController.dispose();
    super.dispose();
  }

  Future<void> _fetchLessons() async {
    setState(() {
      _isLoadingLessons = true;
      _lessonsErrorMessage = null;
    });
    try {
      final fetchedLessons = await _apiService.fetchLessons();
      setState(() {
        _lessons = fetchedLessons;
        _isLoadingLessons = false;
      });
    } catch (e) {
      setState(() {
        _lessonsErrorMessage = 'Failed to load lessons: $e';
        _isLoadingLessons = false;
      });
      print('Error fetching lessons for question screen: $e');
    }
  }

  Future<void> _submitQuestion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      List<String>? optionsList;
      if (_questionType == 'MCQ') {
        optionsList = [];
        if (_optionAController.text.isNotEmpty) optionsList.add(_optionAController.text);
        if (_optionBController.text.isNotEmpty) optionsList.add(_optionBController.text);
        if (_optionCController.text.isNotEmpty) optionsList.add(_optionCController.text);
        if (_optionDController.text.isNotEmpty) optionsList.add(_optionDController.text);

        if (optionsList.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MCQ questions require at least two options.')),
          );
          setState(() { _isLoading = false; });
          return;
        }
      }

      // Ensure _selectedLesson is not null before proceeding
      if (_selectedLesson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a lesson for the question.')),
        );
        setState(() { _isLoading = false; });
        return;
      }

      // DEBUGGING PRINTS: Check the lesson ID and UUID before creating the Question object
      print('DEBUG: _selectedLesson.id: ${_selectedLesson!.id}');
      print('DEBUG: _selectedLesson.uuid: ${_selectedLesson!.uuid}');


      final newQuestion = Question(
        uuid: _uuid.v4(), // Generate a UUID client-side
        lessonUuid: _selectedLesson!.uuid, // Keep lessonUuid for Flutter model consistency
        lessonId: _selectedLesson!.id, // CRITICAL: Pass the integer ID of the selected lesson
        questionText: _questionTextController.text,
        questionType: _questionType!,
        options: optionsList,
        correctAnswerText: _correctAnswerTextController.text,
        difficultyLevel: _difficultyLevel,
        expectedTimeSeconds: int.tryParse(_expectedTimeSecondsController.text),
        createdAt: DateTime.now(), // Will be overridden by Django
      );

      final createdQuestion = await _apiService.createQuestion(newQuestion);

      setState(() {
        _isLoading = false;
      });

      if (createdQuestion != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question created successfully!')),
        );
        // Clear form fields
        _questionTextController.clear();
        _questionType = null;
        _optionAController.clear();
        _optionBController.clear();
        _optionCController.clear();
        _optionDController.clear();
        _correctAnswerTextController.clear();
        _difficultyLevel = null;
        _expectedTimeSecondsController.clear();
        _selectedLesson = null; // Clear selected lesson
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create question. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Question'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoadingLessons
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _lessonsErrorMessage != null
                  ? Center(
                      child: Text(
                        _lessonsErrorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdownField<Lesson>(
                              'Select Lesson',
                              _selectedLesson,
                              _lessons,
                              (Lesson? newValue) {
                                setState(() {
                                  _selectedLesson = newValue;
                                });
                              },
                              Icons.book,
                              itemBuilder: (lesson) => Text(lesson.title),
                              validatorMessage: 'Please select a lesson',
                            ),
                            _buildTextField(_questionTextController, 'Question Text', 'Please enter question text', Icons.question_mark, maxLines: 5),

                            _buildDropdownField<String>(
                              'Question Type',
                              _questionType,
                              ['MCQ', 'SA'],
                              (String? newValue) {
                                setState(() {
                                  _questionType = newValue;
                                  // Clear option fields if type changes from MCQ
                                  if (newValue != 'MCQ') {
                                    _optionAController.clear();
                                    _optionBController.clear();
                                    _optionCController.clear();
                                    _optionDController.clear();
                                  }
                                });
                              },
                              Icons.category,
                              validatorMessage: 'Please select a question type',
                              itemBuilder: (type) => Text(type),
                            ),

                            if (_questionType == 'MCQ') ...[
                              _buildTextField(_optionAController, 'Option A', 'Option A cannot be empty', Icons.looks_one),
                              _buildTextField(_optionBController, 'Option B', 'Option B cannot be empty', Icons.looks_two),
                              _buildTextField(_optionCController, 'Option C', 'Option C cannot be empty', Icons.looks_3),
                              _buildTextField(_optionDController, 'Option D', 'Option D cannot be empty', Icons.looks_4),
                            ],

                            _buildTextField(_correctAnswerTextController, 'Correct Answer Text', 'Please enter the correct answer', Icons.check_circle),

                            _buildDropdownField<String>(
                              'Difficulty Level',
                              _difficultyLevel,
                              ['Easy', 'Medium', 'Hard'],
                              (String? newValue) {
                                setState(() {
                                  _difficultyLevel = newValue;
                                });
                              },
                              Icons.bar_chart,
                              validatorMessage: 'Please select a difficulty level',
                              itemBuilder: (level) => Text(level),
                            ),

                            _buildTextField(_expectedTimeSecondsController, 'Expected Time (seconds)', 'Please enter expected time', Icons.timer, keyboardType: TextInputType.number),

                            const SizedBox(height: 30),
                            Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : ElevatedButton.icon(
                                      onPressed: _submitQuestion,
                                      icon: const Icon(Icons.add_box),
                                      label: const Text('Add Question'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        elevation: 5,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String validationMessage, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.deepPurple.shade700),
          prefixIcon: Icon(icon, color: Colors.deepPurple.shade400),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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

  Widget _buildDropdownField<T>(String label, T? currentValue, List<T> items, ValueChanged<T?> onChanged, IconData icon, {String? validatorMessage, required Widget Function(T) itemBuilder}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<T>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.deepPurple.shade700),
          prefixIcon: Icon(icon, color: Colors.deepPurple.shade400),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        items: items.map<DropdownMenuItem<T>>((T value) {
          return DropdownMenuItem<T>(
            value: value,
            child: itemBuilder(value), // Use the provided itemBuilder
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (validatorMessage != null && (value == null || (value is String && value.isEmpty))) {
            return validatorMessage;
          }
          return null;
        },
      ),
    );
  }
}
