import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/constants/app_constants.dart';
import 'src/di/injection.dart';
import 'src/presentation/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const CupertinoApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
          barBackgroundColor: CupertinoColors.systemBackground,
          textTheme: CupertinoTextThemeData(),
        ),
        home: LoginScreen(),
        localizationsDelegates: [
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [Locale('de', 'DE')],
        locale: Locale('de', 'DE'),
      );
    } else {
      return MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de', 'DE')],
        locale: const Locale('de', 'DE'),
      );
    }
  }
} 