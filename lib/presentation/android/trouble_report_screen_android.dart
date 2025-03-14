import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import 'trouble_report_form_android.dart';
import '../../core/utils/error_handler.dart';
import '../../data/repositories/trouble_report_repository_impl.dart';
import '../../domain/services/email_service.dart';
import '../../domain/services/image_storage_service.dart';

class TroubleReportScreenAndroid extends StatelessWidget {
  const TroubleReportScreenAndroid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Da wir die Services direkt injizieren müssen, holen wir sie aus dem GetIt Container
    final emailService = GetIt.instance<EmailService>();
    final imageStorageService = GetIt.instance<ImageStorageService>();
    
    return ChangeNotifierProvider(
      create: (_) => TroubleReportViewModel(
        // Repository direkt mit den nötigen Services erstellen
        TroubleReportRepositoryImpl(emailService, imageStorageService)
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Störungsmeldung'),
        ),
        body: Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (viewModel.lastError != null) {
              return AppErrorHandler.buildErrorWidget(
                context, 
                viewModel.lastError!,
                onRetry: () => viewModel.clearLastError(),
              );
            }
            
            // Wir benötigen einen FormKey für TroubleReportFormAndroid
            final formKey = GlobalKey<FormState>();
            
            return TroubleReportFormAndroid(
              formKey: formKey,
              onSubmit: (report) async {
                final success = await viewModel.submitReport();
                if (success && context.mounted) {
                  _showSuccessMessage(context, viewModel.lastSubmissionStatus);
                }
              },
            );
          },
        ),
        floatingActionButton: Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading || viewModel.lastError != null) {
              return const SizedBox.shrink();
            }
            
            return FloatingActionButton.extended(
              onPressed: () async {
                // Wir können keine Validierung in der FloatingActionButton vornehmen
                // da der FormKey im anderen Widget existiert
                final success = await viewModel.submitReport();
                
                if (success && context.mounted) {
                  _showSuccessMessage(context, viewModel.lastSubmissionStatus);
                } else if (!success && context.mounted && viewModel.lastError != null) {
                  AppErrorHandler.handleError(context, viewModel.lastError!);
                }
              },
              label: const Text('Absenden'),
              icon: const Icon(Icons.send),
            );
          },
        ),
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
      final viewModel = Provider.of<TroubleReportViewModel>(context, listen: false);
      viewModel.reset();
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