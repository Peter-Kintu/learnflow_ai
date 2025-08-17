// learnflow_ai/flutter_app/lib/models/question.dart

import 'package:uuid/uuid.dart';

class Question {
  final String uuid;
  final String lessonUuid;
  final String questionText;
  final String questionType;
  final List<String>? options;
  final String correctAnswerText;
  final String? difficultyLevel;
  final int? expectedTimeSeconds;
  final String? aiGeneratedFeedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Question({
    required this.uuid,
    required this.lessonUuid,
    required this.questionText,
    required this.questionType,
    required this.correctAnswerText,
    this.options,
    this.difficultyLevel,
    this.expectedTimeSeconds,
    this.aiGeneratedFeedback,
    this.createdAt,
    this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      uuid: json['uuid'] as String,
      lessonUuid: json['lesson_uuid'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      options: json['options'] != null
          ? List<String>.from(json['options'].map((x) => x as String))
          : null,
      correctAnswerText: json['correct_answer_text'] as String,
      difficultyLevel: json['difficulty_level'] as String?,
      expectedTimeSeconds: json['expected_time_seconds'] as int?,
      aiGeneratedFeedback: json['ai_generated_feedback'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'uuid': uuid,
      'lesson_uuid': lessonUuid,
      'question_text': questionText,
      'question_type': questionType,
      'correct_answer_text': correctAnswerText,
      'options': options,
      'difficulty_level': difficultyLevel,
      'expected_time_seconds': expectedTimeSeconds,
      'ai_generated_feedback': aiGeneratedFeedback,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
    return data;
  }
}