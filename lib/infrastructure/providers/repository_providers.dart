import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/trouble_report_repository.dart';
import '../../data/repositories/trouble_report_repository_impl.dart';
import 'service_providers.dart';

/// Provider für das TroubleReport-Repository
/// 
/// Dieses Repository ist zuständig für die Verwaltung von Störungsmeldungen,
/// einschließlich des Sendens, Speicherns und Abrufens.
final troubleReportRepositoryProvider = Provider<TroubleReportRepository>((ref) {
  final emailService = ref.read(emailServiceProvider);
  final imageStorageService = ref.read(imageStorageServiceProvider);
  
  return TroubleReportRepositoryImpl(emailService, imageStorageService);
}); 