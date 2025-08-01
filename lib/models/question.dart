// learnflow_ai/flutter_app/lib/models/question.dart

import 'dart:convert'; // For JSON encoding/decoding

class Question {
  final String uuid;
  final String lessonUuid;
  final String questionText;
  final String questionType;
  final List<String>? options;
  final String correctAnswerText;
  final String difficultyLevel;
  final int? expectedTimeSeconds;
  final String? aiGeneratedFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.uuid,
    required this.lessonUuid,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.correctAnswerText,
    required this.difficultyLevel,
    this.expectedTimeSeconds,
    this.aiGeneratedFeedback,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert a Question object into a Map object (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'lesson_uuid': lessonUuid,
      'question_text': questionText,
      'question_type': questionType,
      'options': options != null ? jsonEncode(options) : null,
      'correct_answer_text': correctAnswerText,
      'difficulty_level': difficultyLevel,
      'expected_time_seconds': expectedTimeSeconds,
      'ai_generated_feedback': aiGeneratedFeedback,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert a Map object into a Lesson object (from SQLite)
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      uuid: map['uuid'] as String,
      lessonUuid: map['lesson_uuid'] as String,
      questionText: map['question_text'] as String,
      questionType: map['question_type'] as String,
      options: map['options'] == null
          ? null
          : (map['options'] is String
              ? List<String>.from(jsonDecode(map['options'] as String))
              : List<String>.from(map['options'] as List)),
      correctAnswerText: map['correct_answer_text']?.toString() ?? '',
      difficultyLevel: map['difficulty_level'] as String,
      expectedTimeSeconds: map['expected_time_seconds'] as int?,
      aiGeneratedFeedback: map['ai_generated_feedback'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert a Question object into a JSON object (for API)
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'lesson_uuid': lessonUuid,
      'question_text': questionText,
      'question_type': questionType,
      'options': options,
      'correct_answer_text': correctAnswerText,
      'difficulty_level': difficultyLevel,
      'expected_time_seconds': expectedTimeSeconds,
      'ai_generated_feedback': aiGeneratedFeedback,
    };
  }

  // Factory constructor to create a Question from JSON (from API)
  factory Question.fromJson(Map<String, dynamic> json, {String? lessonUuidFromContext}) {
    return Question(
      uuid: json['uuid'] as String,
      lessonUuid: json['lesson_uuid'] as String? ?? lessonUuidFromContext ?? '',
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      options: json['options'] == null
          ? null
          : (json['options'] is String
              ? List<String>.from(jsonDecode(json['options'] as String))
              : List<String>.from(json['options'] as List)),
      correctAnswerText: json['correct_answer_text']?.toString() ?? '',
      difficultyLevel: json['difficulty_level'] as String,
      expectedTimeSeconds: json['expected_time_seconds'] as int?,
      aiGeneratedFeedback: json['ai_generated_feedback'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Override the equality operator (==)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question &&
           uuid == other.uuid;
  }

  // Override hashCode
  @override
  int get hashCode => uuid.hashCode;
}
