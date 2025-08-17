// learnflow_ai/flutter_app/lib/models/quiz_attempt.dart

import 'package:uuid/uuid.dart';

class QuizAttempt {
  final String uuid;
  final int studentUserId;
  final String studentUuid;
  final String? studentIdCode;
  final String questionUuid;
  final String submittedAnswer;
  final bool isCorrect;
  final double score;
  final String? aiFeedbackText;
  final String? rawAiResponse;
  final DateTime attemptTimestamp;
  final String? lessonTitle;
  final String? questionTextPreview;

  QuizAttempt({
    required this.uuid,
    required this.studentUserId,
    required this.studentUuid,
    this.studentIdCode,
    required this.questionUuid,
    required this.submittedAnswer,
    required this.isCorrect,
    required this.score,
    this.aiFeedbackText,
    this.rawAiResponse,
    required this.attemptTimestamp,
    this.lessonTitle,
    this.questionTextPreview,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      uuid: json['uuid'] as String,
      studentUserId: json['student_user_id'] as int,
      studentUuid: json['student_uuid'] as String,
      studentIdCode: json['student_id_code'] as String?,
      questionUuid: json['question_uuid'] as String,
      submittedAnswer: json['submitted_answer'] as String,
      isCorrect: json['is_correct'] as bool,
      score: (json['score'] as num).toDouble(),
      aiFeedbackText: json['ai_feedback_text'] as String?,
      rawAiResponse: json['raw_ai_response'] as String?,
      attemptTimestamp: DateTime.parse(json['attempt_timestamp'] as String),
      lessonTitle: json['lesson_title'] as String?,
      questionTextPreview: json['question_text_preview'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'student_user_id': studentUserId,
      'student_uuid': studentUuid,
      'student_id_code': studentIdCode,
      'question_uuid': questionUuid,
      'submitted_answer': submittedAnswer,
      'is_correct': isCorrect,
      'score': score,
      'ai_feedback_text': aiFeedbackText,
      'raw_ai_response': rawAiResponse,
      'attempt_timestamp': attemptTimestamp.toIso8601String(),
    };
  }

  QuizAttempt copyWith({
    String? uuid,
    int? studentUserId,
    String? studentUuid,
    String? studentIdCode,
    String? questionUuid,
    String? submittedAnswer,
    bool? isCorrect,
    double? score,
    String? aiFeedbackText,
    String? rawAiResponse,
    DateTime? attemptTimestamp,
    String? lessonTitle,
    String? questionTextPreview,
  }) {
    return QuizAttempt(
      uuid: uuid ?? this.uuid,
      studentUserId: studentUserId ?? this.studentUserId,
      studentUuid: studentUuid ?? this.studentUuid,
      studentIdCode: studentIdCode ?? this.studentIdCode,
      questionUuid: questionUuid ?? this.questionUuid,
      submittedAnswer: submittedAnswer ?? this.submittedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      score: score ?? this.score,
      aiFeedbackText: aiFeedbackText ?? this.aiFeedbackText,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      attemptTimestamp: attemptTimestamp ?? this.attemptTimestamp,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      questionTextPreview: questionTextPreview ?? this.questionTextPreview,
    );
  }

  @override
  String toString() {
    return 'QuizAttempt(uuid: $uuid, studentUserId: $studentUserId, studentUuid: $studentUuid, questionUuid: $questionUuid, isCorrect: $isCorrect, score: $score, attemptTimestamp: $attemptTimestamp)';
  }
}