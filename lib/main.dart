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
        theme: CupertinoThemeData(),
        home: LoginScreen(),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('de', 'DE')],
      );
    } else {
      return MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(),
        home: const LoginScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de', 'DE')],
        locale: const Locale('de', 'DE'),
      );
    }
  }
} 