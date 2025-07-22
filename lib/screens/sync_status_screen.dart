// learnflow_ai/flutter_app/lib/screens/sync_status_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:learnflow_ai/services/api_service.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final ApiService _apiService = ApiService();
  List<QuizAttempt> _pendingAttempts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingAttempts();
  }

  Future<void> _fetchPendingAttempts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final attempts = await _databaseService.getPendingQuizAttempts();
      setState(() {
        _pendingAttempts = attempts;
        _isLoading = false;
      });
      print('SyncStatusScreen: Fetched ${_pendingAttempts.length} pending quiz attempts from local DB.');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load pending attempts: $e';
        _isLoading = false;
      });
      print('SyncStatusScreen: Error fetching pending attempts: $e');
    }
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    if (_pendingAttempts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending data to sync.')),
      );
      setState(() { _isSyncing = false; });
      return;
    }

    try {
      print('SyncStatusScreen: Starting synchronization of ${_pendingAttempts.length} attempts...');
      final result = await _apiService.uploadQuizAttempts(_pendingAttempts);

      if (result['success']) {
        print('SyncStatusScreen: Quiz attempts uploaded successfully. Updating local status...');
        for (var attempt in _pendingAttempts) {
          await _databaseService.updateQuizAttempt(attempt.copyWith(
            syncedAt: DateTime.now(),
            syncStatus: 'SYNCED',
          ));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data synced successfully!')),
        );
        print('SyncStatusScreen: Local sync statuses updated.');
      } else {
        _errorMessage = result['message'] ?? 'Failed to sync data.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        print('SyncStatusScreen: Sync failed: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Network error during sync: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
      print('SyncStatusScreen: Network error during sync: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
      await _fetchPendingAttempts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        backgroundColor: Colors.deepPurple.shade900, // Even darker purple for app bar
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.indigo.shade800, Colors.purple.shade700], // Deeper, richer gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(28.0), // Increased padding
              child: _isSyncing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton.icon(
                      onPressed: _syncData,
                      icon: const Icon(Icons.cloud_upload_rounded, size: 30), // Larger, rounded icon
                      label: const Text('Sync Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700, // Richer green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20), // Larger button
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded
                        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), // Larger, bolder text
                        elevation: 12, // More shadow
                        shadowColor: Colors.black.withOpacity(0.7),
                      ),
                    ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 15.0), // Increased padding
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 17, fontWeight: FontWeight.w700), // Bolder, larger error text
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _pendingAttempts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 120, color: Colors.green.shade400), // Even larger, rounded, brighter green icon
                              SizedBox(height: 30), // Increased spacing
                              Text(
                                'All data synced! No pending items.',
                                style: TextStyle(
                                  fontSize: 24, // Even larger font
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(blurRadius: 10.0, color: Colors.black54, offset: Offset(2.0, 2.0)),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(25.0), // Increased padding
                          itemCount: _pendingAttempts.length,
                          itemBuilder: (context, index) {
                            final attempt = _pendingAttempts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 12), // Increased vertical margin
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded
                              elevation: 8, // More shadow
                              shadowColor: Colors.black.withOpacity(0.4),
                              child: Padding(
                                padding: const EdgeInsets.all(25.0), // Increased padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attempt UUID: ${attempt.uuid.substring(0, 8)}...',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple.shade800), // Bolder, larger, darker purple
                                    ),
                                    SizedBox(height: 10),
                                    Text('Question UUID: ${attempt.questionUuid.substring(0, 8)}...', style: TextStyle(fontSize: 16, color: Colors.grey.shade900)),
                                    Text('Submitted: "${attempt.submittedAnswer}"', style: TextStyle(fontSize: 16, color: Colors.grey.shade900)),
                                    Text('Correct: ${attempt.isCorrect ? 'Yes' : 'No'}', style: TextStyle(fontSize: 16, color: Colors.grey.shade900)),
                                    Text('Score: ${attempt.score.toStringAsFixed(1)}', style: TextStyle(fontSize: 16, color: Colors.grey.shade900)),
                                    Text('Feedback: ${attempt.aiFeedbackText ?? 'N/A'}', style: TextStyle(fontSize: 16, color: Colors.grey.shade900)),
                                    Text('Status: ${attempt.syncStatus}', style: TextStyle(fontSize: 16, color: Colors.grey.shade900)),
                                    Text('Timestamp: ${attempt.attemptTimestamp.toLocal().toString().split('.')[0]}', style: TextStyle(fontSize: 16, color: Colors.grey.shade900)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to allow copying QuizAttempt for immutability
extension QuizAttemptCopyWith on QuizAttempt {
  QuizAttempt copyWith({
    String? uuid,
    int? studentUserId,
    String? questionUuid,
    String? submittedAnswer,
    bool? isCorrect,
    double? score,
    String? aiFeedbackText,
    Map<String, dynamic>? rawAiResponse,
    DateTime? attemptTimestamp,
    DateTime? syncedAt,
    String? syncStatus,
    String? deviceId,
  }) {
    return QuizAttempt(
      uuid: uuid ?? this.uuid,
      studentUserId: studentUserId ?? this.studentUserId,
      questionUuid: questionUuid ?? this.questionUuid,
      submittedAnswer: submittedAnswer ?? this.submittedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      score: score ?? this.score,
      aiFeedbackText: aiFeedbackText ?? this.aiFeedbackText,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      attemptTimestamp: attemptTimestamp ?? this.attemptTimestamp,
      syncedAt: syncedAt ?? this.syncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
