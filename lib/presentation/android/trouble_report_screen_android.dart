import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import '../common/widgets/trouble_report_form.dart';

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
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Störungsmeldung'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (viewModel.hasError) {
              return _buildErrorView(viewModel.errorMessage);
            } else {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: TroubleReportForm(formKey: _formKey),
              );
            }
          },
        ),
      ),
      floatingActionButton: Consumer<TroubleReportViewModel>(
        builder: (context, viewModel, child) {
          return FloatingActionButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final success = await viewModel.submitReport();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Störungsmeldung erfolgreich gesendet'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  viewModel.reset();
                }
              }
            },
            child: const Icon(Icons.send),
          );
        },
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