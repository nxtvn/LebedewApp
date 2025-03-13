import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import 'trouble_report_form_ios.dart';
import '../../domain/entities/trouble_report.dart';
import '../../core/utils/error_handler.dart';
import '../../data/repositories/trouble_report_repository_impl.dart';
import '../../domain/services/email_service.dart';
import '../../domain/services/image_storage_service.dart';
import '../../core/network/network_info_facade.dart';
import 'dart:async';
import 'dart:ui' show ImageFilter;

class TroubleReportScreenIOS extends StatelessWidget {
  const TroubleReportScreenIOS({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Services aus dem GetIt Container holen
    final emailService = GetIt.instance<EmailService>();
    final imageStorageService = GetIt.instance<ImageStorageService>();
    
    return ChangeNotifierProvider<TroubleReportViewModel>(
      create: (context) => TroubleReportViewModel(
        TroubleReportRepositoryImpl(emailService, imageStorageService)
      ),
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isOffline = false;
  late NetworkInfoFacade _networkInfo;
  StreamSubscription? _networkStatusSubscription;

  @override
  void initState() {
    super.initState();
    _networkInfo = GetIt.instance<NetworkInfoFacade>();
    _checkConnectionStatus();
    _setupNetworkListener();
  }

  @override
  void dispose() {
    _networkStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectionStatus() async {
    final isConnected = await _networkInfo.isCurrentlyConnected;
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  void _setupNetworkListener() {
    _networkStatusSubscription = _networkInfo.isConnected.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TroubleReportViewModel>(
      builder: (context, viewModel, child) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Störungsmeldung'),
          ),
          child: SafeArea(
            child: _buildContent(viewModel),
          ),
        );
      },
    );
  }

  Widget _buildContent(TroubleReportViewModel viewModel) {
    if (viewModel.isLoading) {
      return _buildLoadingView();
    }
    
    if (viewModel.lastError != null) {
      return AppErrorHandler.buildErrorWidget(
        context, 
        viewModel.lastError!,
        onRetry: () => viewModel.clearLastError(),
      );
    }
    
    return _buildFormView(viewModel);
  }

  /// Verbesserte iOS-konforme Ladeanzeige für die Hauptansicht
  Widget _buildLoadingView() {
    return Container(
      color: CupertinoColors.systemBackground,
      child: Center(
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey4.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 16),
              const SizedBox(height: 16),
              Text(
                'Wird geladen...',
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bitte warten',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(TroubleReportViewModel viewModel) {
    // Anzeige des Submit-Buttons basierend auf Netzwerkstatus und Absendestatus
    Widget buildSubmitButton() {
      if (_isSubmitting) {
        return const Center(
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
        );
      }

      // Offline-Zustand: Anderes Design für den Button
      if (_isOffline) {
        return Column(
          children: [
            // Netzwerkstatus-Indikator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.systemOrange.withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.wifi_slash,
                    color: CupertinoColors.systemOrange,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Offline-Modus',
                    style: TextStyle(
                      color: CupertinoColors.systemOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Offline-Button-Stil
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: CupertinoColors.systemGrey,
              onPressed: () => _validateAndSubmit(viewModel),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.tray_arrow_down, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Störungsmeldung für später speichern',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // Online Standard-Button
      return CupertinoButton.filled(
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
      );
    }

    return Stack(
      children: [
        // Scrollbarer Bereich für das Formular
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Offline-Status-Banner (nur anzeigen, wenn offline)
            if (_isOffline)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CupertinoColors.systemYellow.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.wifi_slash,
                        color: CupertinoColors.systemYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sie sind offline. Ihre Störungsmeldung wird gespeichert und automatisch gesendet, sobald eine Verbindung verfügbar ist.',
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: _checkConnectionStatus,
                        child: const Icon(
                          CupertinoIcons.refresh,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Formular-Inhalt
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
              child: SizedBox(height: 100),
            ),
          ],
        ),
        
        // Submit-Button am unteren Rand mit verbessertem Design
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Netzwerk-Status-Indikator für den unteren Bereich
              if (_isOffline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minSize: 0,
                    onPressed: _checkConnectionStatus,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.refresh,
                          color: CupertinoColors.activeBlue,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Erneut verbinden',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Button-Container
              Container(
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
                  child: buildSubmitButton(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitReport(TroubleReport report, TroubleReportViewModel viewModel) async {
    if (_isSubmitting) return; // Verhindere doppelte Einreichungen
    
    // Setze lokalen Loading-Zustand
    setState(() => _isSubmitting = true);
    
    // Zeige ein iOS-konformes Loading-Overlay an
    _showSubmissionOverlay();
    
    try {
      // Sende den Bericht
      final success = await viewModel.submitReport();
      
      // Schließe das Loading-Overlay
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (success && mounted) {
        _showSuccessMessage();
        viewModel.reset();
      } else if (mounted) {
        _showErrorMessage(viewModel.errorMessage);
      }
    } catch (e) {
      // Schließe das Loading-Overlay im Fehlerfall
      if (mounted) {
        Navigator.pop(context);
        _showErrorMessage('Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Zeigt ein iOS-konformes Loading-Overlay für die Formularübermittlung an
  void _showSubmissionOverlay() {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          color: CupertinoColors.systemBackground.withOpacity(0.6),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Center(
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ladeindikator im iOS-Stil
                    const CupertinoActivityIndicator(radius: 18),
                    const SizedBox(height: 20),
                    // Hauptnachricht
                    const Text(
                      'Störungsmeldung wird gesendet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Detailnachricht
                    Text(
                      'Bitte warten Sie, während die Daten übermittelt werden.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontSize: 14,
                      ),
                    ),
                    // Fortschrittsanzeige
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          Container(
                            height: 6,
                            width: 200,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5.resolveFrom(context),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.activeBlue,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.arrow_up_circle,
                                size: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Daten werden übertragen...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Validiert das Formular und sendet den Bericht, wenn die Validierung erfolgreich ist
  void _validateAndSubmit(TroubleReportViewModel viewModel) {
    // Markiere, dass ein Validierungsversuch stattgefunden hat
    viewModel.setValidationAttempted(true);
    
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      // Prüfe, ob die AGBs akzeptiert wurden
      if (!viewModel.hasAcceptedTerms) {
        // Keine Dialog-Anzeige mehr, stattdessen wird die Validierung direkt im UI angezeigt
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
    }
    // Keine Fehler-Dialog-Anzeige mehr, Validierungsfehler werden direkt in der UI angezeigt
  }

  void _showSuccessMessage() {
    final status = Provider.of<TroubleReportViewModel>(context, listen: false).lastSubmissionStatus;
    
    String title = 'Erfolg';
    String message = 'Störungsmeldung erfolgreich verarbeitet.';
    
    if (status == SubmissionStatus.queuedOffline) {
      title = 'Offline gespeichert';
      message = 'Ihre Störungsmeldung wurde gespeichert und wird automatisch gesendet, sobald eine Internetverbindung verfügbar ist.';
    } else if (status == SubmissionStatus.sentSuccess) {
      title = 'Erfolgreich gesendet';
      message = 'Ihre Störungsmeldung wurde erfolgreich übermittelt. Wir werden uns in Kürze bei Ihnen melden.';
    }
    
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
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
}