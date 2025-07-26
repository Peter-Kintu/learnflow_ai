// learnflow_ai/flutter_app/lib/models/lesson.dart

class Lesson {
  final String uuid;
  final String title;
  final String description;
  final String? subject;
  final String? difficultyLevel;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lessonFile; // Ensure this field is present
  final List<String>? prerequisites; // List of lesson UUIDs that are prerequisites

  Lesson({
    required this.uuid,
    required this.title,
    required this.description,
    this.subject,
    this.difficultyLevel,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.lessonFile, // Ensure it's in the constructor
    this.prerequisites,
  });

  // Convert a Lesson object into a Map object (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'subject': subject,
      'difficulty_level': difficultyLevel,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'lesson_file': lessonFile, // Ensure it's included here
      // Prerequisites are not directly stored as a column in SQLite for simplicity
      // If needed, they would be stored as a JSON string or in a separate join table.
    };
  }

  // Convert a Map object into a Lesson object (from SQLite)
  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      subject: map['subject'] as String?,
      difficultyLevel: map['difficulty_level'] as String?,
      version: map['version'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lessonFile: map['lesson_file'] as String?, // Ensure it's retrieved here
      prerequisites: null, // Prerequisites are not retrieved from SQLite in this simple map
    );
  }

  // Convert a Lesson object into a JSON object (for API)
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'subject': subject,
      'difficulty_level': difficultyLevel,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'lesson_file': lessonFile, // Ensure it's included here for API
      'prerequisites': prerequisites,
    };
  }

  // Factory constructor to create a Lesson from JSON (from API)
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      subject: json['subject'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      version: json['version'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lessonFile: json['lesson_file'] as String?, // Ensure it's retrieved here from JSON
      prerequisites: (json['prerequisites'] as List?)?.map((e) => e as String).toList(),
    );
  }
}
