import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import 'trouble_report_form_ios.dart';
import '../../domain/entities/trouble_report.dart';

class TroubleReportScreenIOS extends StatelessWidget {
  const TroubleReportScreenIOS({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TroubleReportViewModel>(
      create: (context) => GetIt.I<TroubleReportViewModel>(),
      child: const _TroubleReportView(),
    );
  }
}

class _TroubleReportView extends StatefulWidget {
  const _TroubleReportView();

  @override
  State<_TroubleReportView> createState() => _TroubleReportViewState();
}

class _TroubleReportViewState extends State<_TroubleReportView> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Störungsmeldung'),
        previousPageTitle: 'Zurück',
      ),
      child: SafeArea(
        bottom: true,
        child: Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return _buildLoadingView();
            } else if (viewModel.hasError) {
              return _buildErrorView(viewModel.errorMessage);
            } else {
              return _buildFormView(viewModel);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 20),
          const SizedBox(height: 16),
          Text(
            'Wird geladen...',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(TroubleReportViewModel viewModel) {
    return Stack(
      children: [
        // Scrollbarer Bereich für das Formular
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TroubleReportFormIOS(
                  formKey: _formKey,
                  onSubmit: (report) => _submitReport(report, viewModel),
                ),
              ),
            ),
            // Zusätzlicher Platz am Ende, damit der Submit-Button nicht überlappt
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
        
        // Submit-Button am unteren Rand
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: _isSubmitting
                ? const Center(child: CupertinoActivityIndicator())
                : CupertinoButton.filled(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        // Der eigentliche Submit wird in der onSubmit-Funktion des Formulars durchgeführt
                        _formKey.currentState?.validate();
                      } else {
                        _showValidationErrorDialog();
                      }
                    },
                    child: const Text('Störungsmeldung absenden'),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitReport(TroubleReport report, TroubleReportViewModel viewModel) async {
    setState(() => _isSubmitting = true);
    
    try {
      final success = await viewModel.submitReport();
      
      if (success && mounted) {
        _showSuccessMessage();
        viewModel.reset();
      } else if (mounted) {
        _showErrorMessage(viewModel.errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showValidationErrorDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eingabefehler'),
        content: const Text('Bitte füllen Sie alle erforderlichen Felder korrekt aus.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Erfolg'),
        message: const Text('Ihre Störungsmeldung wurde erfolgreich übermittelt. Wir werden uns in Kürze bei Ihnen melden.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String errorMessage) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Fehler'),
        content: Text('Bei der Übermittlung ist ein Fehler aufgetreten: $errorMessage'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.destructiveRed,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Ein Fehler ist aufgetreten',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: CupertinoTheme.of(context).textTheme.textStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                Provider.of<TroubleReportViewModel>(context, listen: false).reset();
              },
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}