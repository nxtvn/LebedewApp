// Rename file to trouble_report_screen_android.dart
// Move file to lib/presentation/android/trouble_report_screen_android.dart
import 'package:flutter/material.dart';
import '../../core/platform/platform_helper.dart';
import '../android/trouble_report_screen_android.dart';
import '../ios/trouble_report_screen_ios.dart';

/// Plattformübergreifende Störungsmeldungsansicht
/// 
/// Diese Klasse verwendet PlatformHelper, um die richtige
/// plattformspezifische Implementierung auszuwählen.
class TroubleReportScreen extends StatelessWidget {
  const TroubleReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformHelper.platformWidget(
      iosBuilder: () => const TroubleReportScreenIOS(),
      androidBuilder: () => const TroubleReportScreenAndroid(),
    );
  }
} 