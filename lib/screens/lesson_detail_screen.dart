// learnflow_ai/flutter_app/lib/screens/lesson_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:learnflow_ai/models/student.dart';
import 'package:uuid/uuid.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Question> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  Student? _currentStudent; // This will hold the student profile

  final Map<String, QuestionAttemptState> _questionStates = {};

  @override
  void initState() {
    super.initState();
    _loadStudentAndQuestions();
  }

  @override
  void dispose() {
    _questionStates.values.forEach((state) => state.textController.dispose());
    super.dispose();
  }

  Future<void> _loadStudentAndQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // First, try to load from local database (might have a generated ID from previous session)
      final int? currentUserId = await _apiService.getCurrentUserId(); // Assuming you have a way to get current user ID
      if (currentUserId != null) {
        _currentStudent = await _databaseService.getStudentByUserId(currentUserId);
        if (_currentStudent != null) {
          print('LessonDetailScreen: Student profile loaded from local DB: ${_currentStudent?.user?.username}, ID Code: ${_currentStudent?.studentIdCode}');
        }
      }

      // If not found locally or studentIdCode is null, fetch from API
      if (_currentStudent == null || _currentStudent!.studentIdCode == null) {
        final fetchedStudent = await _apiService.fetchCurrentStudentProfile();
        if (fetchedStudent == null) {
          _errorMessage = 'Could not fetch student profile. Cannot record quiz attempts.';
          _isLoading = false;
          setState(() {});
          return;
        }
        _currentStudent = fetchedStudent;
        print('LessonDetailScreen: Student profile loaded from API: ${_currentStudent?.user?.username}, ID Code: ${_currentStudent?.studentIdCode}');

        // WORKAROUND: If student_id_code is still null from Django, generate one
        if (_currentStudent!.studentIdCode == null || _currentStudent!.studentIdCode!.isEmpty) {
          final generatedId = 'LOCAL_STUDENT_${_currentStudent!.userId}_${const Uuid().v4().substring(0, 8)}';
          _currentStudent = _currentStudent!.copyWith(studentIdCode: generatedId);
          print('LessonDetailScreen: Generated local student_id_code: $generatedId as Django provided null.');

          // Attempt to save this generated ID back to local DB for persistence
          await _databaseService.updateStudent(_currentStudent!);
          print('LessonDetailScreen: Updated local student profile with generated ID code.');
        }
      } else {
         // If we already had a local student with a studentIdCode, ensure it's up-to-date from API
         // (This ensures we don't use stale local data if Django was updated)
         final fetchedStudent = await _apiService.fetchCurrentStudentProfile();
         if (fetchedStudent != null && fetchedStudent.studentIdCode != null && fetchedStudent.studentIdCode!.isNotEmpty) {
           if (_currentStudent!.studentIdCode != fetchedStudent.studentIdCode) {
             _currentStudent = _currentStudent!.copyWith(studentIdCode: fetchedStudent.studentIdCode);
             await _databaseService.updateStudent(_currentStudent!);
             print('LessonDetailScreen: Updated local student_id_code from API: ${fetchedStudent.studentIdCode}');
           }
         }
      }

      // Now proceed with loading questions
      List<Question> localQuestions = await _databaseService.getQuestionsForLesson(widget.lesson.uuid);

      if (localQuestions.isNotEmpty) {
        setState(() {
          _questions = localQuestions;
          _isLoading = false;
          for (var q in _questions) {
            _questionStates[q.uuid] = QuestionAttemptState();
          }
        });
        print('LessonDetailScreen: Loaded ${localQuestions.length} questions from local database.');
        _fetchQuestionsFromApi(backgroundSync: true); // Background sync for latest questions
      } else {
        print('LessonDetailScreen: No local questions found. Fetching from API...');
        await _fetchQuestionsFromApi(backgroundSync: false); // Blocking fetch if no local data
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load student or questions: $e';
        _isLoading = false;
      });
      print('LessonDetailScreen: Error loading student or questions: $e');
    }
  }

  Future<void> _fetchQuestionsFromApi({bool backgroundSync = false}) async {
    try {
      final fetchedQuestions = await _apiService.fetchQuestionsForLesson(widget.lesson.uuid);
      if (fetchedQuestions.isNotEmpty) {
        setState(() {
          _questions = fetchedQuestions;
          if (!backgroundSync) _isLoading = false;
          for (var q in _questions) {
            if (!_questionStates.containsKey(q.uuid)) {
              _questionStates[q.uuid] = QuestionAttemptState();
            }
          }
        });
        print('LessonDetailScreen: Fetched ${fetchedQuestions.length} questions from API.');

        print('LessonDetailScreen: Saving/updating questions to local database...');
        for (var question in fetchedQuestions) {
          await _databaseService.insertQuestion(question);
        }
        print('LessonDetailScreen: Questions saved/updated locally.');
      } else {
        if (!backgroundSync) {
          setState(() {
            _errorMessage = 'No practice questions for this lesson yet from API.';
            _isLoading = false;
          });
        }
        print('LessonDetailScreen: No questions found from API for lesson ${widget.lesson.title}.');
      }
    } catch (e) {
      if (!backgroundSync) {
        setState(() {
          _errorMessage = 'Failed to fetch questions from API: $e';
          _isLoading = false;
        });
      }
      print('LessonDetailScreen: Error fetching questions from API: $e');
    }
  }


  void _submitAnswer(Question question, String? submittedAnswer) async {
    if (_currentStudent == null || _currentStudent!.studentIdCode == null || _currentStudent!.studentIdCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Student profile or ID code not loaded. Cannot record attempt.')),
      );
      print('Error: _currentStudent is null or studentIdCode is empty/null during _submitAnswer.');
      return;
    }

    // DEBUG PRINT: What studentIdCode is being used right now?
    print('LessonDetailScreen: Using studentIdCode for QuizAttempt: ${_currentStudent!.studentIdCode}');


    setState(() {
      final state = _questionStates[question.uuid]!;
      state.submittedAnswer = submittedAnswer;
      state.showFeedback = true;

      if (question.questionType == 'MCQ') {
        state.isAnswerCorrect = (submittedAnswer == question.correctAnswerText);
        state.feedbackMessage = state.isAnswerCorrect ? 'Great job! That\'s correct.' : 'Not quite. Review the options carefully.';
        state.feedbackScore = state.isAnswerCorrect ? 3 : 0;
      } else if (question.questionType == 'SA') {
        final studentAnswerLower = submittedAnswer?.trim().toLowerCase() ?? '';
        final correctAnswerLower = question.correctAnswerText?.trim().toLowerCase() ?? '';

        if (studentAnswerLower == correctAnswerLower) {
          state.isAnswerCorrect = true;
          state.feedbackMessage = 'Excellent! Your answer is spot on.';
          state.feedbackScore = 3;
        } else if (correctAnswerLower.split(' ').any((keyword) => studentAnswerLower.contains(keyword))) {
          state.isAnswerCorrect = false;
          state.feedbackMessage = 'Good attempt! Your answer has some relevant points, but it\'s not fully complete. Consider adding more detail.';
          state.feedbackScore = 1;
        } else {
          state.isAnswerCorrect = false;
          state.feedbackMessage = 'Keep trying! Your answer needs more work. Review the lesson content for key concepts.';
          state.feedbackScore = 0;
        }
      }
      print('Submitted answer for ${question.uuid}: $submittedAnswer. Correct: ${state.isAnswerCorrect}. Feedback: ${state.feedbackMessage}');
    });

    // Save quiz attempt to local database
    final quizAttempt = QuizAttempt(
      uuid: const Uuid().v4(),
      studentUserId: _currentStudent!.userId,
      studentIdCode: _currentStudent!.studentIdCode, // This will now be non-null due to fallback
      questionUuid: question.uuid,
      submittedAnswer: submittedAnswer ?? '',
      isCorrect: _questionStates[question.uuid]!.isAnswerCorrect,
      score: _questionStates[question.uuid]!.feedbackScore?.toDouble() ?? 0.0,
      aiFeedbackText: _questionStates[question.uuid]!.feedbackMessage,
      rawAiResponse: null,
      attemptTimestamp: DateTime.now(),
      syncStatus: 'PENDING',
      deviceId: 'flutter-app-device',
    );

    try {
      await _databaseService.insertQuizAttempt(quizAttempt);
      print('Quiz attempt saved locally for question ${question.uuid}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer submitted and saved locally!')),
      );
    } catch (e) {
      print('Error saving quiz attempt locally: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save answer locally: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.4),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lesson Overview',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.lesson.description ?? 'No detailed description available for this lesson.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoChip(Icons.subject, widget.lesson.subject ?? 'N/A', Colors.blueGrey),
                                    _buildInfoChip(Icons.bar_chart, widget.lesson.difficultyLevel ?? 'N/A', Colors.orange),
                                    _buildInfoChip(Icons.numbers, 'v${widget.lesson.version}', Colors.green),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Text(
                          'Practice Questions',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 5.0, color: Colors.black38, offset: Offset(1.0, 1.0)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),

                        _questions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.help_outline, size: 60, color: Colors.white70),
                                      SizedBox(height: 10),
                                      Text(
                                        'No practice questions for this lesson yet.',
                                        style: TextStyle(fontSize: 18, color: Colors.white70),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _questions.length,
                                itemBuilder: (context, index) {
                                  final question = _questions[index];
                                  final questionState = _questionStates[question.uuid]!;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 6,
                                    shadowColor: Colors.black.withOpacity(0.3),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Question ${index + 1}:',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            question.questionText,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          if (question.questionType == 'MCQ' && question.options != null)
                                            Column(
                                              children: question.options!.map((option) {
                                                return RadioListTile<String>(
                                                  title: Text(
                                                    option,
                                                    style: TextStyle(
                                                      color: questionState.showFeedback
                                                          ? (option == question.correctAnswerText
                                                              ? Colors.green.shade700
                                                              : (option == questionState.selectedOption
                                                                  ? Colors.red.shade700
                                                                  : Colors.black87))
                                                          : Colors.black87,
                                                      fontWeight: questionState.showFeedback && option == question.correctAnswerText
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                  value: option,
                                                  groupValue: questionState.selectedOption,
                                                  onChanged: questionState.showFeedback
                                                      ? null
                                                      : (String? value) {
                                                          setState(() {
                                                            questionState.selectedOption = value;
                                                          });
                                                        },
                                                  activeColor: Colors.deepPurple,
                                                );
                                              }).toList(),
                                            )
                                          else if (question.questionType == 'SA')
                                            TextField(
                                              controller: questionState.textController,
                                              decoration: InputDecoration(
                                                labelText: 'Your Answer',
                                                hintText: 'Type your answer here',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: Colors.deepPurple),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: Colors.deepPurple.shade200),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                                                ),
                                                filled: true,
                                                fillColor: Colors.deepPurple.shade50,
                                              ),
                                              maxLines: 3,
                                              enabled: !questionState.showFeedback,
                                              onChanged: (text) {
                                                questionState.submittedAnswer = text;
                                              },
                                            ),

                                          const SizedBox(height: 15),

                                          if (!questionState.showFeedback)
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  String? answerToSubmit;
                                                  if (question.questionType == 'MCQ') {
                                                    answerToSubmit = questionState.selectedOption;
                                                  } else if (question.questionType == 'SA') {
                                                    answerToSubmit = questionState.textController.text;
                                                  }

                                                  if (answerToSubmit != null && answerToSubmit.isNotEmpty) {
                                                    _submitAnswer(question, answerToSubmit);
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Please select an option or type your answer.')),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.purple,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                                child: const Text('Submit Answer'),
                                              ),
                                            ),

                                          if (questionState.showFeedback)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Divider(height: 20, thickness: 1, color: Colors.grey),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      questionState.isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                                                      color: questionState.isAnswerCorrect ? Colors.green : Colors.red,
                                                      size: 28,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      questionState.isAnswerCorrect ? 'Correct!' : 'Incorrect!',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: questionState.isAnswerCorrect ? Colors.green : Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'The correct answer was: "${question.correctAnswerText}"',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.green.shade900,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                if (questionState.feedbackMessage != null)
                                                  Text(
                                                    'Feedback: ${questionState.feedbackMessage!}',
                                                    style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade800),
                                                  ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Score: ',
                                                      style: TextStyle(fontSize: 15, color: Colors.blueGrey),
                                                    ),
                                                    ...List.generate(3, (i) => Icon(
                                                      Icons.star,
                                                      color: i < (questionState.feedbackScore ?? 0) ? Colors.amber : Colors.grey.shade300,
                                                      size: 20,
                                                    )),
                                                  ],
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
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

class QuestionAttemptState {
  String? selectedOption;
  TextEditingController textController = TextEditingController();
  String? submittedAnswer;
  bool showFeedback;
  bool isAnswerCorrect;
  String? feedbackMessage;
  int? feedbackScore;

  QuestionAttemptState({
    this.selectedOption,
    this.showFeedback = false,
    this.isAnswerCorrect = false,
    this.feedbackMessage,
    this.feedbackScore,
  });
}
