import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../presentation/common/viewmodels/trouble_report_viewmodel.dart';
import '../../presentation/common/widgets/trouble_report_form.dart';

class TroubleReportScreenAndroid extends StatelessWidget {
  const TroubleReportScreenAndroid({Key? key}) : super(key: key);

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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Störungsmeldung'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewModel.hasError
                ? _buildErrorView(viewModel.errorMessage)
                : const SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: TroubleReportForm(),
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
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Ein Fehler ist aufgetreten',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
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