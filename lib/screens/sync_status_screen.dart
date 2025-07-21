// learnflow_ai/flutter_app/lib/screens/sync_status_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/models/quiz_attempt.dart';
import 'package:learnflow_ai/services/database_service.dart';
import 'package:learnflow_ai/services/api_service.dart'; // Will be used for actual sync later

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
  bool _isSyncing = false; // New state to manage sync button loading

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
    if (_isSyncing) return; // Prevent multiple syncs simultaneously

    setState(() {
      _isSyncing = true;
      _errorMessage = null; // Clear previous errors
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
        // Update local database for successfully synced attempts
        for (var attempt in _pendingAttempts) {
          // Assuming Django returns the UUIDs of successfully processed attempts
          // For simplicity, we'll mark all as SYNCED if the overall call was successful.
          // In a real app, you might parse `result['data']` for granular success/failure.
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
      // Re-fetch pending attempts to update the UI
      await _fetchPendingAttempts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.purpleAccent.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isSyncing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton.icon(
                      onPressed: _syncData,
                      icon: const Icon(Icons.cloud_upload, size: 28),
                      label: const Text('Sync Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
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
                              Icon(Icons.check_circle_outline, size: 80, color: Colors.white70),
                              SizedBox(height: 20),
                              Text(
                                'All data synced! No pending items.',
                                style: TextStyle(fontSize: 18, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _pendingAttempts.length,
                          itemBuilder: (context, index) {
                            final attempt = _pendingAttempts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attempt UUID: ${attempt.uuid.substring(0, 8)}...',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text('Question UUID: ${attempt.questionUuid.substring(0, 8)}...'),
                                    Text('Submitted: "${attempt.submittedAnswer}"'),
                                    Text('Correct: ${attempt.isCorrect ? 'Yes' : 'No'}'),
                                    Text('Score: ${attempt.score.toStringAsFixed(1)}'),
                                    Text('Feedback: ${attempt.aiFeedbackText ?? 'N/A'}'),
                                    Text('Status: ${attempt.syncStatus}'),
                                    Text('Timestamp: ${attempt.attemptTimestamp.toLocal().toString().split('.')[0]}'),
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
