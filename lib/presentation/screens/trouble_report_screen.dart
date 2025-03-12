// Rename file to trouble_report_screen_android.dart
// Move file to lib/src/presentation/android/trouble_report_screen_android.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../presentation/viewmodels/trouble_report_viewmodel.dart';
import '../presentation/widgets/trouble_report_form.dart';
import '../core/constants/app_constants.dart';

class TroubleReportScreen extends StatelessWidget {
  const TroubleReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TroubleReportViewModel>(
      create: (context) => GetIt.I<TroubleReportViewModel>(),
      child: const TroubleReportView(),
    );
  }
}

class TroubleReportView extends StatefulWidget {
  const TroubleReportView({super.key});

  @override
  State<TroubleReportView> createState() => _TroubleReportViewState();
}

class _TroubleReportViewState extends State<TroubleReportView> {
  final _formKey = GlobalKey<FormState>();
  final _troubleReportFormKey = GlobalKey<TroubleReportFormState>();
  late TroubleReportViewModel _viewModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<TroubleReportViewModel>();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final success = await _viewModel.submitReport();
        if (success && mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Störungsmeldung erfolgreich gesendet'),
                content: const Text(
                  'Vielen Dank für Ihre Meldung. Wir haben Ihre Störungsmeldung erhalten und werden uns zeitnah mit Ihnen in Verbindung setzen.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _formKey.currentState?.reset();
                      _viewModel.reset();
                      _troubleReportFormKey.currentState?.reset();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fehler beim Senden der Störungsmeldung. Bitte versuchen Sie es später erneut.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TroubleReportViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Störungsmeldung')),
      body: Stack(
        children: [
          TroubleReportForm(
            key: _troubleReportFormKey,
            formKey: _formKey,
          ),
          if (viewModel.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Störungsmeldung wird gesendet...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: AppConstants.defaultPadding,
          right: AppConstants.defaultPadding,
          top: AppConstants.defaultPadding,
          bottom: MediaQuery.of(context).padding.bottom + AppConstants.defaultPadding,
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.send),
          label: const Text(
            'Absenden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _isLoading ? null : _handleSubmit,
        ),
      ),
    );
  }
} 