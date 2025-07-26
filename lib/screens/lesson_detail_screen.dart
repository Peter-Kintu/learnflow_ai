// learnflow_ai/flutter_app/lib/screens/lesson_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/services/api_service.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:learnflow_ai/models/student.dart';
import 'package:uuid/uuid.dart'; // For generating UUIDs

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
  Student? _currentStudent;

  final Map<String, QuestionAttemptState> _questionStates = {};

  @override
  void initState() {
    super.initState();
    _loadStudentAndQuestions();
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers when the widget is removed from the tree
    _questionStates.values.forEach((state) => state.textController.dispose());
    super.dispose();
  }

  Future<void> _loadStudentAndQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final int? currentUserId = await _apiService.getCurrentUserId();
      if (currentUserId == null) {
        setState(() {
          _errorMessage = 'User not logged in. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      // Fetch student profile locally first
      _currentStudent = await _databaseService.getStudent(currentUserId);
      if (_currentStudent != null) {
        print('LessonDetailScreen: Student profile loaded from local DB: ${_currentStudent?.user?.username}, ID Code: ${_currentStudent?.studentIdCode}');
      }

      if (_currentStudent == null || _currentStudent!.studentIdCode == null) {
        // If not found locally or studentIdCode is missing, try API
        final fetchedStudent = await _apiService.fetchCurrentStudentProfile();
        if (fetchedStudent == null) {
          _errorMessage = 'Could not fetch student profile. Cannot record quiz attempts.';
          _isLoading = false;
          setState(() {});
          return;
        }
        _currentStudent = fetchedStudent;
        print('LessonDetailScreen: Student profile loaded from API: ${_currentStudent?.user?.username}, ID Code: ${_currentStudent?.studentIdCode}');

        // If studentIdCode is still null/empty after API fetch, generate a local one
        if (_currentStudent!.studentIdCode == null || _currentStudent!.studentIdCode!.isEmpty) {
          final generatedId = 'LOCAL_STUDENT_${_currentStudent!.userId}_${const Uuid().v4().substring(0, 8)}';
          _currentStudent = _currentStudent!.copyWith(studentIdCode: generatedId);
          print('LessonDetailScreen: Generated local student_id_code: $generatedId as Django provided null.');

          await _databaseService.updateStudent(_currentStudent!); // Update local DB with generated ID
          print('LessonDetailScreen: Updated local student profile with generated ID code.');
        }
      } else {
         // If a student profile exists locally, check if the API has a more recent studentIdCode
         final fetchedStudent = await _apiService.fetchCurrentStudentProfile();
         if (fetchedStudent != null && fetchedStudent.studentIdCode != null && fetchedStudent.studentIdCode!.isNotEmpty) {
           if (_currentStudent!.studentIdCode != fetchedStudent.studentIdCode) {
             _currentStudent = _currentStudent!.copyWith(studentIdCode: fetchedStudent.studentIdCode);
             await _databaseService.updateStudent(_currentStudent!);
             print('LessonDetailScreen: Updated local student_id_code from API: ${fetchedStudent.studentIdCode}');
           }
         }
      }

      // Load questions from local database first
      print('LessonDetailScreen: Attempting to load questions from local database...');
      List<Question> localQuestions = await _databaseService.getQuestionsForLesson(widget.lesson.uuid);

      if (localQuestions.isNotEmpty) {
        setState(() {
          _questions = localQuestions;
          _isLoading = false;
          // Initialize question states for all questions
          for (var q in _questions) {
            _questionStates[q.uuid] = QuestionAttemptState();
          }
        });
        print('LessonDetailScreen: Loaded ${localQuestions.length} questions from local database.');
        // Fetch from API in background to ensure data is fresh
        _fetchQuestionsFromApi(backgroundSync: true);
      } else {
        print('LessonDetailScreen: No local questions found. Fetching from API...');
        // If no local questions, fetch from API and wait for it
        await _fetchQuestionsFromApi(backgroundSync: false);
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
          if (!backgroundSync) _isLoading = false; // Only set loading to false if not background sync
          // Initialize question states for newly fetched questions
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

    print('LessonDetailScreen: Using studentIdCode for QuizAttempt: ${_currentStudent!.studentIdCode}');


    setState(() {
      final state = _questionStates[question.uuid]!;
      state.submittedAnswer = submittedAnswer;
      state.showFeedback = true;

      // Determine correctness and initial feedback/score based on question type
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

    final quizAttempt = QuizAttempt(
      uuid: const Uuid().v4(),
      studentUserId: _currentStudent!.userId,
      studentIdCode: _currentStudent!.studentIdCode, // Pass the studentIdCode
      questionUuid: question.uuid,
      submittedAnswer: submittedAnswer ?? '',
      isCorrect: _questionStates[question.uuid]!.isAnswerCorrect,
      score: _questionStates[question.uuid]!.feedbackScore?.toDouble() ?? 0.0,
      aiFeedbackText: _questionStates[question.uuid]!.feedbackMessage,
      rawAiResponse: null, // Placeholder for actual raw AI response
      attemptTimestamp: DateTime.now(),
      syncStatus: 'PENDING', // Mark as pending sync
      deviceId: 'flutter-app-device', // Placeholder device ID
      // Add lessonTitle and questionTextPreview for easier display in SyncStatusScreen
      lessonTitle: widget.lesson.title, // Pass lesson title
      questionTextPreview: question.questionText.length > 50 ? '${question.questionText.substring(0, 50)}...' : question.questionText, // Pass question text preview
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

  // Re-added this method
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Lesson Completed!'),
          content: const Text('You have completed all questions for this lesson.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Go to Lessons'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to LessonsScreen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0), // Increased padding
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 19, fontWeight: FontWeight.bold), // Bolder, larger error
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0), // Increased padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 25), // Increased margin
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Even more rounded
                          elevation: 16, // More pronounced shadow
                          shadowColor: Colors.black.withOpacity(0.5),
                          color: Colors.white, // Solid white for content cards
                          child: Padding(
                            padding: const EdgeInsets.all(30.0), // Increased padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lesson Overview',
                                  style: TextStyle(
                                    fontSize: 26, // Larger font
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 15), // Increased spacing
                                Text(
                                  widget.lesson.description ?? 'No detailed description available for this lesson.',
                                  style: TextStyle(
                                    fontSize: 17, // Larger font
                                    color: Colors.grey.shade900, // Even darker grey for better contrast
                                  ),
                                ),
                                const SizedBox(height: 25), // Increased spacing
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoChip(Icons.subject_rounded, widget.lesson.subject ?? 'N/A', Colors.blueGrey.shade700), // Rounded, darker color
                                    _buildInfoChip(Icons.bar_chart_rounded, widget.lesson.difficultyLevel ?? 'N/A', Colors.orange.shade700), // Rounded, darker color
                                    _buildInfoChip(Icons.numbers_rounded, 'v${widget.lesson.version}', Colors.green.shade700), // Rounded, darker color
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Text(
                          'Practice Questions',
                          style: TextStyle(
                            fontSize: 30, // Even larger font
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 10.0, color: Colors.black87, offset: Offset(2.0, 2.0)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25), // Increased spacing

                        _questions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(25.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.help_outline_rounded, size: 90, color: Colors.white70), // Larger, rounded icon
                                      SizedBox(height: 25),
                                      Text(
                                        'No practice questions for this lesson yet.',
                                        style: TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w500), // Larger, medium weight
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(), // Important to allow parent SingleChildScrollView
                                itemCount: _questions.length,
                                itemBuilder: (context, index) {
                                  final question = _questions[index];
                                  final questionState = _questionStates[question.uuid]!;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 15), // Increased vertical margin
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Even more rounded
                                    elevation: 10, // More shadow
                                    shadowColor: Colors.black.withOpacity(0.4),
                                    color: Colors.white, // Solid white
                                    child: Padding(
                                      padding: const EdgeInsets.all(30.0), // Increased padding
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Question ${index + 1}:',
                                            style: TextStyle(
                                              fontSize: 22, // Larger font
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple.shade800, // Darker purple
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            question.questionText,
                                            style: TextStyle(
                                              fontSize: 19, // Larger font
                                              color: Colors.grey.shade900, // Darker grey
                                            ),
                                          ),
                                          const SizedBox(height: 18),

                                          if (question.questionType == 'MCQ' && question.options != null)
                                            Column(
                                              children: question.options!.map((option) {
                                                return RadioListTile<String>(
                                                  title: Text(
                                                    option,
                                                    style: TextStyle(
                                                      color: questionState.showFeedback
                                                          ? (option == question.correctAnswerText
                                                              ? Colors.green.shade800 // Even darker green
                                                              : (option == questionState.selectedOption
                                                                  ? Colors.red.shade800 // Even darker red
                                                                  : Colors.black87))
                                                          : Colors.black87,
                                                      fontWeight: questionState.showFeedback && option == question.correctAnswerText
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      fontSize: 17, // Consistent font size
                                                    ),
                                                  ),
                                                  value: option,
                                                  groupValue: questionState.selectedOption,
                                                  onChanged: questionState.showFeedback
                                                      ? null // Disable if feedback is shown
                                                      : (String? value) {
                                                          setState(() {
                                                            questionState.selectedOption = value;
                                                          });
                                                        },
                                                  activeColor: Colors.deepPurple.shade800, // Even deeper purple for active radio
                                                  controlAffinity: ListTileControlAffinity.leading,
                                                );
                                              }).toList(),
                                            )
                                          else if (question.questionType == 'SA')
                                            TextField(
                                              controller: questionState.textController,
                                              decoration: InputDecoration(
                                                labelText: 'Your Answer',
                                                hintText: 'Type your answer here',
                                                labelStyle: TextStyle(color: Colors.deepPurple.shade800, fontWeight: FontWeight.w600),
                                                hintStyle: TextStyle(color: Colors.grey.shade600),
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
                                                filled: true,
                                                fillColor: Colors.deepPurple.shade50.withOpacity(0.8),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                                              ),
                                              maxLines: 5, // More lines for short answer
                                              enabled: !questionState.showFeedback, // Disable if feedback is shown
                                              onChanged: (text) {
                                                questionState.submittedAnswer = text;
                                              },
                                              style: const TextStyle(color: Colors.black87, fontSize: 17),
                                            ),

                                          const SizedBox(height: 25),

                                          if (!questionState.showFeedback) // Only show submit button if feedback is not shown
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
                                                  backgroundColor: Colors.deepPurpleAccent.shade700,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20), // Larger button
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                  elevation: 10,
                                                  shadowColor: Colors.deepPurple.shade900.withOpacity(0.7),
                                                ),
                                                child: const Text('Submit Answer'),
                                              ),
                                            ),

                                          if (questionState.showFeedback) // Only show feedback section if feedback is shown
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Divider(height: 35, thickness: 2, color: Colors.deepPurple), // Thicker divider
                                                Row(
                                                  children: [
                                                    Icon(
                                                      questionState.isAnswerCorrect ? Icons.check_circle_outline_rounded : Icons.cancel_outlined, // Rounded icons, outline for cancel
                                                      color: questionState.isAnswerCorrect ? Colors.green.shade800 : Colors.red.shade800, // Deeper colors
                                                      size: 36, // Larger icon
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      questionState.isAnswerCorrect ? 'Correct!' : 'Incorrect!',
                                                      style: TextStyle(
                                                        fontSize: 24, // Larger font
                                                        fontWeight: FontWeight.bold,
                                                        color: questionState.isAnswerCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 15),
                                                Text(
                                                  'The correct answer was: "${question.correctAnswerText}"',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.green.shade900,
                                                    fontStyle: FontStyle.italic,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 18),
                                                if (questionState.feedbackMessage != null)
                                                  Text(
                                                    'Feedback: ${questionState.feedbackMessage!}',
                                                    style: TextStyle(fontSize: 17, color: Colors.blueGrey.shade900), // Darker blue-grey
                                                  ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Score: ',
                                                      style: TextStyle(fontSize: 17, color: Colors.blueGrey),
                                                    ),
                                                    ...List.generate(3, (i) => Icon(
                                                      Icons.star_rounded,
                                                      color: i < (questionState.feedbackScore ?? 0) ? Colors.amber.shade700 : Colors.grey.shade400, // Richer amber, darker grey
                                                      size: 25, // Larger stars
                                                    )),
                                                  ],
                                                ),
                                            const SizedBox(height: 25), // Space before next button
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // Reset state for the current question before moving
                                                  questionState.showFeedback = false;
                                                  questionState.selectedOption = null;
                                                  questionState.textController.clear();
                                                  questionState.submittedAnswer = null;
                                                  questionState.isAnswerCorrect = false;
                                                  questionState.feedbackMessage = null;
                                                  questionState.feedbackScore = null;

                                                  // Move to the next question or show completion
                                                  _nextQuestionOrComplete();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.deepPurple.shade700,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                  elevation: 8,
                                                ),
                                                child: Text(index < _questions.length - 1 ? 'Next Question' : 'Finish Lesson'),
                                              ),
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

  // Helper method to navigate to next question or show completion dialog
  void _nextQuestionOrComplete() {
    // Find the index of the current question being displayed in the ListView.builder
    // This assumes the ListView.builder is iterating through _questions in order.
    final currentQuestion = _questions.firstWhere(
      (q) => _questionStates.containsKey(q.uuid) && _questionStates[q.uuid]!.showFeedback,
      orElse: () => _questions.first, // Fallback, though ideally should find it
    );
    final currentIndex = _questions.indexOf(currentQuestion);

    if (currentIndex < _questions.length - 1) {
      // If there are more questions, scroll to the next one.
      // This is a simplified approach; a PageView or explicit scroll controller
      // would be more robust for navigating questions.
      // For now, we'll just re-render and the user can scroll.
      setState(() {
        // No explicit index change needed for ListView.builder, just update state
        // of the current question to hide feedback and allow next interaction.
      });
    } else {
      _showCompletionDialog();
    }
  }


  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Chip(
      avatar: Icon(icon, size: 22, color: color), // Larger icon
      label: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15), // Slightly larger text
      ),
      backgroundColor: color.withOpacity(0.2), // More opaque background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // More rounded
      side: BorderSide(color: color.withOpacity(0.7), width: 2), // Thicker, clearer border
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // More padding
    );
  }
}

// Helper class to manage the state of each question attempt
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
