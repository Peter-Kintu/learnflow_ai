// learnflow_ai/flutter_app/lib/models/question.dart

class Question {
  final String uuid; // UUID from Django
  final String lessonUuid; // UUID of the associated lesson
  final int? lessonId; // ADDED: Django's integer primary key for the lesson
  final String questionText;
  final String questionType; // 'MCQ' or 'SA'
  final List<String>? options; // For MCQs
  final String? correctAnswerText; // For MCQs or keywords for SA
  final String? difficultyLevel;
  final int? expectedTimeSeconds;
  final DateTime createdAt;

  Question({
    required this.uuid,
    required this.lessonUuid,
    this.lessonId, // ADDED
    required this.questionText,
    required this.questionType,
    this.options,
    this.correctAnswerText,
    this.difficultyLevel,
    this.expectedTimeSeconds,
    required this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      uuid: json['uuid'],
      lessonUuid: json['lesson'].toString(), // Still parsing as string for consistency in Flutter model
      lessonId: json['lesson'] is int ? json['lesson'] : null, // ADDED: Parse integer ID if available
      questionText: json['question_text'],
      questionType: json['question_type'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      correctAnswerText: json['correct_answer_text'],
      difficultyLevel: json['difficulty_level'],
      expectedTimeSeconds: json['expected_time_seconds'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      // IMPORTANT: Send the integer 'lessonId' if available, otherwise fallback to 'lessonUuid' (though Django expects ID)
      'lesson': lessonId ?? lessonUuid, // Use lessonId (int) if present, else lessonUuid (str)
      'question_text': questionText,
      'question_type': questionType,
      'options': options,
      'correct_answer_text': correctAnswerText,
      'difficulty_level': difficultyLevel,
      'expected_time_seconds': expectedTimeSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Method to convert to a format suitable for local storage (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'lesson_uuid': lessonUuid,
      'lesson_id': lessonId, // Include for local storage
      'question_text': questionText,
      'question_type': questionType,
      'options': options != null ? options!.join('|||') : null, // Use a unique separator
      'correct_answer_text': correctAnswerText,
      'difficulty_level': difficultyLevel,
      'expected_time_seconds': expectedTimeSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Method to create from a map (for local storage retrieval)
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      uuid: map['uuid'],
      lessonUuid: map['lesson_uuid'],
      lessonId: map['lesson_id'], // Parse from map
      questionText: map['question_text'],
      questionType: map['question_type'],
      options: map['options'] != null
          ? (map['options'] as String).split('|||')
          : null,
      correctAnswerText: map['correct_answer_text'],
      difficultyLevel: map['difficulty_level'],
      expectedTimeSeconds: map['expected_time_seconds'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
