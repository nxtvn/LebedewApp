import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import 'trouble_report_form_android.dart';
import '../../core/utils/error_handler.dart';

class TroubleReportScreenAndroid extends ConsumerWidget {
  const TroubleReportScreenAndroid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(troubleReportViewModelProvider);
    final viewModelNotifier = ref.read(troubleReportViewModelProvider);
    
    // Wir benötigen einen FormKey für TroubleReportFormAndroid
    final formKey = GlobalKey<FormState>();
    
    if (viewModel.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Störungsmeldung'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (viewModel.lastError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Störungsmeldung'),
        ),
        body: AppErrorHandler.buildErrorWidget(
          context, 
          viewModel.lastError!,
          onRetry: () => viewModelNotifier.clearLastError(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Störungsmeldung'),
      ),
      body: TroubleReportFormAndroid(
        onSubmit: (report) async {
          final success = await viewModelNotifier.submitReport();
          if (success && context.mounted) {
            _showSuccessMessage(context, viewModel.lastSubmissionStatus);
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Wir können keine Validierung in der FloatingActionButton vornehmen
          // da der FormKey im anderen Widget existiert
          final success = await viewModelNotifier.submitReport();
          
          if (success && context.mounted) {
            _showSuccessMessage(context, viewModel.lastSubmissionStatus);
          } else if (!success && context.mounted && viewModel.lastError != null) {
            AppErrorHandler.handleError(context, viewModel.lastError!);
          }
        },
        label: const Text('Absenden'),
        icon: const Icon(Icons.send),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, SubmissionStatus status) {
     
    String message = 'Störungsmeldung erfolgreich verarbeitet.';
    if (status == SubmissionStatus.queuedOffline) {
      message = 'Ihre Störungsmeldung wurde gespeichert und wird automatisch gesendet, sobald eine Internetverbindung verfügbar ist.';
    } else if (status == SubmissionStatus.sentSuccess) {
      message = 'Ihre Störungsmeldung wurde erfolgreich übermittelt. Wir werden uns in Kürze bei Ihnen melden.';
      
      // Formular zurücksetzen nach erfolgreichem Senden
      ProviderScope.containerOf(context).read(troubleReportViewModelProvider).reset();
    }
     
    // Zeige passende Nachricht an
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: status == SubmissionStatus.queuedOffline ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}