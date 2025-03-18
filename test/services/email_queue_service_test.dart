import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebedew_app/data/services/email_queue_service.dart';
import 'package:lebedew_app/domain/entities/trouble_report.dart';
import 'package:lebedew_app/domain/enums/request_type.dart';
import 'package:lebedew_app/domain/enums/urgency_level.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Define a class for the mock platform
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return './test/tmp';
  }
  
  // Implement required methods
  @override
  Future<String?> getApplicationSupportPath() async {
    return './test/tmp';
  }
  
  @override
  Future<String?> getApplicationCachePath() async {
    return './test/tmp';
  }
  
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async {
    return ['./test/tmp'];
  }
  
  @override
  Future<String?> getExternalStoragePath() async {
    return './test/tmp';
  }
  
  @override
  Future<List<String>?> getExternalCachePaths() async {
    return ['./test/tmp'];
  }
  
  @override
  Future<String?> getDownloadsPath() async {
    return './test/tmp';
  }
  
  @override
  Future<String?> getTemporaryPath() async {
    return './test/tmp';
  }
}

void main() {
  late EmailQueueService emailQueueService;
  late Directory tempDir;

  setUp(() async {
    // Setze den Mock für PathProvider
    final mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;
    
    // Erstelle temporäres Verzeichnis für Tests
    tempDir = await Directory('./test/tmp').create(recursive: true);
    
    // Initialisiere den EmailQueueService
    emailQueueService = EmailQueueService();
    await emailQueueService.initialize();
  });

  tearDown(() async {
    // Lösche temporäres Verzeichnis nach den Tests
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('EmailQueueService sollte eine leere Queue haben', () {
    expect(emailQueueService.hasQueuedEmails, isFalse);
    expect(emailQueueService.queueLength, equals(0));
    expect(emailQueueService.troubleReportQueueLength, equals(0));
    expect(emailQueueService.simpleEmailQueueLength, equals(0));
  });

  test('EmailQueueService sollte eine Störungsmeldung zur Queue hinzufügen können', () async {
    // Erstelle eine Test-Störungsmeldung
    const report = TroubleReport(
      id: 'test-id-1',
      name: 'Test User',
      email: 'test@example.com',
      description: 'Test Description',
      type: RequestType.trouble,
      urgencyLevel: UrgencyLevel.medium,
    );
    
    // Füge die Störungsmeldung zur Queue hinzu
    await emailQueueService.addToQueue(report, []);
    
    // Überprüfe, ob die Queue jetzt ein Element enthält
    expect(emailQueueService.hasQueuedEmails, isTrue);
    expect(emailQueueService.queueLength, equals(1));
    expect(emailQueueService.troubleReportQueueLength, equals(1));
    expect(emailQueueService.simpleEmailQueueLength, equals(0));
  });

  test('EmailQueueService sollte eine einfache E-Mail zur Queue hinzufügen können', () async {
    // Erstelle eine Test-E-Mail
    final email = EmailQueueItem(
      subject: 'Test Subject',
      body: 'Test Body',
      toEmail: 'test@example.com',
    );
    
    // Füge die E-Mail zur Queue hinzu
    await emailQueueService.addSimpleEmailToQueue(email);
    
    // Überprüfe, ob die Queue jetzt ein Element enthält
    expect(emailQueueService.hasQueuedEmails, isTrue);
    expect(emailQueueService.queueLength, equals(1));
    expect(emailQueueService.troubleReportQueueLength, equals(0));
    expect(emailQueueService.simpleEmailQueueLength, equals(1));
  });

  test('EmailQueueService sollte die Queue verarbeiten können', () async {
    // Erstelle eine Test-Störungsmeldung
    const report = TroubleReport(
      id: 'test-id-2',
      name: 'Test User',
      email: 'test@example.com',
      description: 'Test Description',
      type: RequestType.trouble,
      urgencyLevel: UrgencyLevel.medium,
    );
    
    // Füge die Störungsmeldung zur Queue hinzu
    await emailQueueService.addToQueue(report, []);
    
    // Verarbeite die Queue mit einer Mock-Funktion, die immer Erfolg zurückgibt
    await emailQueueService.processQueue((report, images) async {
      return true;
    });
    
    // Überprüfe, ob die Queue jetzt leer ist
    expect(emailQueueService.hasQueuedEmails, isFalse);
    expect(emailQueueService.queueLength, equals(0));
    expect(emailQueueService.troubleReportQueueLength, equals(0));
  });

  test('EmailQueueService sollte die einfache Queue verarbeiten können', () async {
    // Erstelle eine Test-E-Mail
    final email = EmailQueueItem(
      subject: 'Test Subject',
      body: 'Test Body',
      toEmail: 'test@example.com',
    );
    
    // Füge die E-Mail zur Queue hinzu
    await emailQueueService.addSimpleEmailToQueue(email);
    
    // Verarbeite die Queue mit einer Mock-Funktion, die immer Erfolg zurückgibt
    await emailQueueService.processSimpleQueue((email) async {
      return true;
    });
    
    // Überprüfe, ob die Queue jetzt leer ist
    expect(emailQueueService.hasQueuedEmails, isFalse);
    expect(emailQueueService.queueLength, equals(0));
    expect(emailQueueService.simpleEmailQueueLength, equals(0));
  });

  test('EmailQueueService sollte fehlgeschlagene E-Mails in der Queue behalten', () async {
    // Erstelle eine Test-E-Mail
    final email = EmailQueueItem(
      subject: 'Test Subject',
      body: 'Test Body',
      toEmail: 'test@example.com',
    );
    
    // Füge die E-Mail zur Queue hinzu
    await emailQueueService.addSimpleEmailToQueue(email);
    
    // Verarbeite die Queue mit einer Mock-Funktion, die immer Misserfolg zurückgibt
    await emailQueueService.processSimpleQueue((email) async {
      return false;
    });
    
    // Überprüfe, ob die E-Mail noch in der Queue ist
    expect(emailQueueService.hasQueuedEmails, isTrue);
    expect(emailQueueService.queueLength, equals(1));
    expect(emailQueueService.simpleEmailQueueLength, equals(1));
  });
} 