import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import '../common/widgets/trouble_report_form.dart';
import '../../domain/entities/trouble_report.dart';
import '../../domain/enums/request_type.dart';
import '../../domain/enums/urgency_level.dart';
import '../../core/logging/app_logger.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';

class TroubleReportFormIOS extends ConsumerStatefulWidget {
  final Function(TroubleReport) onSubmit;

  const TroubleReportFormIOS({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  ConsumerState<TroubleReportFormIOS> createState() => _TroubleReportFormIOSState();
}

class _TroubleReportFormIOSState extends ConsumerState<TroubleReportFormIOS> with TroubleReportFormResetMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deviceModelController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _errorCodeController = TextEditingController();
  final _serviceHistoryController = TextEditingController();
  final _customerNumberController = TextEditingController();

  late TroubleReportViewModel _viewModel;
  bool _isLoading = false;
  DateTime? _selectedDate;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Logger für diese Klasse
  final _log = AppLogger.getLogger('TroubleReportFormIOS');
  
  // Add timer variable
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _log.info('TroubleReportFormIOS initialisiert');
    _viewModel = ref.read(troubleReportViewModelProvider);
    
    // Aktualisiere das ViewModel mit leeren Standardwerten, falls keine Werte vorhanden sind
    _viewModel.setType(_viewModel.type);
    _viewModel.setUrgencyLevel(_viewModel.urgencyLevel);
    
    // Versuche, gespeicherten Formularstatus zu laden
    _viewModel.loadFormState().then((hasState) {
      if (hasState) {
        _updateControllersFromViewModel();
        // UI aktualisieren nach dem Laden der Daten
        if (mounted) setState(() {});
      }
    });
    
    // Setze einen Timer, um regelmäßig den Formularstatus zu speichern
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _viewModel.saveFormState();
        _log.info('Formularstatus automatisch gespeichert');
      }
    });
  }

  void _updateControllersFromViewModel() {
    _nameController.text = _viewModel.name ?? '';
    _emailController.text = _viewModel.email ?? '';
    _phoneController.text = _viewModel.phone ?? '';
    _addressController.text = _viewModel.address ?? '';
    _descriptionController.text = _viewModel.description ?? '';
    _deviceModelController.text = _viewModel.deviceModel ?? '';
    _manufacturerController.text = _viewModel.manufacturer ?? '';
    _serialNumberController.text = _viewModel.serialNumber ?? '';
    _errorCodeController.text = _viewModel.errorCode ?? '';
    _serviceHistoryController.text = _viewModel.serviceHistory ?? '';
    _customerNumberController.text = _viewModel.customerNumber ?? '';
    _selectedDate = _viewModel.occurrenceDate;

    // Listener für Controller-Änderungen
    _nameController.addListener(() => _viewModel.setName(_nameController.text));
    _emailController.addListener(() => _viewModel.setEmail(_emailController.text));
    _phoneController.addListener(() => _viewModel.setPhone(_phoneController.text));
    _addressController.addListener(() => _viewModel.setAddress(_addressController.text));
    _descriptionController.addListener(() => _viewModel.setDescription(_descriptionController.text));
    _deviceModelController.addListener(() => _viewModel.setDeviceModel(_deviceModelController.text));
    _manufacturerController.addListener(() => _viewModel.setManufacturer(_manufacturerController.text));
    _serialNumberController.addListener(() => _viewModel.setSerialNumber(_serialNumberController.text));
    _errorCodeController.addListener(() => _viewModel.setErrorCode(_errorCodeController.text));
    _serviceHistoryController.addListener(() => _viewModel.setServiceHistory(_serviceHistoryController.text));
    _customerNumberController.addListener(() => _viewModel.setCustomerNumber(_customerNumberController.text));
  }

  @override
  void dispose() {
    _log.info('TroubleReportFormIOS wird entfernt');
    
    // Timer abbrechen, um Memory Leaks zu vermeiden
    _autoSaveTimer?.cancel();
    
    // Controller freigeben
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _deviceModelController.dispose();
    _manufacturerController.dispose();
    _serialNumberController.dispose();
    _errorCodeController.dispose();
    _serviceHistoryController.dispose();
    _customerNumberController.dispose();
    
    super.dispose();
  }

  @override
  void reset() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _descriptionController.clear();
    _deviceModelController.clear();
    _manufacturerController.clear();
    _serialNumberController.clear();
    _errorCodeController.clear();
    _serviceHistoryController.clear();
    _customerNumberController.clear();
    _selectedDate = null;
    
    _viewModel.reset();
    _viewModel.clearSavedFormState();
    _log.info('Formular zurückgesetzt und gespeicherte Daten gelöscht');
  }

  /// Zeigt die Optionen zur Bildauswahl an
  void _showImagePickerOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Foto hinzufügen'),
        message: const Text('Wählen Sie eine Option'),
        actions: [
          Semantics(
            label: 'Mit Kamera fotografieren',
            hint: 'Öffnet die Kamera, um ein Foto aufzunehmen',
            button: true,
            child: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Text('Kamera verwenden'),
            ),
          ),
          Semantics(
            label: 'Aus Galerie auswählen',
            hint: 'Öffnet die Bildergalerie zur Fotoauswahl',
            button: true,
            child: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Aus Galerie auswählen'),
            ),
          ),
        ],
        cancelButton: Semantics(
          label: 'Abbrechen',
          hint: 'Schließt dieses Menü ohne Auswahl',
          button: true,
          child: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ),
      ),
    );
  }

  /// Wählt ein Bild aus der Kamera oder Galerie aus
  Future<void> _pickImage(ImageSource source) async {
    // Ein iOS-konformes Loading-Overlay anzeigen
    _showLoadingOverlay(
      source == ImageSource.camera 
          ? 'Kamera wird geöffnet...' 
          : 'Galerie wird geöffnet...'
    );
    
    try {
      // Anfrage der entsprechenden Berechtigung
      final permission = source == ImageSource.camera 
          ? Permission.camera 
          : Permission.photos;
      
      // Prüfe aktuellen Status
      final permissionStatus = await permission.status;
      
      // Wenn Berechtigung nicht gewährt, anfragen
      if (!permissionStatus.isGranted) {
        final result = await permission.request();
        
        // Wenn Berechtigung verweigert, Dialog anzeigen und abbrechen
        if (!result.isGranted) {
          if (mounted) {
            // Loading-Overlay schließen
            Navigator.of(context).pop();
            _showPermissionDeniedDialog(source);
          }
          return;
        }
      }
      
      // Bild auswählen
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      // Loading-Overlay schließen
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Wenn keine Datei ausgewählt wurde, abbrechen
      if (pickedFile == null) {
        return;
      }
      
      // Neues Loading-Overlay für die Bildverarbeitung anzeigen
      if (mounted) {
        setState(() => _isLoading = true);
        
        // Datei zum ViewModel hinzufügen
        final file = File(pickedFile.path);
        _viewModel.addImagePath(file.path);
      }
      
    } catch (e) {
      // Fehlerbehandlung
      String errorMessage = 'Fehler beim Auswählen des Bildes';
      
      if (e is PlatformException) {
        switch (e.code) {
          case 'camera_access_denied':
          case 'photo_access_denied':
          case 'permission_denied':
            errorMessage = 'Zugriff verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
            break;
          default:
            errorMessage = 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';
        }
      }
      
      // Loading-Overlay schließen
      if (mounted) {
        // Sicherstellen, dass das Overlay nicht zweimal geschlossen wird
        try {
          Navigator.of(context).pop();
        } catch (_) {}
        
        _showErrorDialog(errorMessage);
      }
      
    } finally {
      // Loading-Status zurücksetzen
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Zeigt ein iOS-konformes Loading-Overlay an
  void _showLoadingOverlay(String message) {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          color: CupertinoColors.systemBackground.withAlpha(127),
          child: Center(
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey4.withAlpha(76),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(radius: 15),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Zeigt einen Dialog an, wenn Berechtigungen fehlen
  void _showPermissionDeniedDialog(ImageSource source) {
    const String title = 'Berechtigung erforderlich';
    final String message = source == ImageSource.camera
        ? 'Um ein Foto aufzunehmen, benötigt die App Zugriff auf Ihre Kamera.'
        : 'Um ein Bild auszuwählen, benötigt die App Zugriff auf Ihre Fotos.';
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Abbrechen'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Einstellungen'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  /// Zeigt eine einfache Fehlermeldung an
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hinweis'),
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

  void _showDatePicker() {
    // SystemUI-Farbe für iOS-Look
    final backgroundColor = CupertinoTheme.of(context).scaffoldBackgroundColor;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    
    showCupertinoModalPopup<void>(
      context: context,
      // Volle Animation für iOS-Design
      barrierDismissible: true,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Hintergrund-Blur
      semanticsDismissible: true,
      builder: (BuildContext context) {
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          // Verwendet SafeArea um Notches und andere Einschnitte zu respektieren
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // iOS-übliche Titelleiste mit Griff
                Container(
                  height: 6,
                  width: 40,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                // Titel und Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        'Datum wählen',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: textColor,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Fertig',
                          style: TextStyle(
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Trennlinie
                Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                
                // Date Picker
                Expanded(
                  child: CupertinoDatePicker(
                    backgroundColor: backgroundColor,
                    initialDateTime: _selectedDate ?? DateTime.now(),
                    maximumDate: DateTime.now(),
                    minimumDate: DateTime(2000),
                    mode: CupertinoDatePickerMode.date,
                    use24hFormat: true, // Für deutsche Konvention
                    dateOrder: DatePickerDateOrder.dmy, // Europäisches Format
                    onDateTimeChanged: (DateTime newDateTime) {
                      setState(() {
                        _selectedDate = newDateTime;
                        // Sofort ViewModel aktualisieren für reaktiveres Verhalten
                        _viewModel.setOccurrenceDate(newDateTime);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget? _buildImagePreview(BuildContext context, int index) {
    final viewModel = ref.read(troubleReportViewModelProvider);
    final bool isGridView = MediaQuery.of(context).size.width < 400;
    final double imageSize = isGridView ? 130 : 140;
    
    return Padding(
      padding: const EdgeInsets.only(
        right: 12,
        bottom: 4,
      ),
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey5.withAlpha(127),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bild
              Image.file(
                viewModel.images[index],
                fit: BoxFit.cover,
              ),
              
              // Abgedunkelter Overlay am oberen Rand für besseren Kontrast
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoColors.black.withAlpha(102),
                        CupertinoColors.black.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Lösch-Button
              Positioned(
                top: 8,
                right: 8,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => viewModel.removeImage(index),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withAlpha(25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 14,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bildindex-Anzeige
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withAlpha(153),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}/${viewModel.images.length}',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Wir lesen das ViewModel für den Build erneut, um reaktive Updates zu erhalten
    _viewModel = ref.watch(troubleReportViewModelProvider);
    
    final padding = _getResponsivePadding(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestTypeSection(),
          SizedBox(height: padding / 2),
          _buildPersonalDataSection(),
          SizedBox(height: padding / 2),
          _buildDeviceDataSection(),
          SizedBox(height: padding / 2),
          _buildDescriptionSection(),
          SizedBox(height: padding / 2),
          _buildUrgencySection(),
          SizedBox(height: padding / 2),
          _buildTermsSection(),
          // SizedBox(height: padding),
          // _buildSubmitButton(), // Submit-Button entfernt
        ],
      ),
    );
  }

  Widget _buildRequestTypeSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Art des Anliegens *'),
      footer: const Text('Wählen Sie die entsprechende Kategorie'),
      margin: _getResponsiveMargin(context),
      children: _buildRequestTypeOptions(),
    );
  }

  List<Widget> _buildRequestTypeOptions() {
    final viewModel = ref.watch(troubleReportViewModelProvider);
    List<Widget> options = [];
    
    // Eine Liste von Optionen für jeden RequestType erstellen
    for (var type in RequestType.values) {
      options.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GestureDetector(
            onTap: () {
              _log.info('Anfordererungstyp geändert auf: ${type.toString()}');
              debugPrint('Tippen auf Typ: ${type.toString()}');
              _viewModel.setType(type);
              setState(() {}); // UI explizit aktualisieren
            },
            behavior: HitTestBehavior.opaque, // Stellt sicher, dass der gesamte Bereich reagiert
            child: Container(
              decoration: BoxDecoration(
                color: viewModel.type == type 
                    ? CupertinoColors.activeBlue.withOpacity(0.1)
                    : CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: viewModel.type == type
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey4.resolveFrom(context),
                  width: viewModel.type == type ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: viewModel.type == type
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey6,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getIconForRequestType(type),
                          color: viewModel.type == type
                              ? CupertinoColors.white
                              : CupertinoColors.activeBlue,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: viewModel.type == type
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: viewModel.type == type
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getDescriptionForRequestType(type),
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      viewModel.type == type
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      color: viewModel.type == type
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey4,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Füge eine Beschreibung für den ausgewählten Typ hinzu
    options.add(
      Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.systemGrey4.resolveFrom(context),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.info_circle,
              color: CupertinoColors.activeBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bitte wählen Sie die Art Ihres Anliegens aus. Dies hilft uns, Ihre Anfrage richtig zu bearbeiten.',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    return options;
  }

  // Hilfsmethode, um das passende Icon für jeden RequestType zu erhalten
  IconData _getIconForRequestType(RequestType type) {
    switch (type) {
      case RequestType.trouble:
        return CupertinoIcons.exclamationmark_triangle;
      case RequestType.maintenance:
        return CupertinoIcons.wrench;
      case RequestType.consultation:
        return CupertinoIcons.chat_bubble_2;
      case RequestType.installation:
        return CupertinoIcons.hammer;
      case RequestType.question:
        return CupertinoIcons.question_circle;
      case RequestType.other:
        return CupertinoIcons.ellipsis_circle;
    }
  }

  // Hilfsmethode, um eine Beschreibung für jeden RequestType zu erhalten
  String _getDescriptionForRequestType(RequestType type) {
    switch (type) {
      case RequestType.trouble:
        return 'Melden Sie ein Problem oder eine Störung an Ihrem Gerät.';
      case RequestType.maintenance:
        return 'Vereinbaren Sie einen Termin für die regelmäßige Wartung Ihres Geräts.';
      case RequestType.consultation:
        return 'Beratung zu Produkten, Lösungen oder technischen Fragen.';
      case RequestType.installation:
        return 'Informationen oder Hilfe bei der Installation Ihres Geräts.';
      case RequestType.question:
        return 'Allgemeine Fragen zu unseren Produkten und Dienstleistungen.';
      case RequestType.other:
        return 'Sonstige Anfragen, die nicht in die anderen Kategorien passen.';
    }
  }

  Widget _buildPersonalDataSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Persönliche Daten *'),
      footer: const Text('Bitte geben Sie Ihre Kontaktdaten an, damit wir Sie bei Rückfragen erreichen können.'),
      margin: _getResponsiveMargin(context),
      children: [
        _buildNameField(),
        _buildEmailField(),
        CupertinoFormRow(
          prefix: const Text('Telefon *'),
          child: CupertinoTextFormFieldRow(
            controller: _phoneController,
            placeholder: 'Telefonnummer eingeben',
            keyboardType: TextInputType.phone,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihre Telefonnummer ein';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Adresse'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            child: CupertinoTextFormFieldRow(
              controller: _addressController,
              placeholder: 'Adresse eingeben',
              maxLines: 3,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return CupertinoFormRow(
      prefix: const Text('Name *'),
      child: Semantics(
        label: 'Name Eingabefeld',
        hint: 'Geben Sie Ihren vollständigen Namen ein',
        child: CupertinoTextFormFieldRow(
          controller: _nameController,
          placeholder: 'Ihr vollständiger Name',
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie Ihren Namen ein';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return CupertinoFormRow(
      prefix: const Text('E-Mail *'),
      child: Semantics(
        label: 'E-Mail Eingabefeld',
        hint: 'Geben Sie Ihre E-Mail-Adresse ein',
        child: CupertinoTextFormFieldRow(
          controller: _emailController,
          placeholder: 'Ihre E-Mail-Adresse',
          keyboardType: TextInputType.emailAddress,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie Ihre E-Mail-Adresse ein';
            }
            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
              return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    );
  }

  Widget _buildDeviceDataSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Geräteinformationen'),
      footer: const Text('Geben Sie hier Informationen zum betroffenen Gerät an.'),
      margin: _getResponsiveMargin(context),
      children: [
        CupertinoFormRow(
          prefix: const Text('Gerätemodell'),
          child: CupertinoTextFormFieldRow(
            controller: _deviceModelController,
            placeholder: 'Modellbezeichnung',
            padding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Hersteller'),
          child: CupertinoTextFormFieldRow(
            controller: _manufacturerController,
            placeholder: 'Herstellername',
            padding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Seriennummer'),
          child: CupertinoTextFormFieldRow(
            controller: _serialNumberController,
            placeholder: 'Seriennummer',
            padding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Fehlercode'),
          child: CupertinoTextFormFieldRow(
            controller: _errorCodeController,
            placeholder: 'Falls vorhanden',
            padding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Servicehistorie'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 100),
            child: CupertinoTextFormFieldRow(
              controller: _serviceHistoryController,
              placeholder: 'Letzte Wartungen',
              maxLines: 4,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
          ),
        ),
        _buildDatePicker(context),
        _buildMaintenanceContractRow(context),
        // Kundennummer-Feld, das nur angezeigt wird, wenn ein Wartungsvertrag vorhanden ist
        Consumer(
          builder: (context, ref, _) {
            final viewModel = ref.watch(troubleReportViewModelProvider);
            if (!viewModel.hasMaintenanceContract) {
              return const SizedBox.shrink();
            }
            return CupertinoFormRow(
              prefix: const Text('Kundennummer *'),
              child: CupertinoTextFormFieldRow(
                controller: _customerNumberController,
                placeholder: 'Kundennummer eingeben',
                keyboardType: TextInputType.text,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                validator: (value) {
                  if (viewModel.hasMaintenanceContract && (value == null || value.isEmpty)) {
                    return 'Bitte geben Sie Ihre Kundennummer ein';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return CupertinoFormRow(
      prefix: const Text('Datum des Vorfalls'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _log.info('Datumsauswahl geöffnet');
          debugPrint('Tippen auf Datumsauswahl');
          _showDatePicker();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _selectedDate != null
                ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                : 'Datum wählen',
            style: TextStyle(
              color: _selectedDate != null
                  ? CupertinoColors.label.resolveFrom(context)
                  : CupertinoColors.placeholderText.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceContractRow(BuildContext context) {
    final viewModel = ref.watch(troubleReportViewModelProvider);
    return CupertinoFormRow(
      prefix: const Text('Wartungsvertrag vorhanden'),
      child: CupertinoSwitch(
        value: viewModel.hasMaintenanceContract,
        onChanged: (value) => _viewModel.setHasMaintenanceContract(value),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Beschreibung *'),
      footer: const Text('Beschreiben Sie das Problem so detailliert wie möglich.'),
      margin: _getResponsiveMargin(context),
      children: [
        CupertinoFormRow(
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            child: CupertinoTextFormFieldRow(
              controller: _descriptionController,
              placeholder: 'Problem beschreiben',
              maxLines: 6,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte beschreiben Sie das Problem';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
        ),
        CupertinoFormRow(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isLoading ? null : _showImagePickerOptions,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo_camera,
                    color: _isLoading ? CupertinoColors.systemGrey : CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _viewModel.images.isEmpty
                        ? 'Fotos hinzufügen'
                        : '${_viewModel.images.length} Foto${_viewModel.images.length == 1 ? '' : 's'} ausgewählt',
                    style: TextStyle(
                      color: _isLoading ? CupertinoColors.systemGrey : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Verbesserte iOS-konforme Ladeanzeige für Bildverarbeitung
        if (_isLoading)
          CupertinoFormRow(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  // iOS-typischer Ladeindikator
                  const CupertinoActivityIndicator(radius: 14),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo,
                        size: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Bild wird verarbeitet...',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bitte warten',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Verbesserte iOS-konforme Bildergalerie
        Consumer(
          builder: (context, ref, _) {
            final viewModel = ref.watch(troubleReportViewModelProvider);
            if (viewModel.images.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return CupertinoFormRow(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.photo_on_rectangle,
                              color: CupertinoColors.activeBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ausgewählte Bilder (${viewModel.images.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                          ],
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: _isLoading ? null : _showImagePickerOptions,
                          child: const Text(
                            'Mehr hinzufügen',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Verbesserte Bildvorschau-Galerie mit iOS-konformem Scrollverhalten
                  SizedBox(
                    height: 150,
                    child: CupertinoScrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: viewModel.images.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _buildImagePreview(context, index);
                        },
                        padding: const EdgeInsets.only(right: 12, bottom: 8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUrgencySection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Dringlichkeit'),
      footer: const Text('Wählen Sie die Dringlichkeit des Problems.'),
      margin: _getResponsiveMargin(context),
      children: _buildUrgencyLevelPicker(),
    );
  }

  List<Widget> _buildUrgencyLevelPicker() {
    final viewModel = ref.watch(troubleReportViewModelProvider);
    return [
      CupertinoFormRow(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: UrgencyLevel.values.map((level) {
              Color color;
              IconData icon;
              
              switch (level) {
                case UrgencyLevel.low:
                  color = CupertinoColors.systemGreen;
                  icon = CupertinoIcons.checkmark_circle;
                  break;
                case UrgencyLevel.medium:
                  color = CupertinoColors.systemOrange;
                  icon = CupertinoIcons.exclamationmark_circle;
                  break;
                case UrgencyLevel.high:
                  color = CupertinoColors.systemRed;
                  icon = CupertinoIcons.exclamationmark_triangle;
                  break;
                case UrgencyLevel.critical:
                  color = CupertinoColors.systemRed.darkColor;
                  icon = CupertinoIcons.flame;
                  break;
              }
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _log.info('Dringlichkeitsstufe geändert auf: ${level.toString()}');
                    debugPrint('Tippen auf Dringlichkeitsstufe: ${level.toString()}');
                    _viewModel.setUrgencyLevel(level);
                    setState(() {}); // UI explizit aktualisieren
                  },
                  behavior: HitTestBehavior.opaque, // Stellt sicher, dass der gesamte Bereich reagiert
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: viewModel.urgencyLevel == level
                          ? color.withAlpha(20)
                          : CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: viewModel.urgencyLevel == level
                            ? color
                            : CupertinoColors.systemGrey4.resolveFrom(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(icon, color: color, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          level.displayName,
                          style: TextStyle(
                            fontWeight: viewModel.urgencyLevel == level
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: viewModel.urgencyLevel == level
                                ? color
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      CupertinoFormRow(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getUrgencyColor().withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getUrgencyColor().withAlpha(30)),
          ),
          child: Text(
            viewModel.urgencyLevel.description,
            style: TextStyle(color: _getUrgencyColor()),
          ),
        ),
      ),
    ];
  }
  
  Color _getUrgencyColor() {
    final viewModel = ref.watch(troubleReportViewModelProvider);
    switch (viewModel.urgencyLevel) {
      case UrgencyLevel.low:
        return CupertinoColors.systemGreen;
      case UrgencyLevel.medium:
        return CupertinoColors.systemOrange;
      case UrgencyLevel.high:
        return CupertinoColors.systemRed;
      case UrgencyLevel.critical:
        return CupertinoColors.systemRed.darkColor;
    }
  }

  Widget _buildTermsSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text(
        'Nutzungsbedingungen',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
      footer: const Padding(
        padding: EdgeInsets.only(top: 4.0),
        child: Text(
          'Ihre Zustimmung ist erforderlich, um die Störungsmeldung einzureichen.',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel,
            height: 1.3,
          ),
        ),
      ),
      margin: _getResponsiveMargin(context),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      children: [
        _buildTermsAcceptanceRow(),
      ],
    );
  }

  Widget _buildTermsAcceptanceRow() {
    final viewModel = ref.watch(troubleReportViewModelProvider);
    // Ermittle, ob wir Fehler anzeigen sollen
    final bool showError = !viewModel.hasAcceptedTerms && viewModel.validationAttempted;
    
    // Link-Farbe für den AGB-Text
    const linkColor = CupertinoColors.activeBlue;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ein größeres Touch-Target für bessere Benutzererfahrung
          CupertinoButton(
            padding: EdgeInsets.zero,
            pressedOpacity: 0.7,
            onPressed: () => _viewModel.setHasAcceptedTerms(!viewModel.hasAcceptedTerms),
            child: Semantics(
              label: 'Allgemeine Geschäftsbedingungen akzeptieren',
              hint: 'Tippen Sie hier, um die Nutzungsbedingungen zu akzeptieren',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Besseres Checkbox-Design mit größerem Touch-Target
                  Container(
                    width: 30,
                    height: 44,
                    alignment: Alignment.center,
                    child: CupertinoCheckbox(
                      value: viewModel.hasAcceptedTerms,
                      onChanged: (value) {
                        if (value != null) {
                          _viewModel.setHasAcceptedTerms(value);
                        }
                      },
                      activeColor: CupertinoColors.activeBlue,
                      // fillColor als WidgetStateProperty anstelle von MaterialStateProperty verwenden
                      fillColor: WidgetStateProperty.resolveWith<Color>((states) => 
                        showError ? CupertinoColors.systemRed : CupertinoColors.systemGrey3
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.3,
                            color: showError 
                                ? CupertinoColors.systemRed
                                : CupertinoColors.label.resolveFrom(context),
                          ),
                          children: [
                            const TextSpan(
                              text: 'Ich akzeptiere die ',
                            ),
                            TextSpan(
                              text: 'Nutzungsbedingungen',
                              style: const TextStyle(
                                color: linkColor,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _showTermsAndConditions();
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Verbesserte Fehlermeldung mit besserem Styling
          if (showError)
            const Padding(
              padding: EdgeInsets.only(left: 30.0, top: 4.0, right: 16.0),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_circle,
                    size: 14,
                    color: CupertinoColors.systemRed,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Bitte stimmen Sie den Nutzungsbedingungen zu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Hilfsmethode für responsive Abstände
  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 8.0;
    if (width < 600) return 16.0;
    return 24.0;
  }

  // Hilfsmethode für responsive Ränder in CupertinoFormSection
  EdgeInsetsGeometry _getResponsiveMargin(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(
      horizontal: width < 600 ? 16.0 : 24.0,
      vertical: 8.0
    );
  }

  void _showTermsAndConditions() {
    showCupertinoModalPopup(
      context: context,
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            'Nutzungsbedingungen',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          message: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: const CupertinoScrollbar(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Die folgenden Nutzungsbedingungen regeln die Verwendung unseres Störungsmeldungsformulars. '
                  'Durch die Nutzung unserer Dienste erklären Sie sich mit diesen Bedingungen einverstanden.\n\n'
                  '1. Datenschutz und Vertraulichkeit\n'
                  'Wir behandeln Ihre persönlichen Daten mit größter Sorgfalt und Vertraulichkeit. Ihre Daten werden ausschließlich zum Zweck der Bearbeitung Ihrer Störungsmeldung verwendet.\n\n'
                  '2. Datenverarbeitung\n'
                  'Mit dem Absenden des Formulars stimmen Sie zu, dass wir Ihre angegebenen Daten zur Bearbeitung Ihrer Störungsmeldung verarbeiten dürfen.\n\n'
                  '3. Verantwortung\n'
                  'Sie versichern, dass alle von Ihnen gemachten Angaben wahrheitsgemäß und vollständig sind.\n\n'
                  '4. Bilder und Dateien\n'
                  'Falls Sie Bilder oder Dateien hochladen, stellen Sie sicher, dass diese keine urheberrechtlich geschützten Inhalte enthalten, es sei denn, Sie besitzen die entsprechenden Rechte.\n\n'
                  '5. Bearbeitung\n'
                  'Wir bemühen uns, Ihre Störungsmeldung zeitnah zu bearbeiten, können jedoch keine verbindlichen Bearbeitungszeiten garantieren.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: CupertinoColors.label,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                _viewModel.setHasAcceptedTerms(true);
              },
              child: const Text('Akzeptieren'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }
}