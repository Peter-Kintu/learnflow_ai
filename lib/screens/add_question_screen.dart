// learnflow_ai/flutter_app/lib/screens/add_question_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/services/api_service.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _questionTextController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  final _optionsController = TextEditingController();

  String? _questionType;
  Lesson? _selectedLesson;
  String? _difficultyLevel;
  bool _isLoading = true;
  String? _errorMessage;
  List<Lesson> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fetchedLessons = await _apiService.getLessons();
      setState(() {
        _lessons = fetchedLessons;
        _isLoading = false;
      });
      if (_lessons.isEmpty) {
        setState(() {
          _errorMessage = "No lessons available. Please add a lesson first.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load lessons: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final newQuestion = Question(
        uuid: const Uuid().v4(),
        lessonUuid: _selectedLesson!.uuid,
        questionText: _questionTextController.text,
        questionType: _questionType!,
        correctAnswerText: _correctAnswerController.text,
        options: _questionType == 'MCQ'
            ? _optionsController.text.split(',').map((e) => e.trim()).toList()
            : null,
        difficultyLevel: _difficultyLevel!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _apiService.addQuestion(newQuestion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question added successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add question: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _correctAnswerController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Question'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        DropdownButtonFormField<Lesson>(
                          decoration: const InputDecoration(labelText: 'Lesson'),
                          value: _selectedLesson,
                          items: _lessons.map((lesson) {
                            return DropdownMenuItem(
                              value: lesson,
                              child: Text(lesson.title),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLesson = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a lesson.';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _questionTextController,
                          decoration: const InputDecoration(labelText: 'Question Text'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter question text.';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Question Type'),
                          value: _questionType,
                          items: ['MCQ', 'SA'].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type == 'MCQ' ? 'Multiple Choice' : 'Short Answer'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _questionType = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a question type.';
                            }
                            return null;
                          },
                        ),
                        if (_questionType == 'MCQ')
                          TextFormField(
                            controller: _optionsController,
                            decoration: const InputDecoration(
                              labelText: 'Options (comma-separated)',
                              hintText: 'e.g., Option A, Option B, Option C',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter options for MCQ.';
                              }
                              return null;
                            },
                          ),
                        TextFormField(
                          controller: _correctAnswerController,
                          decoration: const InputDecoration(labelText: 'Correct Answer'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the correct answer.';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Difficulty Level'),
                          value: _difficultyLevel,
                          items: ['Easy', 'Medium', 'Hard'].map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _difficultyLevel = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a difficulty level.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _submitForm,
                                child: const Text('Add Question'),
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }
}