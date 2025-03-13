import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
              child: SizedBox(height: 100), // Erhöht für besseren Abstand
            ),
          ],
        ),
        
        // Submit-Button am unteren Rand mit verbessertem Design
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey4.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: _isSubmitting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoActivityIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Störungsmeldung wird gesendet...',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () => _validateAndSubmit(viewModel),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.paperplane, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Störungsmeldung absenden',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitReport(TroubleReport report, TroubleReportViewModel viewModel) async {
    if (_isSubmitting) return; // Verhindere doppelte Einreichungen
    
    setState(() => _isSubmitting = true);
    
    try {
      // Zeige Feedback während des Sendens
      _showSendingFeedback();
      
      // Sende den Bericht
      final success = await viewModel.submitReport();
      
      if (success && mounted) {
        _showSuccessMessage();
        viewModel.reset();
      } else if (mounted) {
        _showErrorMessage(viewModel.errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Zeigt Feedback während des Sendens an
  void _showSendingFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      _buildCupertinoStyleSnackBar(
        content: const Row(
          children: [
            CupertinoActivityIndicator(radius: 10),
            SizedBox(width: 10),
            Text('Störungsmeldung wird gesendet...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Erstellt einen SnackBar im Cupertino-Stil
  SnackBar _buildCupertinoStyleSnackBar({
    required Widget content,
    required Duration duration,
  }) {
    return SnackBar(
      content: content,
      duration: duration,
      backgroundColor: CupertinoColors.systemGrey6,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 0,
    );
  }

  /// Validiert das Formular und sendet den Bericht, wenn die Validierung erfolgreich ist
  void _validateAndSubmit(TroubleReportViewModel viewModel) {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      // Prüfe, ob die AGBs akzeptiert wurden
      if (!viewModel.hasAcceptedTerms) {
        _showTermsNotAcceptedError();
        return;
      }
      
      // Erstelle TroubleReport-Objekt
      final report = TroubleReport(
        type: viewModel.type,
        name: viewModel.name ?? '',
        email: viewModel.email ?? '',
        phone: viewModel.phone,
        address: viewModel.address,
        hasMaintenanceContract: viewModel.hasMaintenanceContract,
        customerNumber: viewModel.customerNumber,
        description: viewModel.description ?? '',
        deviceModel: viewModel.deviceModel,
        manufacturer: viewModel.manufacturer,
        serialNumber: viewModel.serialNumber,
        errorCode: viewModel.errorCode,
        energySources: viewModel.energySources,
        occurrenceDate: viewModel.occurrenceDate,
        serviceHistory: viewModel.serviceHistory,
        urgencyLevel: viewModel.urgencyLevel,
        imagesPaths: viewModel.imagesPaths,
        hasAcceptedTerms: viewModel.hasAcceptedTerms,
      );
      
      // Sende den Bericht
      _submitReport(report, viewModel);
    } else {
      _showValidationErrorDialog();
    }
  }

  void _showTermsNotAcceptedError() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('AGBs nicht akzeptiert'),
        content: const Text('Bitte akzeptieren Sie die Allgemeinen Geschäftsbedingungen, um fortzufahren.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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