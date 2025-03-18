import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/email_service.dart';
import '../../domain/services/image_storage_service.dart';
import '../../data/services/email_queue_service.dart';
import '../../data/services/email_service_impl.dart';
import '../../data/services/image_storage_service_impl.dart';
import 'core_providers.dart';

/// Provider für den E-Mail-Service
/// 
/// Dieser Service ist zuständig für das Senden von E-Mails,
/// einschließlich Störungsmeldungen.
final emailServiceProvider = Provider<EmailService>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final emailQueueService = ref.read(emailQueueServiceProvider);
  
  return EmailServiceImpl(networkInfo, emailQueueService);
});

/// Provider für den E-Mail-Queue-Service
/// 
/// Dieser Service ist zuständig für die Verwaltung einer Warteschlange von E-Mails,
/// die noch nicht gesendet werden konnten.
final emailQueueServiceProvider = Provider<EmailQueueService>((ref) {
  return EmailQueueService();
});

/// Provider für den Bilderspeicher-Service
/// 
/// Dieser Service ist zuständig für die Speicherung und Verwaltung von Bildern,
/// die mit Störungsmeldungen verbunden sind.
final imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageServiceImpl();
}); 