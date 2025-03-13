import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/config/injection.dart';
import 'core/config/app_config.dart';
import 'core/config/env.dart';
import 'core/logging/app_logger.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/common/widgets/offline_status_banner.dart';

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
  
  // Initialisiere Env für Abwärtskompatibilität
  await Env.initialize();
  
  log.info('Konfiguration initialisiert');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
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
class OfflineAwareApp extends StatelessWidget {
  final Widget child;
  final AppPlatform platform;
  
  const OfflineAwareApp({
    Key? key,
    required this.child,
    required this.platform,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Für iOS verwenden wir einen CupertinoScaffold
    if (platform == AppPlatform.ios) {
      return CupertinoPageScaffold(
        navigationBar: null,
        child: OfflineStatusBanner(
          child: child,
        ),
      );
    }
    
    // Für Android verwenden wir einen MaterialScaffold
    return Scaffold(
      body: OfflineStatusBanner(
        child: child,
      ),
    );
  }
} 