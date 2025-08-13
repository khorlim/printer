import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:tunaipro/extra_utils/printer/src/print_commander/super_print_commander.dart';

/// Represents a print job in the queue
class PrintJob {
  final String id;
  final SuperPrintCommander commands;
  final Completer<bool> completer;
  final DateTime createdAt;
  final int priority;

  PrintJob({
    required this.id,
    required this.commands,
    required this.completer,
    required this.createdAt,
    this.priority = 0,
  });

  @override
  String toString() {
    return 'PrintJob(id: $id, priority: $priority, createdAt: $createdAt)';
  }
}

/// Manages the print queue and processes print jobs sequentially
class PrintQueue {
  final Queue<PrintJob> _queue = Queue<PrintJob>();
  final Map<String, PrintJob> _activeJobs = {};
  bool _isProcessing = false;
  final int _maxRetries = 3;
  final Duration _retryDelay = Duration(milliseconds: 500);

  /// Callback function to execute the actual print command
  final Future<bool> Function(SuperPrintCommander commands) _printExecutor;

  PrintQueue(this._printExecutor);

  /// Add a print job to the queue
  Future<bool> addJob(PrintJob job) async {
    _queue.add(job);
    debugPrint(
        'Print job added to queue: ${job.id} (Queue size: ${_queue.length})');

    if (!_isProcessing) {
      _processQueue();
    }

    return job.completer.future;
  }

  /// Process the print queue
  void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    debugPrint('Starting to process print queue (${_queue.length} jobs)');

    while (_queue.isNotEmpty) {
      final job = _queue.removeFirst();
      _activeJobs[job.id] = job;

      try {
        debugPrint('Processing print job: ${job.id}');
        final result = await _executePrintJob(job);
        job.completer.complete(result);
      } catch (e) {
        debugPrint('Print job failed: ${job.id}, Error: $e');
        job.completer.completeError(e);
      } finally {
        _activeJobs.remove(job.id);
      }

      // Small delay between jobs to prevent overwhelming the printer
      if (_queue.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    _isProcessing = false;
    debugPrint('Print queue processing completed');
  }

  /// Execute a single print job with retry logic
  Future<bool> _executePrintJob(PrintJob job) async {
    int attempts = 0;

    while (attempts < _maxRetries) {
      try {
        attempts++;
        debugPrint(
            'Executing print job ${job.id} (Attempt $attempts/$_maxRetries)');

        // Execute the print command using the provided executor
        bool success = await _printExecutor(job.commands);

        if (success) {
          debugPrint('Print job ${job.id} completed successfully');
          return true;
        } else {
          debugPrint('Print job ${job.id} failed, will retry');
          if (attempts < _maxRetries) {
            await Future.delayed(_retryDelay);
          }
        }
      } catch (e) {
        debugPrint('Print job ${job.id} error on attempt $attempts: $e');
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    debugPrint('Print job ${job.id} failed after $_maxRetries attempts');
    return false;
  }

  /// Get current queue status
  Map<String, dynamic> getStatus() {
    return {
      'queueSize': _queue.length,
      'activeJobs': _activeJobs.length,
      'isProcessing': _isProcessing,
    };
  }

  /// Clear all pending jobs
  void clearQueue() {
    final pendingJobs = _queue.toList();
    _queue.clear();

    for (final job in pendingJobs) {
      job.completer.complete(false);
    }

    debugPrint('Print queue cleared, ${pendingJobs.length} jobs cancelled');
  }

  /// Remove a specific job from the queue
  bool removeJob(String jobId) {
    final job = _queue.firstWhere(
      (job) => job.id == jobId,
      orElse: () => throw StateError('Job not found'),
    );

    _queue.remove(job);
    job.completer.complete(false);
    debugPrint('Print job $jobId removed from queue');
    return true;
  }

  /// Get the number of jobs in the queue
  int get queueLength => _queue.length;

  /// Check if the queue is currently processing
  bool get isProcessing => _isProcessing;
}
