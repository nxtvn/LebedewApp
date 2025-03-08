import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../viewmodels/trouble_report_viewmodel.dart';
import '../widgets/trouble_report_form.dart';
import '../../core/constants/app_constants.dart';

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

  Future<void> _handleSubmit(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final success = await _viewModel.submitReport();
        if (success && mounted) {
          if (Platform.isIOS) {
            await showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Serviceanfrage erfolgreich gesendet'),
                content: const Text(
                  'Vielen Dank für Ihre Anfrage. Wir haben Ihre Serviceanfrage erhalten und werden uns zeitnah mit Ihnen in Verbindung setzen.',
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _formKey.currentState?.reset();
                      _viewModel.reset();
                      if (_troubleReportFormKey.currentState != null) {
                        _troubleReportFormKey.currentState!.reset();
                      }
                      setState(() {
                        _isLoading = false;
                      });
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PopScope(
                canPop: false,
                child: AlertDialog(
                  title: const Text('Serviceanfrage erfolgreich gesendet'),
                  content: const Text(
                    'Vielen Dank für Ihre Anfrage. Wir haben Ihre Serviceanfrage erhalten und werden uns zeitnah mit Ihnen in Verbindung setzen.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _formKey.currentState?.reset();
                        _viewModel.reset();
                        if (_troubleReportFormKey.currentState != null) {
                          _troubleReportFormKey.currentState!.reset();
                        }
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            );
          }
        } else if (mounted) {
          if (Platform.isIOS) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Fehler'),
                content: const Text('Fehler beim Senden der Serviceanfrage. Bitte versuchen Sie es später erneut.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Fehler beim Senden der Serviceanfrage. Bitte versuchen Sie es später erneut.'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
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
    final isIOS = Platform.isIOS;
    final colorScheme = Theme.of(context).colorScheme;

    /// Zeigt ein plattformspezifisches Lade-Overlay an
    Widget loadingOverlay() {
      if (Platform.isIOS) {
        // Cupertino Lade-Overlay für iOS
        return Container(
          color: CupertinoColors.white.withOpacity(0.7),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(radius: 16),
                  const SizedBox(height: 16),
                  const Text(
                    'Serviceanfrage wird gesendet...',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return Container(
          color: Colors.black26,
          child: Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text('Serviceanfrage wird gesendet...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.white,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.white,
          middle: const Text(
            'Serviceanfrage',
            style: TextStyle(
              color: CupertinoColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text(
              'Senden',
              style: TextStyle(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => _handleSubmit(context),
          ),
          border: const Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey5,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              TroubleReportForm(
                formKey: _formKey,
                onSubmit: () => _handleSubmit(context),
                showSubmitButton: false,
              ),
              if (viewModel.isLoading)
                Container(
                  color: CupertinoColors.white.withOpacity(0.7),
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Serviceanfrage'),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
        body: Stack(
          children: [
            TroubleReportForm(
              key: _troubleReportFormKey,
              formKey: _formKey,
              onSubmit: () => _handleSubmit(context),
            ),
            if (viewModel.isLoading) loadingOverlay(),
          ],
        ),
      );
    }
  }
} 