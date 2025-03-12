import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../domain/entities/trouble_report.dart';
import 'package:logging/logging.dart';

class QueuedEmail {
  final TroubleReport report;
  final List<String> imagePaths;
  final DateTime timestamp;

  QueuedEmail({
    required this.report,
    required this.imagePaths,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'report': report.toJson(),
    'imagePaths': imagePaths,
    'timestamp': timestamp.toIso8601String(),
  };

  factory QueuedEmail.fromJson(Map<String, dynamic> json) => QueuedEmail(
    report: TroubleReport.fromJson(json['report']),
    imagePaths: List<String>.from(json['imagePaths']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class EmailQueueService {
  static final _log = Logger('EmailQueueService');
  static const String _queueFileName = 'email_queue.json';
  final List<QueuedEmail> _queue = [];
  bool _isProcessing = false;

  Future<String> get _queueFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_queueFileName';
  }

  Future<void> initialize() async {
    try {
      final file = File(await _queueFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _queue.addAll(
          jsonList.map((item) => QueuedEmail.fromJson(item)).toList(),
        );
        _log.info('Queue geladen: ${_queue.length} E-Mails');
      }
    } catch (e) {
      _log.severe('Fehler beim Laden der Queue: $e');
    }
  }

  Future<void> _saveQueue() async {
    try {
      final file = File(await _queueFilePath);
      final jsonList = _queue.map((email) => email.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      _log.severe('Fehler beim Speichern der Queue: $e');
    }
  }

  Future<void> addToQueue(TroubleReport report, List<String> imagePaths) async {
    _queue.add(QueuedEmail(
      report: report,
      imagePaths: imagePaths,
      timestamp: DateTime.now(),
    ));
    await _saveQueue();
    _log.info('E-Mail zur Queue hinzugefügt');
  }

  Future<void> processQueue(Future<bool> Function(TroubleReport, List<File>) sendEmail) async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    _log.info('Starte Verarbeitung der Queue: ${_queue.length} E-Mails');

    try {
      final List<QueuedEmail> successfulEmails = [];

      for (final queuedEmail in _queue) {
        try {
          final images = queuedEmail.imagePaths
              .map((path) => File(path))
              .where((file) => file.existsSync())
              .toList();

          final success = await sendEmail(queuedEmail.report, images);
          
          if (success) {
            successfulEmails.add(queuedEmail);
            _log.info('Queued E-Mail erfolgreich gesendet');
          }
        } catch (e) {
          _log.warning('Fehler beim Senden einer Queued E-Mail: $e');
        }
      }

      // Erfolgreiche E-Mails aus der Queue entfernen
      _queue.removeWhere((email) => successfulEmails.contains(email));
      await _saveQueue();
      
    } finally {
      _isProcessing = false;
    }
  }

  bool get hasQueuedEmails => _queue.isNotEmpty;
  int get queueLength => _queue.length;
} 