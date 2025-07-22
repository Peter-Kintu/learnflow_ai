// learnflow_ai/flutter_app/lib/models/lesson.dart

class Lesson {
  final int? id; // CHANGED: Made nullable (int?)
  final String uuid;
  final String title;
  final String? description;
  final String? subject;
  final String? difficultyLevel;
  final String? lessonFile; // Path to lesson content file (e.g., PDF, DOCX)
  final String? prerequisites; // JSON string of prerequisite lesson UUIDs
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lesson({
    this.id, // CHANGED: No longer required
    required this.uuid,
    required this.title,
    this.description,
    this.subject,
    this.difficultyLevel,
    this.lessonFile,
    this.prerequisites,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'], // Parse the integer ID (can be null if not present)
      uuid: json['uuid'],
      title: json['title'],
      description: json['description'],
      subject: json['subject'],
      difficultyLevel: json['difficulty_level'],
      lessonFile: json['lesson_file'],
      prerequisites: json['prerequisites'],
      version: json['version'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id is usually not sent when creating, but needed for linking
      // 'id': id, // Don't include id when creating a new lesson, only when sending existing
      'uuid': uuid,
      'title': title,
      'description': description,
      'subject': subject,
      'difficulty_level': difficultyLevel,
      'lesson_file': lessonFile,
      'prerequisites': prerequisites,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Method to convert to a format suitable for local storage (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include ID for local storage
      'uuid': uuid,
      'title': title,
      'description': description,
      'subject': subject,
      'difficulty_level': difficultyLevel,
      'lesson_file': lessonFile,
      'prerequisites': prerequisites,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Method to create from a map (for local storage retrieval)
  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'], // Parse ID from map
      uuid: map['uuid'],
      title: map['title'],
      description: map['description'],
      subject: map['subject'],
      difficultyLevel: map['difficulty_level'],
      lessonFile: map['lesson_file'],
      prerequisites: map['prerequisites'],
      version: map['version'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}