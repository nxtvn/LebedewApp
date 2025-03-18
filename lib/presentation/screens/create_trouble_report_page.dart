import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../android/trouble_report_form_android.dart';
import '../ios/trouble_report_form_ios.dart';
import '../../core/platform/platform_helper.dart';
import '../../application/trouble_report/trouble_report_notifier.dart';
import '../../domain/entities/trouble_report.dart';

class CreateTroubleReportPage extends ConsumerWidget {
  const CreateTroubleReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Handler für die Formularübermittlung
    Future<void> handleSubmit(TroubleReport report) async {
      // Leere Bilderliste als temporäre Lösung
      final List<File> images = [];
      
      // Sende die Störungsmeldung über den Notifier
      await ref.read(troubleReportNotifierProvider.notifier).submitReport(report, images);
    }
    
    if (PlatformHelper.isIOS()) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Störungsmeldung erstellen'),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TroubleReportFormIOS(
              onSubmit: handleSubmit,
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Störungsmeldung erstellen'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TroubleReportFormAndroid(
            onSubmit: handleSubmit,
          ),
        ),
      );
    }
  }
} 