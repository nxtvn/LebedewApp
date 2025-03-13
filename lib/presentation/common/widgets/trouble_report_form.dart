import 'package:flutter/material.dart';
import '../../../domain/entities/trouble_report.dart';

/// Abstrakte Basisklasse für Störungsmeldungsformulare
abstract class TroubleReportForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(TroubleReport) onSubmit;
  
  const TroubleReportForm({
    Key? key,
    required this.formKey,
    required this.onSubmit,
  }) : super(key: key);
}

// Definiere ein Mixin für den Reset-Vorgang
mixin TroubleReportFormResetMixin {
  void reset();
} 