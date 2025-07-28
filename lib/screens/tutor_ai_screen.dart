import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TutorAIScreen extends StatefulWidget {
  const TutorAIScreen({Key? key}) : super(key: key);

  @override
  _TutorAIScreenState createState() => _TutorAIScreenState();
}

class _TutorAIScreenState extends State<TutorAIScreen> {
  final _studentIdController = TextEditingController();
  final _questionController = TextEditingController();
  String _subject = 'math';
  String _level = 'beginner';
  String? _answer;
  bool _isLoading = false;

  Future<void> askTutor() async {
    FocusScope.of(context).unfocus(); // hide keyboard

    if (_studentIdController.text.isEmpty || _questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _answer = null;
    });

    final url = Uri.parse("https://learn-africana-ai.onrender.com/ask_tutor");
    final body = jsonEncode({
      "student_id": _studentIdController.text,
      "subject": _subject,
      "level": _level,
      "question": _questionController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer sk-or-v1-311...bec"
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _answer = data["answer"] ?? "No answer returned.";
        });
      } else {
        setState(() {
          _answer = "Failed to get response from AI Tutor.";
        });
      }
    } catch (e) {
      setState(() {
        _answer = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI TutorBot'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ask your AI Tutor',
              style: theme.textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Your Question',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.question_answer),
              ),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _subject,
              onChanged: (val) => setState(() => _subject = val!),
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.book),
              ),
              items: [
                'math',
                'science',
                'coding',
                'english',
                'sst',
                'history',
                'biology',
                'chemistry'
              ]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                  .toList(),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _level,
              onChanged: (val) => setState(() => _level = val!),
              decoration: InputDecoration(
                labelText: 'Level',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.leaderboard),
              ),
              items: ['beginner', 'intermediate', 'advanced']
                  .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl.capitalize())))
                  .toList(),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : askTutor,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Loading...' : 'Ask Tutor'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),

            const SizedBox(height: 30),

            if (_answer != null) ...[
              Text(
                "Tutor's Response:",
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _answer!,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
}
