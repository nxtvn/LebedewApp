import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _log.info('TroubleReportFormIOS initialisiert');
    _viewModel = Provider.of<TroubleReportViewModel>(context, listen: false);
    _initControllers();
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
  }

  /// Zeigt die Optionen zur Bildauswahl an
  void _showImagePickerOptions() {
    _log.info('Bildauswahl-Optionen angezeigt');
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Bild hinzufügen'),
        message: const Text('Wählen Sie eine Option'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
            child: const Text('Kamera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Galerie'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          isDestructiveAction: true,
          child: const Text('Abbrechen'),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey4),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withAlpha(51),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Image.file(
                      _viewModel.images[index],
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        color: CupertinoColors.black.withAlpha(128),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.fullscreen,
                            color: CupertinoColors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => _confirmImageRemoval(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withAlpha(77),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 16,
                  color: CupertinoColors.destructiveRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Zeigt ein Bild im Vollbildmodus an
  void _showFullScreenImage(int index) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Bildvorschau'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Fertig'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                _viewModel.images[index],
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bestätigt das Entfernen eines Bildes
  void _confirmImageRemoval(int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Bild entfernen'),
        content: const Text('Möchten Sie dieses Bild wirklich entfernen?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Abbrechen'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Entfernen'),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _viewModel.removeImage(index);
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestTypeSection(),
          const SizedBox(height: 16),
          _buildPersonalDataSection(),
          const SizedBox(height: 16),
          _buildDeviceDataSection(),
          const SizedBox(height: 16),
          _buildDescriptionSection(),
          const SizedBox(height: 16),
          _buildUrgencySection(),
          const SizedBox(height: 16),
          _buildTermsSection(),
        ],
      ),
    );
  }

  Widget _buildRequestTypeSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Art des Anliegens *'),
      footer: const Text('Wählen Sie die passende Kategorie'),
      children: [
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            // Erstelle eine Map für den CupertinoSegmentedControl
            final Map<RequestType, Widget> requestTypeSegments = {};
            
            // Füge für jeden RequestType ein Widget zur Map hinzu
            for (var type in RequestType.values) {
              requestTypeSegments[type] = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon je nach RequestType
                    Icon(
                      _getIconForRequestType(type),
                      color: viewModel.type == type 
                          ? CupertinoColors.white 
                          : CupertinoColors.activeBlue,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    // Label
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: viewModel.type == type 
                            ? CupertinoColors.white 
                            : CupertinoColors.label.resolveFrom(context),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: CupertinoFormRow(
                child: CupertinoSegmentedControl<RequestType>(
                  children: requestTypeSegments,
                  groupValue: viewModel.type,
                  onValueChanged: (RequestType value) {
                    viewModel.setType(value);
                  },
                  padding: const EdgeInsets.all(4),
                ),
              ),
            );
          },
        ),
        // Zeige eine Beschreibung des ausgewählten Typs an
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            return CupertinoFormRow(
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
                          _getIconForRequestType(viewModel.type),
                          color: CupertinoColors.activeBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          viewModel.type.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDescriptionForRequestType(viewModel.type),
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Hilfsmethode, um das passende Icon für jeden RequestType zu erhalten
  IconData _getIconForRequestType(RequestType type) {
    switch (type) {
      case RequestType.trouble:
        return CupertinoIcons.exclamationmark_triangle;
      case RequestType.maintenance:
        return CupertinoIcons.wrench;
      case RequestType.installation:
        return CupertinoIcons.hammer;
      case RequestType.consultation:
        return CupertinoIcons.chat_bubble_2;
      case RequestType.other:
        return CupertinoIcons.question;
    }
  }

  // Hilfsmethode, um eine Beschreibung für jeden RequestType zu erhalten
  String _getDescriptionForRequestType(RequestType type) {
    switch (type) {
      case RequestType.trouble:
        return 'Melden Sie ein Problem oder eine Störung an Ihrem Gerät.';
      case RequestType.maintenance:
        return 'Vereinbaren Sie einen Termin für die regelmäßige Wartung Ihres Geräts.';
      case RequestType.installation:
        return 'Anfrage für die Installation eines neuen Geräts oder Systems.';
      case RequestType.consultation:
        return 'Beratung zu Produkten, Lösungen oder technischen Fragen.';
      case RequestType.other:
        return 'Andere Anfragen, die nicht in die obigen Kategorien passen.';
    }
  }

  Widget _buildPersonalDataSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Persönliche Daten'),
      footer: const Text('Ihre Kontaktinformationen'),
      children: [
        CupertinoFormRow(
          prefix: const Text('Name *'),
          child: CupertinoTextFormFieldRow(
            controller: _nameController,
            placeholder: 'Name eingeben',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihren Namen ein';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('E-Mail *'),
          child: CupertinoTextFormFieldRow(
            controller: _emailController,
            placeholder: 'E-Mail eingeben',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihre E-Mail-Adresse ein';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
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

  Widget _buildDeviceDataSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Gerätedaten'),
      footer: const Text('Informationen zum betroffenen Gerät'),
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
      header: const Text('Störungsbeschreibung'),
      footer: const Text('Beschreiben Sie das Problem so genau wie möglich'),
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
      header: const Text('Dringlichkeit *'),
      footer: const Text('Wie dringend benötigen Sie Unterstützung?'),
      children: [
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            return CupertinoFormRow(
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
                        onTap: () => viewModel.setUrgencyLevel(level),
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
                                level.label,
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
            );
          },
        ),
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            Color color;
            final urgencyLevel = viewModel.urgencyLevel;
            
            switch (urgencyLevel) {
              case UrgencyLevel.low:
                color = CupertinoColors.systemGreen;
                break;
              case UrgencyLevel.medium:
                color = CupertinoColors.systemOrange;
                break;
              case UrgencyLevel.high:
                color = CupertinoColors.systemRed;
                break;
            }
            
            return CupertinoFormRow(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(30)),
                ),
                child: Text(
                  urgencyLevel.description,
                  style: TextStyle(color: color),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Nutzungsbedingungen *'),
      footer: const Text('Sie müssen die AGBs akzeptieren, um fortzufahren'),
      children: [
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            return CupertinoFormRow(
              prefix: const Text('AGBs akzeptieren *'),
              error: !viewModel.hasAcceptedTerms && widget.formKey.currentState?.validate() == false
                  ? const Text('Bitte akzeptieren Sie die AGBs', style: TextStyle(color: CupertinoColors.destructiveRed))
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showTermsAndConditions(),
                      child: const Text(
                        'Ich akzeptiere die AGBs der Lebedew Haustechnik',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: viewModel.hasAcceptedTerms,
                    onChanged: (value) => viewModel.setHasAcceptedTerms(value),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showTermsAndConditions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Allgemeine Geschäftsbedingungen'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Schließen'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Allgemeine Geschäftsbedingungen der Lebedew Haustechnik',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Geltungsbereich\n\n'
                  'Diese Allgemeinen Geschäftsbedingungen gelten für alle Verträge, Lieferungen und sonstigen Leistungen der Lebedew Haustechnik (nachfolgend "Anbieter" genannt) gegenüber ihren Kunden.\n\n'
                  '2. Vertragsschluss\n\n'
                  'Mit Absenden einer Störungsmeldung über die App gibt der Kunde ein Angebot zum Abschluss eines Vertrages ab. Der Vertrag kommt zustande, wenn der Anbieter dieses Angebot annimmt.\n\n'
                  '3. Leistungen\n\n'
                  'Der Anbieter erbringt Leistungen im Bereich der Haustechnik, insbesondere Reparatur-, Wartungs- und Installationsarbeiten.\n\n'
                  '4. Preise und Zahlungsbedingungen\n\n'
                  'Die Preise für die Leistungen des Anbieters richten sich nach der jeweils aktuellen Preisliste. Die Zahlung erfolgt nach Rechnungsstellung.\n\n'
                  '5. Datenschutz\n\n'
                  'Der Anbieter erhebt, verarbeitet und nutzt personenbezogene Daten des Kunden gemäß den geltenden Datenschutzbestimmungen. Weitere Informationen finden Sie in unserer Datenschutzerklärung.\n\n'
                  '6. Schlussbestimmungen\n\n'
                  'Es gilt das Recht der Bundesrepublik Deutschland. Gerichtsstand ist, soweit gesetzlich zulässig, der Sitz des Anbieters.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CupertinoButton.filled(
                    child: const Text('Zurück zum Formular'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 