import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'trouble_report_form_ios.dart';
import '../../domain/entities/trouble_report.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';

class TroubleReportScreenIOS extends StatelessWidget {
  const TroubleReportScreenIOS({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TroubleReportViewModel>(
      create: (context) => GetIt.I<TroubleReportViewModel>(),
      child: const TroubleReportViewIOS(),
    );
  }
}

class TroubleReportViewIOS extends StatefulWidget {
  const TroubleReportViewIOS({super.key});

  @override
  State<TroubleReportViewIOS> createState() => _TroubleReportViewIOSState();
}

class _TroubleReportViewIOSState extends State<TroubleReportViewIOS> {
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
          await showCupertinoDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Störungsmeldung erfolgreich gesendet'),
              content: const Text(
                'Vielen Dank für Ihre Meldung. Wir haben Ihre Störungsmeldung erhalten und werden uns zeitnah mit Ihnen in Verbindung setzen.',
              ),
              actions: [
                CupertinoDialogAction(
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
          await showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Fehler'),
              content: const Text('Fehler beim Senden der Störungsmeldung. Bitte versuchen Sie es später erneut.'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
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

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Störungsmeldung'),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            TroubleReportFormIOS(
              formKey: _formKey,
              onSubmit: _handleSubmit,
            ),
            if (viewModel.isLoading)
              Container(
                color: CupertinoColors.black.withAlpha(51),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoActivityIndicator(),
                        SizedBox(height: 16),
                        Text('Störungsmeldung wird gesendet...'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}