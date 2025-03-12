import 'package:get_it/get_it.dart';
import 'app_config.dart';
import '../../domain/services/email_service.dart';
import '../../data/services/mailjet_email_service.dart';
import '../../data/services/local_image_storage_service.dart';
import '../../domain/repositories/trouble_report_repository.dart';
import '../../data/repositories/trouble_report_repository_impl.dart';
import '../../presentation/common/viewmodels/trouble_report_viewmodel.dart';
import '../../domain/services/image_storage_service.dart';
import '../../data/services/email_queue_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Services
  getIt.registerLazySingleton<EmailQueueService>(
    () => EmailQueueService(),
  );

  // Hole die API-Schlüssel asynchron
  final mailjetApiKey = await AppConfig.mailjetApiKey;
  final mailjetSecretKey = await AppConfig.mailjetSecretKey;
  final serviceEmail = await AppConfig.serviceEmail;

  getIt.registerLazySingleton<EmailService>(
    () => MailjetEmailService(
      apiKey: mailjetApiKey,
      secretKey: mailjetSecretKey,
      toEmail: serviceEmail,
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