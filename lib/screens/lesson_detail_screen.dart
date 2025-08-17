// learnflow_ai/flutter_app/lib/screens/lesson_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/lesson.dart';
import 'package:learnflow_ai/models/question.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/services/api_service.dart';
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
    _questionStates.values.forEach((state) => state.textController.dispose());
    super.dispose();
  }

  Future<void> _loadStudentAndQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final student = await _apiService.fetchCurrentStudentProfile();
      if (student == null) {
        setState(() {
          _errorMessage = "Student profile not found. Please log in again.";
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _currentStudent = student;
      });
      final questions = await _apiService.getQuestionsForLesson(widget.lesson.uuid);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      if (questions.isEmpty) {
        setState(() {
          _errorMessage = "No questions found for this lesson.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load questions: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer(Question question) async {
    final state = _questionStates[question.uuid];
    if (state == null || state.submittedAnswer == null) {
      return;
    }

    setState(() {
      state.showFeedback = true;
    });

    final isCorrect = state.submittedAnswer == question.correctAnswerText;

    try {
      final quizAttempt = QuizAttempt(
        uuid: const Uuid().v4(),
        studentUserId: _currentStudent!.userId,
        studentUuid: _currentStudent!.uuid,
        questionUuid: question.uuid,
        submittedAnswer: state.submittedAnswer!,
        isCorrect: isCorrect,
        score: isCorrect ? 100.0 : 0.0,
        attemptTimestamp: DateTime.now(),
      );

      final result = await _apiService.saveQuizAttempt(quizAttempt);
      if (result['success']) {
        setState(() {
          state.feedbackMessage = result['ai_feedback_text'] ?? 'Answer submitted successfully.';
          state.feedbackScore = (result['score'] as num?)?.toInt() ?? (isCorrect ? 100 : 0);
          state.isAnswerCorrect = isCorrect;
        });
      } else {
        setState(() {
          state.feedbackMessage = 'Failed to submit answer: ${result['message']}';
          state.feedbackScore = 0;
          state.isAnswerCorrect = false;
        });
      }
    } catch (e) {
      setState(() {
        state.feedbackMessage = 'Error submitting answer: $e';
        state.feedbackScore = 0;
        state.isAnswerCorrect = false;
      });
    }
  }

  void _nextQuestion() {
    final currentQuestion = _questions.firstWhere(
      (q) => _questionStates.containsKey(q.uuid) && _questionStates[q.uuid]!.showFeedback,
      orElse: () => _questions.first,
    );
    final currentIndex = _questions.indexOf(currentQuestion);

    if (currentIndex < _questions.length - 1) {
      setState(() {});
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lesson Completed'),
        content: const Text('You have completed all the questions in this lesson.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go back to Lessons'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final state = _questionStates.putIfAbsent(
      question.uuid,
      () => QuestionAttemptState(),
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question: ${question.questionText}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (question.questionType == 'MCQ')
              ..._buildMCQOptions(question, state),
            if (question.questionType == 'SA')
              _buildShortAnswerInput(question, state),
            const SizedBox(height: 20),
            if (!state.showFeedback)
              Center(
                child: ElevatedButton(
                  onPressed: () => _submitAnswer(question),
                  child: const Text('Submit Answer'),
                ),
              ),
            if (state.showFeedback)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20, thickness: 1),
                  Text(
                    state.isAnswerCorrect ? 'Correct!' : 'Incorrect.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: state.isAnswerCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'AI Feedback:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    state.feedbackMessage ?? 'No feedback provided.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Score: ${state.feedbackScore}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      child: const Text('Next Question'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMCQOptions(Question question, QuestionAttemptState state) {
    if (question.options == null) return [const Text('No options available.')];
    return question.options!.map((option) {
      return RadioListTile<String>(
        title: Text(option),
        value: option,
        groupValue: state.selectedOption,
        onChanged: (value) {
          if (!state.showFeedback) {
            setState(() {
              state.selectedOption = value;
              state.submittedAnswer = value;
            });
          }
        },
      );
    }).toList();
  }

  Widget _buildShortAnswerInput(Question question, QuestionAttemptState state) {
    return TextField(
      controller: state.textController,
      onChanged: (value) {
        state.submittedAnswer = value;
      },
      decoration: const InputDecoration(
        labelText: 'Your Answer',
        border: OutlineInputBorder(),
      ),
      readOnly: state.showFeedback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 18), textAlign: TextAlign.center),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    return _buildQuestionCard(question);
                  },
                ),
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