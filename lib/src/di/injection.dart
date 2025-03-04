import 'package:get_it/get_it.dart';
import '../core/config/env.dart';
import '../domain/services/email_service.dart';
import '../services/mailjet_email_service.dart';
import '../data/services/local_image_storage_service.dart';
import '../domain/repositories/trouble_report_repository.dart';
import '../data/repositories/trouble_report_repository_impl.dart';
import '../presentation/viewmodels/trouble_report_viewmodel.dart';
import '../domain/services/image_storage_service.dart';
import '../services/email_queue_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerLazySingleton<EmailQueueService>(
    () => EmailQueueService(),
  );

  getIt.registerLazySingleton<EmailService>(
    () => MailjetEmailService(
      apiKey: Env.mailjetApiKey,
      secretKey: Env.mailjetSecretKey,
      toEmail: Env.serviceEmail,
      queueService: getIt<EmailQueueService>(),
    ),
  );
  
  getIt.registerLazySingleton<ImageStorageService>(
    () => LocalImageStorageService(),
  );

  // Repositories
  getIt.registerLazySingleton<TroubleReportRepository>(
    () => TroubleReportRepositoryImpl(
      getIt<EmailService>(),
      getIt<ImageStorageService>(),
    ),
  );

  // ViewModels
  getIt.registerFactory(
    () => TroubleReportViewModel(getIt<TroubleReportRepository>()),
  );
} 