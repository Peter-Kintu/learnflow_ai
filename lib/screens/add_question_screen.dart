// learnflow_ai/flutter_app/lib/screens/add_question_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:uuid/uuid.dart'; // For generating UUIDs

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance;

  final TextEditingController _questionTextController = TextEditingController();
  final TextEditingController _correctAnswerController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();

  Lesson? _selectedLesson;
  List<Lesson> _lessons = [];
  String? _selectedQuestionType; // 'MCQ' or 'SA'
  String? _selectedDifficulty; // 'Easy', 'Medium', 'Hard'

  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _correctAnswerController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // First, try to load from local database
      List<Lesson> localLessons = await _databaseService.getLessons();
      if (localLessons.isNotEmpty) {
        setState(() {
          _lessons = localLessons;
          _isLoading = false;
        });
        print('AddQuestionScreen: Loaded ${localLessons.length} lessons from local DB.');
        // Fetch from API in background to ensure data is fresh
        _fetchLessonsFromApi(backgroundSync: true);
      } else {
        print('AddQuestionScreen: No local lessons found. Fetching from API...');
        // If no local lessons, fetch from API and wait for it
        await _fetchLessonsFromApi(backgroundSync: false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load lessons: $e';
        _isLoading = false;
      });
      print('AddQuestionScreen: Error loading lessons: $e');
    }
  }

  Future<void> _fetchLessonsFromApi({bool backgroundSync = false}) async {
    try {
      final apiLessons = await _apiService.fetchLessons();
      if (apiLessons.isNotEmpty) {
        setState(() {
          _lessons = apiLessons;
          if (!backgroundSync) _isLoading = false;
        });
        print('AddQuestionScreen: Fetched ${apiLessons.length} lessons from API.');

        print('AddQuestionScreen: Saving/updating lessons to local database...');
        for (var lesson in apiLessons) {
          await _databaseService.insertLesson(lesson);
        }
        print('AddQuestionScreen: Lessons saved/updated locally.');
      } else {
        if (!backgroundSync) {
          setState(() {
            _errorMessage = 'No lessons available from API.';
            _isLoading = false;
          });
        }
        print('AddQuestionScreen: No lessons found from API.');
      }
    } catch (e) {
      if (!backgroundSync) {
        setState(() {
          _errorMessage = 'Failed to fetch lessons from API: $e';
          _isLoading = false;
        });
      }
      print('AddQuestionScreen: Error fetching lessons from API: $e');
    }
  }

  Future<void> _addQuestion() async {
    if (_selectedLesson == null || _selectedQuestionType == null || _selectedDifficulty == null || _questionTextController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill all required fields.';
      });
      return;
    }

    List<String> options = [];
    if (_selectedQuestionType == 'MCQ') {
      if (_optionAController.text.isEmpty || _optionBController.text.isEmpty) {
        setState(() {
          _errorMessage = 'MCQ questions require at least Option A and Option B.';
        });
        return;
      }
      options.add(_optionAController.text);
      if (_optionBController.text.isNotEmpty) options.add(_optionBController.text);
      if (_optionCController.text.isNotEmpty) options.add(_optionCController.text);
      if (_optionDController.text.isNotEmpty) options.add(_optionDController.text);
    }

    if (_correctAnswerController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a correct answer.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final newQuestion = Question(
        uuid: const Uuid().v4(),
        lessonUuid: _selectedLesson!.uuid, // Corrected: use .uuid instead of .id
        questionText: _questionTextController.text,
        questionType: _selectedQuestionType!,
        options: _selectedQuestionType == 'MCQ' ? options : null,
        correctAnswerText: _correctAnswerController.text,
        difficultyLevel: _selectedDifficulty!,
        aiGeneratedFeedback: null, // AI feedback will be generated on attempt
      );

      final result = await _apiService.addQuestion(newQuestion);
      if (result['success']) {
        // Also save to local database
        await _databaseService.insertQuestion(newQuestion);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question added successfully!')),
        );
        _clearForm();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to add question.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding question: $e';
      });
      print('AddQuestionScreen: Error adding question: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _clearForm() {
    _questionTextController.clear();
    _correctAnswerController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    setState(() {
      _selectedLesson = null;
      _selectedQuestionType = null;
      _selectedDifficulty = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Question'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.4),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<Lesson>(
                              value: _selectedLesson,
                              decoration: _inputDecoration('Select Lesson', Icons.book_rounded),
                              hint: const Text('Select Lesson'),
                              items: _lessons.map((lesson) {
                                return DropdownMenuItem<Lesson>(
                                  value: lesson,
                                  child: Text(lesson.title),
                                );
                              }).toList(),
                              onChanged: (Lesson? newValue) {
                                setState(() {
                                  _selectedLesson = newValue;
                                });
                              },
                              dropdownColor: Colors.deepPurple.shade50,
                              style: TextStyle(color: Colors.deepPurple.shade800, fontSize: 16),
                              icon: Icon(Icons.arrow_drop_down_circle, color: Colors.deepPurple.shade500),
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(_questionTextController, 'Question Text', Icons.question_mark_rounded, maxLines: 5),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              value: _selectedQuestionType,
                              decoration: _inputDecoration('Question Type', Icons.category_rounded),
                              hint: const Text('Select Question Type'),
                              items: const [
                                DropdownMenuItem(value: 'MCQ', child: Text('Multiple Choice Question')),
                                DropdownMenuItem(value: 'SA', child: Text('Short Answer')),
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedQuestionType = newValue;
                                });
                              },
                              dropdownColor: Colors.deepPurple.shade50,
                              style: TextStyle(color: Colors.deepPurple.shade800, fontSize: 16),
                              icon: Icon(Icons.arrow_drop_down_circle, color: Colors.deepPurple.shade500),
                            ),
                            const SizedBox(height: 15),
                            if (_selectedQuestionType == 'MCQ') ...[
                              _buildTextField(_optionAController, 'Option A', Icons.looks_one_rounded),
                              const SizedBox(height: 10),
                              _buildTextField(_optionBController, 'Option B', Icons.looks_two_rounded),
                              const SizedBox(height: 10),
                              _buildTextField(_optionCController, 'Option C (Optional)', Icons.looks_3_rounded, required: false),
                              const SizedBox(height: 10),
                              _buildTextField(_optionDController, 'Option D (Optional)', Icons.looks_4_rounded, required: false),
                              const SizedBox(height: 15),
                            ],
                            _buildTextField(_correctAnswerController, 'Correct Answer', Icons.check_circle_rounded),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              value: _selectedDifficulty,
                              decoration: _inputDecoration('Difficulty Level', Icons.bar_chart_rounded),
                              hint: const Text('Select Difficulty'),
                              items: const [
                                DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                                DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedDifficulty = newValue;
                                });
                              },
                              dropdownColor: Colors.deepPurple.shade50,
                              style: TextStyle(color: Colors.deepPurple.shade800, fontSize: 16),
                              icon: Icon(Icons.arrow_drop_down_circle, color: Colors.deepPurple.shade500),
                            ),
                            const SizedBox(height: 25),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            _isSaving
                                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                                : ElevatedButton.icon(
                                    onPressed: _addQuestion,
                                    icon: const Icon(Icons.add_task_rounded, size: 28),
                                    label: const Text('Add Question'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurpleAccent.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      elevation: 8,
                                      shadowColor: Colors.deepPurple.shade900.withOpacity(0.7),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(color: Colors.deepPurple.shade800, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: Colors.grey.shade600),
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
      prefixIcon: Icon(icon, color: Colors.deepPurple.shade500),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = true, int? maxLines}) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87, fontSize: 17),
    );
  }
}
