// learnflow_ai/flutter_app/lib/models/question.dart

import 'dart:convert'; // For JSON encoding/decoding

class Question {
  final String uuid;
  final String lessonUuid; // This is the field that expects the UUID string
  final String questionText;
  final String questionType; // 'MCQ' or 'SA'
  final List<String>? options; // For MCQ, stored as JSON string in DB
  final String correctAnswerText;
  final String difficultyLevel;
  final int? expectedTimeSeconds; // Added this field
  final String? aiGeneratedFeedback; // Added this field

  Question({
    required this.uuid,
    required this.lessonUuid,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.correctAnswerText,
    required this.difficultyLevel,
    this.expectedTimeSeconds, // Include in constructor
    this.aiGeneratedFeedback, // Include in constructor
  });

  // Convert a Question object into a Map object (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'lesson_uuid': lessonUuid,
      'question_text': questionText,
      'question_type': questionType,
      'options': options != null ? jsonEncode(options) : null, // Store as JSON string
      'correct_answer': correctAnswerText,
      'difficulty_level': difficultyLevel,
      'expected_time_seconds': expectedTimeSeconds, // Include in map
      'ai_generated_feedback': aiGeneratedFeedback, // Include in map
    };
  }

  // Convert a Map object into a Question object (from SQLite)
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      uuid: map['uuid'] as String,
      lessonUuid: map['lesson_uuid'] as String,
      questionText: map['question_text'] as String,
      questionType: map['question_type'] as String,
      options: map['options'] != null ? List<String>.from(jsonDecode(map['options'] as String)) : null,
      correctAnswerText: map['correct_answer'] as String,
      difficultyLevel: map['difficulty_level'] as String,
      expectedTimeSeconds: map['expected_time_seconds'] as int?, // Retrieve from map
      aiGeneratedFeedback: map['ai_generated_feedback'] as String?, // Retrieve from map
    );
  }

  // Convert a Question object into a JSON object (for API)
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'lesson': lessonUuid, // Use backend's field name 'lesson' for UUID
      'question_text': questionText,
      'question_type': questionType,
      'options': options,
      'correct_answer_text': correctAnswerText, // Use backend's field name
      'difficulty_level': difficultyLevel,
      'expected_time_seconds': expectedTimeSeconds, // Include in JSON
      'ai_generated_feedback': aiGeneratedFeedback, // Include in JSON
    };
  }

  // Factory constructor to create a Question from JSON (from API)
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      uuid: json['uuid'] as String,
      lessonUuid: json['lesson'] as String, // This will now correctly map to the new field from Django
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      options: (json['options'] as List?)?.map((e) => e as String).toList(),
      correctAnswerText: json['correct_answer_text'] as String,
      difficultyLevel: json['difficulty_level'] as String,
      expectedTimeSeconds: json['expected_time_seconds'] as int?, // Include from JSON
      aiGeneratedFeedback: json['ai_generated_feedback'] as String?,
    );
  }
}
