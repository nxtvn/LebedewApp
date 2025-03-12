import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../presentation/common/viewmodels/trouble_report_viewmodel.dart';
import '../../presentation/common/widgets/trouble_report_form_ios.dart';

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
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<TroubleReportViewModel>(context);
    
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Störungsmeldung'),
      ),
      child: SafeArea(
        child: viewModel.isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : viewModel.hasError
                ? _buildErrorView(viewModel.errorMessage)
                : const SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: TroubleReportFormIOS(),
                  ),
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