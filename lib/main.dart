import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'core/config/app_config.dart';
import 'core/config/env.dart';
import 'core/config/injection.dart';
import 'core/constants/app_constants.dart';
import 'core/logging/app_logger.dart';
import 'core/platform/platform_helper.dart';
import 'core/theme/app_theme.dart';
import 'core/network/network_info_facade.dart';
import 'data/services/email_queue_service.dart';
import 'domain/services/email_service.dart';
import 'domain/services/image_storage_service.dart';
import 'presentation/common/widgets/offline_status_banner.dart';
import 'presentation/screens/login_screen.dart';
import 'core/config/config_importer.dart';

void main() async {
  // Initialisiere Flutter-Binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Konfiguriere Logger
  await _setupLogging();
  
  // Initialisiere Konfiguration
  await _initializeConfig();
  
  // Initialisiere Dependency Injection
  await setupDependencies();
  
  // Starte die App
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppTheme>(
          create: (_) => AppTheme(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Konfiguriert das Logging-System
Future<void> _setupLogging() async {
  // Initialisiere das erweiterte Logging-System
  await AppLogger.initialize();
  
  // Konfiguriere das Root-Logger für Abwärtskompatibilität
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('Stack trace: ${record.stackTrace}');
    }
  });
  
  // Hole einen Logger für die Hauptanwendung
  final log = AppLogger.getLogger('Main');
  log.info('Logging-System initialisiert');
}

/// Initialisiert die Konfiguration
Future<void> _initializeConfig() async {
  final log = Logger('Config');
  
  // Bestimme die Umgebung (in einer echten App würde dies basierend auf Build-Flags erfolgen)
  const env = bool.fromEnvironment('dart.vm.product') 
      ? Environment.production 
      : Environment.development;
  
  log.info('Initialisiere Konfiguration für Umgebung: $env');
  
  // Initialisiere AppConfig
  await AppConfig.initialize(
    env: env,
    resetSecureStorage: false, // Auf true setzen, um alle gespeicherten Werte zurückzusetzen
  );
  
  // Lade die externe Konfigurationsdatei aus den Assets
  try {
    log.info('Lade externe Konfigurationsdatei aus Assets');
    
    // Importiere die Konfiguration aus der config.json Datei
    final success = await ConfigImporter.importFromAsset('assets/config/config.json');
    
    if (success) {
      log.info('Konfiguration aus Assets erfolgreich geladen');
    } else {
      log.warning('Fehler beim Laden der Konfiguration aus Assets. Verwende Standardwerte.');
    }
  } catch (e) {
    log.severe('Fehler beim Laden der Konfigurationsdatei: $e');
  }
  
  // Initialisiere Env für Abwärtskompatibilität
  await Env.initialize();
  
  log.info('Konfiguration initialisiert');
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // Falls ein Service-Locator verwendet wird, sollten globale Instanzen hier freigegeben werden
    try {
      final log = Logger('AppDisposal');
      log.info('Beende Anwendung und bereinige Ressourcen');
      
      // Bereinige Netzwerkdienste
      final networkInfo = GetIt.I<NetworkInfoFacade>();
      networkInfo.dispose();
      
      // Bereinige E-Mail-Dienste
      final emailQueueService = GetIt.I<EmailQueueService>();
      emailQueueService.dispose();
      
      // Lösche alle sensiblen Daten aus dem Speicher
      final emailService = GetIt.I<EmailService>();
      emailService.dispose();
      
      // Bereinige Bildspeicherdienste
      final imageStorageService = GetIt.I<ImageStorageService>();
      imageStorageService.dispose();
      
      // Sicheres Löschen aller Konfigurationsdaten im Speicher
      AppConfig.securelyWipeAllFromMemory().then((_) {
        log.info('Alle sensiblen Daten wurden sicher aus dem Speicher gelöscht');
      });
      
      log.info('Alle Ressourcen wurden erfolgreich freigegeben');
    } catch (e) {
      // Diese Services könnten bereits entfernt worden sein
      debugPrint('Fehler beim Freigeben von Ressourcen: $e');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.isIOS()) {
      return const CupertinoApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('de', 'DE')],
        home: OfflineAwareApp(
          platform: AppPlatform.ios,
          child: LoginScreen(),
        ),
      );
    } else {
      return MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(),
        builder: (context, child) {
          return ScaffoldMessenger(
            child: child ?? const SizedBox.shrink(),
          );
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de', 'DE')],
        locale: const Locale('de', 'DE'),
        home: const OfflineAwareApp(
          platform: AppPlatform.android,
          child: LoginScreen(),
        ),
      );
    }
  }
}

/// Plattform-Enum für die App
enum AppPlatform {
  ios,
  android,
}

/// Wrapper für die Offline-Statusanzeige
/// 
/// Diese Komponente umhüllt die gesamte App und zeigt ein Banner an,
/// wenn keine Internetverbindung besteht.
class OfflineAwareApp extends StatefulWidget {
  final Widget child;
  final AppPlatform platform;
  
  const OfflineAwareApp({
    Key? key,
    required this.child,
    required this.platform,
  }) : super(key: key);
  
  @override
  State<OfflineAwareApp> createState() => _OfflineAwareAppState();
}

class _OfflineAwareAppState extends State<OfflineAwareApp> {
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    // Clean resource disposal
    try {
      getIt<EmailQueueService>().dispose();
      getIt<EmailService>().dispose();
      getIt<ImageStorageService>().dispose();
    } catch (e) {
      debugPrint('Fehler beim Freigeben von Ressourcen in OfflineAwareApp: $e');
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Für iOS verwenden wir einen CupertinoScaffold
    if (widget.platform == AppPlatform.ios) {
      return CupertinoPageScaffold(
        navigationBar: null,
        child: OfflineStatusBanner(
          child: widget.child,
        ),
      );
    }
    
    // Für Android verwenden wir einen MaterialScaffold
    return Scaffold(
      body: OfflineStatusBanner(
        child: widget.child,
      ),
    );
  }
}

