import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'trouble_report_form_android.dart';
import '../../domain/entities/trouble_report.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';

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
  late TroubleReportViewModel _viewModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<TroubleReportViewModel>();
  }

  Future<void> _handleSubmit(TroubleReport troubleReport) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final success = await _viewModel.submitReport(troubleReport);
        if (success && mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
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
                  },
                  child: const Text('OK'),
                ),
              ],
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
          TroubleReportFormAndroid(
            formKey: _formKey,
            onSubmit: _handleSubmit,
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
    );
  }
}