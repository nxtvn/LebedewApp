import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import '../common/widgets/trouble_report_form_ios.dart';

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

  @override
  Widget build(BuildContext context) {
    // Verwende Consumer für effizienteres Rebuilding
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Störungsmeldung'),
      ),
      child: SafeArea(
        child: Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            } else if (viewModel.hasError) {
              return _buildErrorView(viewModel.errorMessage);
            } else {
              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: TroubleReportFormIOS(formKey: _formKey),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.all(16),
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          final success = await viewModel.submitReport();
                          if (success && mounted) {
                            _showSuccessMessage(context);
                            viewModel.reset();
                          }
                        }
                      },
                      child: const Icon(CupertinoIcons.paperplane),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erfolg'),
        content: const Text('Störungsmeldung erfolgreich gesendet'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.destructiveRed,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ein Fehler ist aufgetreten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 16),
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