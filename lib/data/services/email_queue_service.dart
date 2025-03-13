import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/trouble_report.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/network/network_info_facade.dart';

class EmailQueueItem {
  final String subject;
  final String body;
  final String toEmail;
  final String? fromEmail;
  final String? fromName;
  final List<String>? attachmentPaths;
  final DateTime createdAt;

  EmailQueueItem({
    required this.subject,
    required this.body,
    required this.toEmail,
    this.fromEmail,
    this.fromName,
    this.attachmentPaths,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'body': body,
      'toEmail': toEmail,
      'fromEmail': fromEmail,
      'fromName': fromName,
      'attachmentPaths': attachmentPaths,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmailQueueItem.fromJson(Map<String, dynamic> json) {
    return EmailQueueItem(
      subject: json['subject'],
      body: json['body'],
      toEmail: json['toEmail'],
      fromEmail: json['fromEmail'],
      fromName: json['fromName'],
      attachmentPaths: json['attachmentPaths'] != null
          ? List<String>.from(json['attachmentPaths'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

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
  static const String _simpleQueueFileName = 'simple_email_queue.json';
  final List<QueuedEmail> _queue = [];
  final List<EmailQueueItem> _simpleQueue = [];
  bool _isProcessing = false;
  bool _isProcessingSimple = false;
  StreamSubscription<bool>? _networkSubscription;

  Future<String> get _queueFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_queueFileName';
  }

  Future<String> get _simpleQueueFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_simpleQueueFileName';
  }

  Future<void> initialize() async {
    try {
      // Lade die Störungsmeldungs-Queue
      final file = File(await _queueFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _queue.addAll(
          jsonList.map((item) => QueuedEmail.fromJson(item)).toList(),
        );
        _log.info('Störungsmeldungs-Queue geladen: ${_queue.length} E-Mails');
      }

      // Lade die einfache E-Mail-Queue
      final simpleFile = File(await _simpleQueueFilePath);
      if (await simpleFile.exists()) {
        final content = await simpleFile.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _simpleQueue.addAll(
          jsonList.map((item) => EmailQueueItem.fromJson(item)).toList(),
        );
        _log.info('Einfache E-Mail-Queue geladen: ${_simpleQueue.length} E-Mails');
      }
    } catch (e) {
      _log.severe('Fehler beim Laden der Queue: $e');
    }
  }

  /// Verbindet den E-Mail-Queue-Service mit dem Netzwerk-Listener
  /// 
  /// Diese Methode registriert einen Listener für Netzwerkänderungen und
  /// versucht, die E-Mail-Warteschlange zu synchronisieren, wenn die
  /// Netzwerkverbindung wiederhergestellt wird.
  void connectToNetworkMonitor(NetworkInfoFacade networkInfo) {
    // Bestehende Subscription beenden, falls vorhanden
    _networkSubscription?.cancel();
    
    // Neuen Listener registrieren
    _networkSubscription = networkInfo.isConnected.listen((isConnected) {
      if (isConnected && hasQueuedEmails) {
        _log.info('Netzwerkverbindung wiederhergestellt. Versuche, ausstehende E-Mails zu senden.');
        syncQueuedEmails();
      }
    });
    
    _log.info('E-Mail-Queue-Service mit Netzwerk-Monitor verbunden');
  }
  
  /// Synchronisiert die E-Mail-Warteschlange, wenn die Netzwerkverbindung verfügbar ist
  /// 
  /// Diese Methode wird aufgerufen, wenn die Netzwerkverbindung wiederhergestellt wird,
  /// und versucht, alle ausstehenden E-Mails zu senden.
  Future<void> syncQueuedEmails() async {
    _log.info('Starte Synchronisierung der E-Mail-Warteschlange');
    
    if (!hasQueuedEmails) {
      _log.info('Keine ausstehenden E-Mails in der Warteschlange');
      return;
    }
    
    // Diese Methode wird von außen aufgerufen und erwartet die Callback-Funktionen
    // zum Senden der E-Mails. Da wir diese hier nicht haben, loggen wir nur eine Nachricht.
    _log.info('E-Mail-Warteschlange enthält $queueLength ausstehende E-Mails');
    _log.info('Störungsmeldungen: $troubleReportQueueLength, Einfache E-Mails: $simpleEmailQueueLength');
    
    // Die tatsächliche Verarbeitung erfolgt in der Implementierung des E-Mail-Services,
    // der die processQueue-Methode aufruft.
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

  Future<void> _saveSimpleQueue() async {
    try {
      final file = File(await _simpleQueueFilePath);
      final jsonList = _simpleQueue.map((email) => email.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      _log.severe('Fehler beim Speichern der einfachen Queue: $e');
    }
  }

  Future<void> addToQueue(TroubleReport report, List<String> imagePaths) async {
    _queue.add(QueuedEmail(
      report: report,
      imagePaths: imagePaths,
      timestamp: DateTime.now(),
    ));
    await _saveQueue();
    _log.info('Störungsmeldung zur Queue hinzugefügt');
  }

  Future<void> addSimpleEmailToQueue(EmailQueueItem email) async {
    _simpleQueue.add(email);
    await _saveSimpleQueue();
    _log.info('Einfache E-Mail zur Queue hinzugefügt');
  }

  Future<void> processQueue(Future<bool> Function(TroubleReport, List<File>) sendEmail) async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    _log.info('Starte Verarbeitung der Störungsmeldungs-Queue: ${_queue.length} E-Mails');

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
            _log.info('Queued Störungsmeldung erfolgreich gesendet');
          }
        } catch (e) {
          _log.warning('Fehler beim Senden einer Queued Störungsmeldung: $e');
        }
      }

      // Erfolgreiche E-Mails aus der Queue entfernen
      _queue.removeWhere((email) => successfulEmails.contains(email));
      await _saveQueue();
      
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> processSimpleQueue(Future<bool> Function(EmailQueueItem) sendEmail) async {
    if (_isProcessingSimple || _simpleQueue.isEmpty) return;

    _isProcessingSimple = true;
    _log.info('Starte Verarbeitung der einfachen E-Mail-Queue: ${_simpleQueue.length} E-Mails');

    try {
      final List<EmailQueueItem> successfulEmails = [];

      for (final queuedEmail in _simpleQueue) {
        try {
          final success = await sendEmail(queuedEmail);
          
          if (success) {
            successfulEmails.add(queuedEmail);
            _log.info('Queued einfache E-Mail erfolgreich gesendet');
          }
        } catch (e) {
          _log.warning('Fehler beim Senden einer Queued einfachen E-Mail: $e');
        }
      }

      // Erfolgreiche E-Mails aus der Queue entfernen
      _simpleQueue.removeWhere((email) => successfulEmails.contains(email));
      await _saveSimpleQueue();
      
    } finally {
      _isProcessingSimple = false;
    }
  }

  bool get hasQueuedEmails => _queue.isNotEmpty || _simpleQueue.isNotEmpty;
  int get queueLength => _queue.length + _simpleQueue.length;
  int get troubleReportQueueLength => _queue.length;
  int get simpleEmailQueueLength => _simpleQueue.length;

  /// Gibt Ressourcen frei
  void dispose() {
    // Netzwerk-Subscription abmelden
    _networkSubscription?.cancel();
    
    // Speichere alle ausstehenden Änderungen, bevor die Instanz verworfen wird
    if (_queue.isNotEmpty) {
      _saveQueue();
    }
    
    if (_simpleQueue.isNotEmpty) {
      _saveSimpleQueue();
    }
    
    _log.info('E-Mail-Queue-Service beendet');
  }

  /// Lädt die E-Mail-Warteschlange
  /// Diese Methode ist für die Abwärtskompatibilität mit älteren Versionen
  Future<void> loadQueue() async {
    await initialize();
  }
} 