import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

class TroubleReportFormIOS extends TroubleReportForm {
  const TroubleReportFormIOS({
    Key? key,
    required GlobalKey<FormState> formKey,
    required Function(TroubleReport) onSubmit,
  }) : super(key: key, formKey: formKey, onSubmit: onSubmit);

  @override
  State<TroubleReportFormIOS> createState() => _TroubleReportFormIOSState();
}

class _TroubleReportFormIOSState extends State<TroubleReportFormIOS> with TroubleReportFormResetMixin {
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
  
  // Zähler für Bildauswahl-Fehler
  int _imagePickErrorCount = 0;
  
  // Logger für diese Klasse
  final _log = AppLogger.getLogger('TroubleReportFormIOS');
  
  // Add timer variable
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _log.info('TroubleReportFormIOS initialisiert');
    _viewModel = Provider.of<TroubleReportViewModel>(context, listen: false);
    
    // Versuche, gespeicherten Formularstatus zu laden
    _viewModel.loadFormState().then((hasState) {
      _initControllers();
      _log.info('Formularstatus geladen: ${hasState ? 'erfolgreich' : 'kein gespeicherter Status'}');
    });
    
    // Setze einen Timer, um regelmäßig den Formularstatus zu speichern
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _viewModel.saveFormState();
        _log.info('Formularstatus automatisch gespeichert');
      }
    });
  }

  void _initControllers() {
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
    final uniqueId = AppLogger.generateUniqueId();
    final sourceStr = source == ImageSource.camera ? 'Kamera' : 'Galerie';
    
    AppLogger.logImagePickerWorkflow(
      _log,
      step: 'Start',
      source: sourceStr,
      uniqueId: uniqueId
    );
    
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Prüfe Berechtigungen
      bool permissionGranted = false;
      
      if (source == ImageSource.camera) {
        AppLogger.logImagePickerWorkflow(
          _log,
          step: 'Prüfe Kamera-Berechtigung',
          source: sourceStr,
          uniqueId: uniqueId
        );
        
        final status = await Permission.camera.status;
        
        AppLogger.logPermissionStatus(
          _log,
          permission: 'Kamera',
          status: status.toString()
        );
        
        if (status.isDenied) {
          final result = await Permission.camera.request();
          permissionGranted = result.isGranted;
          
          AppLogger.logPermissionStatus(
            _log,
            permission: 'Kamera',
            status: result.toString(),
            userResponse: result.isGranted ? 'Erlaubt' : 'Verweigert'
          );
        } else {
          permissionGranted = status.isGranted;
        }
      } else {
        AppLogger.logImagePickerWorkflow(
          _log,
          step: 'Prüfe Fotos-Berechtigung',
          source: sourceStr,
          uniqueId: uniqueId
        );
        
        final status = await Permission.photos.status;
        
        AppLogger.logPermissionStatus(
          _log,
          permission: 'Fotos',
          status: status.toString()
        );
        
        if (status.isDenied) {
          final result = await Permission.photos.request();
          permissionGranted = result.isGranted;
          
          AppLogger.logPermissionStatus(
            _log,
            permission: 'Fotos',
            status: result.toString(),
            userResponse: result.isGranted ? 'Erlaubt' : 'Verweigert'
          );
        } else {
          permissionGranted = status.isGranted;
        }
      }
      
      if (!permissionGranted) {
        AppLogger.logImagePickerWorkflow(
          _log,
          step: 'Berechtigung verweigert',
          source: sourceStr,
          error: 'Benutzer hat Berechtigung verweigert',
          uniqueId: uniqueId
        );
        
        if (mounted) {
          _showPermissionDeniedDialog(source);
        }
        return;
      }
      
      // Wähle das Bild aus
      AppLogger.logImagePickerWorkflow(
        _log,
        step: 'Öffne Bildauswahl',
        source: sourceStr,
        uniqueId: uniqueId
      );
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        AppLogger.logImagePickerWorkflow(
          _log,
          step: 'Abgebrochen',
          source: sourceStr,
          uniqueId: uniqueId
        );
        return;
      }
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      
      AppLogger.logImagePickerWorkflow(
        _log,
        step: 'Bild ausgewählt',
        source: sourceStr,
        filePath: pickedFile.path,
        fileSize: fileSize,
        uniqueId: uniqueId
      );
      
      // Füge das Bild zum ViewModel hinzu
      _viewModel.addImagePath(file.path);
      
      AppLogger.logImagePickerWorkflow(
        _log,
        step: 'Bild hinzugefügt',
        source: sourceStr,
        uniqueId: uniqueId
      );
      
      // Setze den Fehlerzähler zurück
      _imagePickErrorCount = 0;
    } catch (e) {
      AppLogger.logImagePickerWorkflow(
        _log,
        step: 'Fehler',
        source: sourceStr,
        error: e.toString(),
        uniqueId: uniqueId
      );
      
      // Erhöhe den Fehlerzähler
      _imagePickErrorCount++;
      
      // Detaillierte Fehlerbehandlung
      String errorMessage = 'Fehler beim Auswählen des Bildes';
      
      if (e is PlatformException) {
        _log.warning('PlatformException: ${e.code} - ${e.message}');
        
        switch (e.code) {
          case 'camera_access_denied':
            errorMessage = 'Kamerazugriff verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
            break;
          case 'photo_access_denied':
            errorMessage = 'Zugriff auf Fotos verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
            break;
          case 'permission_denied':
            errorMessage = 'Berechtigung verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
            break;
          default:
            errorMessage = 'Fehler: ${e.message}';
        }
      }
      
      // Zeige Fehlermeldung an
      if (mounted) {
        _showErrorDialog(errorMessage);
      }
      
      // Fallback-Mechanismus: Biete alternative Methode an
      if (mounted && source == ImageSource.camera) {
        _offerAlternativeMethod();
      }
      
      // Wenn mehrere Fehler aufgetreten sind, zeige die manuelle Upload-Option an
      if (_imagePickErrorCount >= 2 && mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showManualUploadOption();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Zeigt einen Dialog an, wenn Berechtigungen fehlen
  void _showPermissionDeniedDialog(ImageSource source) {
    _log.warning('Zeige Dialog: Berechtigung verweigert für ${source == ImageSource.camera ? "Kamera" : "Galerie"}');
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Berechtigung erforderlich'),
        content: Text(
          source == ImageSource.camera
              ? 'Für die Verwendung der Kamera wird eine Berechtigung benötigt. Bitte erlauben Sie den Zugriff in den Einstellungen.'
              : 'Für den Zugriff auf Ihre Fotos wird eine Berechtigung benötigt. Bitte erlauben Sie den Zugriff in den Einstellungen.'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Abbrechen'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Einstellungen öffnen'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  /// Zeigt eine Fehlermeldung an
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Fehler'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Bietet eine alternative Methode an, wenn die Kamera nicht funktioniert
  void _offerAlternativeMethod() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Alternative Methode'),
        content: const Text('Möchten Sie stattdessen ein Bild aus der Galerie auswählen?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Nein'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Ja, Galerie öffnen'),
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  /// Fallback-Methode für Bildupload, wenn normale Methoden fehlschlagen
  void _showManualUploadOption() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Alternative Methode'),
        content: const Text(
          'Wenn Sie Probleme beim Hochladen von Bildern haben, können Sie uns die Bilder auch per E-Mail senden. '
          'Bitte geben Sie dabei Ihre Referenznummer an, die Sie nach dem Absenden der Störungsmeldung erhalten.'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Verstanden'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Abbrechen'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Bestätigen'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _viewModel.setOccurrenceDate(_selectedDate);
                    },
                  ),
                ],
              ),
              const Divider(height: 0),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: _selectedDate ?? DateTime.now(),
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(2000),
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() => _selectedDate = newDateTime);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildImagePreview(BuildContext context, int index) {
    final bool isGridView = MediaQuery.of(context).size.width < 400;
    
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(
            right: isGridView ? 0 : 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _viewModel.images[index],
              fit: BoxFit.cover,
              width: isGridView ? null : 120,
              height: 120,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: isGridView ? 4 : 12,
          child: GestureDetector(
            onTap: () => _viewModel.removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.clear_circled_solid,
                size: 16,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final padding = _getResponsivePadding(context);
    
    return Form(
      key: widget.formKey,
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
          SizedBox(height: padding),
          _buildSubmitButton(),
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
    final Map<RequestType, Widget> requestTypeSegments = <RequestType, Widget>{};
    
    for (var type in RequestType.values) {
      requestTypeSegments[type] = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForRequestType(type),
              color: _viewModel.type == type 
                  ? CupertinoColors.white 
                  : CupertinoColors.activeBlue,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 12,
                color: _viewModel.type == type 
                    ? CupertinoColors.white 
                    : CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      );
    }
    
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: CupertinoFormRow(
          child: CupertinoSegmentedControl<RequestType>(
            children: requestTypeSegments,
            groupValue: _viewModel.type,
            onValueChanged: (RequestType value) {
              _viewModel.setType(value);
            },
            padding: const EdgeInsets.all(4),
          ),
        ),
      ),
      CupertinoFormRow(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemGrey4.resolveFrom(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconForRequestType(_viewModel.type),
                    color: CupertinoColors.activeBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _viewModel.type.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getDescriptionForRequestType(_viewModel.type),
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
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
          child: CupertinoTextFormFieldRow(
            controller: _addressController,
            placeholder: 'Adresse eingeben',
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Semantics(
      label: 'Name Eingabefeld',
      hint: 'Geben Sie Ihren vollständigen Namen ein',
      child: CupertinoTextFormFieldRow(
        controller: _nameController,
        prefix: const Text('Name'),
        placeholder: 'Ihr vollständiger Name',
        padding: const EdgeInsets.symmetric(vertical: 12),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bitte geben Sie Ihren Namen ein';
          }
          return null;
        },
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Semantics(
      label: 'E-Mail Eingabefeld',
      hint: 'Geben Sie Ihre E-Mail-Adresse ein',
      child: CupertinoTextFormFieldRow(
        controller: _emailController,
        prefix: const Text('E-Mail'),
        placeholder: 'Ihre E-Mail-Adresse',
        padding: const EdgeInsets.symmetric(vertical: 12),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bitte geben Sie Ihre E-Mail-Adresse ein';
          }
          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
            return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
          }
          return null;
        },
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
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
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Hersteller'),
          child: CupertinoTextFormFieldRow(
            controller: _manufacturerController,
            placeholder: 'Herstellername',
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Seriennummer'),
          child: CupertinoTextFormFieldRow(
            controller: _serialNumberController,
            placeholder: 'Seriennummer',
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Fehlercode'),
          child: CupertinoTextFormFieldRow(
            controller: _errorCodeController,
            placeholder: 'Falls vorhanden',
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Servicehistorie'),
          child: CupertinoTextFormFieldRow(
            controller: _serviceHistoryController,
            placeholder: 'Letzte Wartungen',
            maxLines: 3,
          ),
        ),
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            return CupertinoFormRow(
              prefix: const Text('Datum des Vorfalls'),
              child: GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    viewModel.occurrenceDate != null
                        ? '${viewModel.occurrenceDate!.day}.${viewModel.occurrenceDate!.month}.${viewModel.occurrenceDate!.year}'
                        : 'Datum wählen',
                    style: TextStyle(
                      color: viewModel.occurrenceDate != null
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.placeholderText.resolveFrom(context),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            return CupertinoFormRow(
              prefix: const Text('Wartungsvertrag vorhanden'),
              child: CupertinoSwitch(
                value: viewModel.hasMaintenanceContract,
                onChanged: (value) => viewModel.setHasMaintenanceContract(value),
              ),
            );
          },
        ),
        // Kundennummer-Feld, das nur angezeigt wird, wenn ein Wartungsvertrag vorhanden ist
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            if (!viewModel.hasMaintenanceContract) {
              return const SizedBox.shrink();
            }
            return CupertinoFormRow(
              prefix: const Text('Kundennummer *'),
              child: CupertinoTextFormFieldRow(
                controller: _customerNumberController,
                placeholder: 'Kundennummer eingeben',
                keyboardType: TextInputType.text,
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

  Widget _buildDescriptionSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Beschreibung *'),
      footer: const Text('Beschreiben Sie das Problem so detailliert wie möglich.'),
      margin: _getResponsiveMargin(context),
      children: [
        CupertinoFormRow(
          child: CupertinoTextFormFieldRow(
            controller: _descriptionController,
            placeholder: 'Problem beschreiben',
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte beschreiben Sie das Problem';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        CupertinoFormRow(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isLoading ? null : _showImagePickerOptions,
              child: Consumer<TroubleReportViewModel>(
                builder: (context, viewModel, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo_camera,
                        color: _isLoading ? CupertinoColors.systemGrey : CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        viewModel.images.isEmpty
                            ? 'Fotos hinzufügen'
                            : '${viewModel.images.length} Foto${viewModel.images.length == 1 ? '' : 's'} ausgewählt',
                        style: TextStyle(
                          color: _isLoading ? CupertinoColors.systemGrey : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        if (_isLoading)
          const CupertinoFormRow(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Bild wird verarbeitet...',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.images.isEmpty) {
              return const SizedBox.shrink();
            }
            return CupertinoFormRow(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Ausgewählte Bilder:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: viewModel.images.length,
                      itemBuilder: _buildImagePreview,
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
                  icon = CupertinoIcons.info;
                  break;
                case UrgencyLevel.medium:
                  color = CupertinoColors.systemOrange;
                  icon = CupertinoIcons.exclamationmark_triangle;
                  break;
                case UrgencyLevel.high:
                  color = CupertinoColors.systemRed;
                  icon = CupertinoIcons.exclamationmark_circle;
                  break;
              }
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => _viewModel.setUrgencyLevel(level),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _viewModel.urgencyLevel == level
                          ? color.withAlpha(20)
                          : CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _viewModel.urgencyLevel == level
                            ? color
                            : CupertinoColors.systemGrey4.resolveFrom(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(icon, color: color, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          level.label,
                          style: TextStyle(
                            fontWeight: _viewModel.urgencyLevel == level
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _viewModel.urgencyLevel == level
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
            _viewModel.urgencyLevel.description,
            style: TextStyle(color: _getUrgencyColor()),
          ),
        ),
      ),
    ];
  }
  
  Color _getUrgencyColor() {
    switch (_viewModel.urgencyLevel) {
      case UrgencyLevel.low:
        return CupertinoColors.systemGreen;
      case UrgencyLevel.medium:
        return CupertinoColors.systemOrange;
      case UrgencyLevel.high:
        return CupertinoColors.systemRed;
    }
  }

  Widget _buildTermsSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Zustimmung'),
      footer: const Text('Bitte stimmen Sie den Nutzungsbedingungen zu, um fortzufahren.'),
      margin: _getResponsiveMargin(context),
      children: [
        _buildTermsAcceptanceRow(),
      ],
    );
  }

  Widget _buildTermsAcceptanceRow() {
    return Semantics(
      label: 'Allgemeine Geschäftsbedingungen akzeptieren',
      hint: 'Aktivieren Sie die Checkbox, um die AGBs zu akzeptieren',
      child: Row(
        children: [
          CupertinoCheckbox(
            value: _viewModel.hasAcceptedTerms,
            onChanged: (value) {
              if (value != null) {
                _viewModel.setHasAcceptedTerms(value);
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _viewModel.setHasAcceptedTerms(!_viewModel.hasAcceptedTerms),
              child: Text(
                'Ich habe die Allgemeinen Geschäftsbedingungen gelesen und akzeptiere sie',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Zeigt einen Validierungsfehler-Dialog an
  void _showValidationErrorDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eingabefehler'),
        content: Semantics(
          label: 'Formularvalidierungsfehler',
          liveRegion: true,
          child: const Text('Bitte füllen Sie alle erforderlichen Felder korrekt aus.'),
        ),
        actions: [
          Semantics(
            label: 'Verstanden',
            hint: 'Schließt diese Fehlermeldung',
            button: true,
            child: CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  /// Zeigt einen Fehler-Dialog für nicht akzeptierte AGBs an
  void _showTermsNotAcceptedError() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('AGBs nicht akzeptiert'),
        content: Semantics(
          label: 'AGBs Validierungsfehler',
          liveRegion: true,
          child: const Text('Bitte akzeptieren Sie die Allgemeinen Geschäftsbedingungen, um fortzufahren.'),
        ),
        actions: [
          Semantics(
            label: 'Verstanden',
            hint: 'Schließt diese Fehlermeldung',
            button: true,
            child: CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // Füge diese Methode zur Validierung und Übermittlung des Formulars hinzu
  void _validateAndSubmit(TroubleReportViewModel viewModel) {
    if (widget.formKey.currentState?.validate() ?? false) {
      widget.formKey.currentState?.save();
      
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
        phone: viewModel.phone ?? '',
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
      widget.onSubmit(report);
    } else {
      _showValidationErrorDialog();
    }
  }

  Widget _buildSubmitButton() {
    return Semantics(
      label: 'Störungsmeldung absenden',
      hint: 'Sendet das ausgefüllte Formular ab',
      button: true,
      enabled: !_isLoading,
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: _isLoading ? null : () => _validateAndSubmit(_viewModel),
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
} 