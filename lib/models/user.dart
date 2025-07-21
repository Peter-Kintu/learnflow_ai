// learnflow_ai/flutter_app/lib/models/user.dart

class User {
  final int id; // User ID (Primary Key)
  final String username;
  final String? email;
  final bool isStaff; // To distinguish between student and teacher/admin

  User({
    required this.id, // ID is required once a User object is created/fetched
    required this.username,
    this.email,
    this.isStaff = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle cases where 'id' might come as 'user_id' or just 'id'
    // Ensure 'id' is always an integer. If missing, it's a critical error.
    final int? userId = json['user_id'] ?? json['id'];
    if (userId == null) {
      throw FormatException("User ID is missing from JSON: $json");
    }

    return User(
      id: userId,
      username: json['username'],
      email: json['email'],
      isStaff: json['is_staff'] ?? false, // Default to false if not provided
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_staff': isStaff,
    };
  }

  // Method to convert to a format suitable for local storage (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_staff': isStaff ? 1 : 0, // SQLite stores boolean as integer
    };
  }

  // Method to create from a map (for local storage retrieval)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      isStaff: map['is_staff'] == 1, // Convert integer back to boolean
    );
  }
}
