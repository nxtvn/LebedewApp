import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'app_config.dart';
import '../../domain/services/email_service.dart';
import '../../data/services/mailjet_email_service.dart';
import '../../data/services/local_image_storage_service.dart';
import '../../domain/repositories/trouble_report_repository.dart';
import '../../data/repositories/trouble_report_repository_impl.dart';
import '../../presentation/common/viewmodels/trouble_report_viewmodel.dart';
import '../../domain/services/image_storage_service.dart';
import '../../data/services/email_queue_service.dart';
import '../network/network_info_facade.dart';
import '../network/network_error_handler.dart';

final getIt = GetIt.instance;

/// Initialisiert die Abhängigkeitsinjektionen
/// 
/// Diese Methode muss nach der Initialisierung von AppConfig aufgerufen werden.
Future<void> setupDependencies() async {
  final log = Logger('DependencyInjection');
  log.info('Initialisiere Abhängigkeiten');
  
  // Netzwerkdienste
  log.info('Registriere NetworkInfoFacade');
  getIt.registerLazySingleton<NetworkInfoFacade>(
    () => NetworkInfoFacade(),
  );
  
  log.info('Registriere NetworkErrorHandler');
  getIt.registerLazySingleton<NetworkErrorHandler>(
    () => NetworkErrorHandler(getIt<NetworkInfoFacade>()),
  );
  
  // Services
  log.info('Registriere EmailQueueService');
  getIt.registerLazySingleton<EmailQueueService>(
    () => EmailQueueService(),
  );

  // Hole die API-Schlüssel asynchron
  log.info('Lade API-Schlüssel aus AppConfig');
  final mailjetApiKey = await AppConfig.mailjetApiKey;
  final mailjetSecretKey = await AppConfig.mailjetSecretKey;
  final serviceEmail = await AppConfig.serviceEmail;
  
  // Überprüfe, ob die API-Schlüssel vorhanden sind
  if (mailjetApiKey.isEmpty || mailjetSecretKey.isEmpty || serviceEmail.isEmpty) {
    log.warning('API-Schlüssel fehlen oder sind leer!');
    log.warning('Mailjet API-Key: ${mailjetApiKey.isEmpty ? "Fehlt" : "Vorhanden"}');
    log.warning('Mailjet Secret-Key: ${mailjetSecretKey.isEmpty ? "Fehlt" : "Vorhanden"}');
    log.warning('Service-E-Mail: ${serviceEmail.isEmpty ? "Fehlt" : "Vorhanden"}');
    
    // Im Debug-Modus können wir Platzhalter verwenden
    if (AppConfig.isDevelopment) {
      log.info('Entwicklungsmodus: Setze Platzhalter für fehlende API-Schlüssel');
      
      if (mailjetApiKey.isEmpty) {
        await AppConfig.setApiKey(ConfigKeys.mailjetApiKey, 'dev_api_key');
      }
      
      if (mailjetSecretKey.isEmpty) {
        await AppConfig.setApiKey(ConfigKeys.mailjetSecretKey, 'dev_secret_key');
      }
      
      if (serviceEmail.isEmpty) {
        await AppConfig.setApiKey(ConfigKeys.serviceEmail, 'dev@example.com');
      }
    }
  }

  log.info('Registriere EmailService');
  getIt.registerLazySingleton<EmailService>(
    () => MailjetEmailService(
      apiKey: mailjetApiKey,
      secretKey: mailjetSecretKey,
      toEmail: serviceEmail,
      queueService: getIt<EmailQueueService>(),
    ),
  );
  
  log.info('Registriere ImageStorageService');
  getIt.registerLazySingleton<ImageStorageService>(
    () => LocalImageStorageService(),
  );

  // Repositories
  log.info('Registriere TroubleReportRepository');
  getIt.registerLazySingleton<TroubleReportRepository>(
    () => TroubleReportRepositoryImpl(
      getIt<EmailService>(),
      getIt<ImageStorageService>(),
    ),
  );

  // ViewModels
  log.info('Registriere TroubleReportViewModel');
  getIt.registerFactory(
    () => TroubleReportViewModel(getIt<TroubleReportRepository>()),
  );
  
  log.info('Abhängigkeiten initialisiert');
} 