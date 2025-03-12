import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform, File;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/enums/request_type.dart';
import '../../domain/enums/urgency_level.dart';
import '../viewmodels/trouble_report_viewmodel.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';

class TroubleReportForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback? onSubmit;
  
  const TroubleReportForm({
    required this.formKey,
    this.onSubmit,
    super.key,
  });

  @override
  State<TroubleReportForm> createState() => TroubleReportFormState();
}

class TroubleReportFormState extends State<TroubleReportForm> {
  // Controller als final Felder deklarieren
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _deviceModelController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _errorCodeController = TextEditingController();
  final TextEditingController _serviceHistoryController = TextEditingController();
  final TextEditingController _previousIssuesController = TextEditingController();
  
  // FocusNodes für jedes Textfeld
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _deviceModelFocus = FocusNode();
  final FocusNode _manufacturerFocus = FocusNode();
  final FocusNode _serialNumberFocus = FocusNode();
  final FocusNode _errorCodeFocus = FocusNode();
  final FocusNode _serviceHistoryFocus = FocusNode();
  final FocusNode _previousIssuesFocus = FocusNode();
  
  // Lokale Zustandsvariablen für Auswahlwerte
  RequestType? _selectedType;
  UrgencyLevel? _selectedUrgencyLevel;
  DateTime? _selectedDate;
  double _ratingValue = 0.0; // Für CupertinoSlider
  bool _isLoading = false; // Für CupertinoActivityIndicator
  bool _formWasSubmitted = false; // Zeigt an, ob das Formular abgesendet wurde
  
  final List<File> _images = [];
  final ScrollController _scrollController = ScrollController();

  // Referenz auf das ViewModel für einfacheren Zugriff
  late final TroubleReportViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    
    // ViewModel-Referenz initialisieren
    _viewModel = context.read<TroubleReportViewModel>();
    
    // Initialen Zustand aus dem ViewModel laden
    _loadInitialState();
    
    // Listener für Controller-Änderungen
    _setupControllerListeners();
  }

  void _loadInitialState() {
    // Lokale Zustandsvariablen mit ViewModel-Werten initialisieren
    setState(() {
      _selectedType = _viewModel.type;
      _selectedUrgencyLevel = _viewModel.urgencyLevel;
      _selectedDate = _viewModel.occurrenceDate;
      _images.clear();
      _images.addAll(_viewModel.images);
      
      // Controller mit initialen Werten aus dem ViewModel befüllen
      _descriptionController.text = _viewModel.description ?? '';
      _nameController.text = _viewModel.name ?? '';
      _emailController.text = _viewModel.email ?? '';
      _phoneController.text = _viewModel.phone ?? '';
      _addressController.text = _viewModel.address ?? '';
      _deviceModelController.text = _viewModel.deviceModel ?? '';
      _manufacturerController.text = _viewModel.manufacturer ?? '';
      _serialNumberController.text = _viewModel.serialNumber ?? '';
      _errorCodeController.text = _viewModel.errorCode ?? '';
      _serviceHistoryController.text = _viewModel.serviceHistory ?? '';
      _previousIssuesController.text = _viewModel.previousIssues ?? '';
    });
  }

  void _setupControllerListeners() {
    // Listener für TextEditingController
    _descriptionController.addListener(() => _viewModel.setDescription(_descriptionController.text));
    _nameController.addListener(() => _viewModel.setName(_nameController.text));
    _emailController.addListener(() => _viewModel.setEmail(_emailController.text));
    _phoneController.addListener(() => _viewModel.setPhone(_phoneController.text));
    _addressController.addListener(() => _viewModel.setAddress(_addressController.text));
    _deviceModelController.addListener(() => _viewModel.setDeviceModel(_deviceModelController.text));
    _manufacturerController.addListener(() => _viewModel.setManufacturer(_manufacturerController.text));
    _serialNumberController.addListener(() => _viewModel.setSerialNumber(_serialNumberController.text));
    _errorCodeController.addListener(() => _viewModel.setErrorCode(_errorCodeController.text));
    _serviceHistoryController.addListener(() => _viewModel.setServiceHistory(_serviceHistoryController.text));
    _previousIssuesController.addListener(() => _viewModel.setPreviousIssues(_previousIssuesController.text));
  }

  void reset() {
    setState(() {
      _selectedType = null;
      _selectedUrgencyLevel = null;
      _selectedDate = null;
      _images.clear();
      
      _descriptionController.clear();
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _deviceModelController.clear();
      _manufacturerController.clear();
      _serialNumberController.clear();
      _errorCodeController.clear();
      _serviceHistoryController.clear();
      _previousIssuesController.clear();
    });
  }

  @override
  void dispose() {
    // Controller und Listener aufräumen
    _descriptionController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _deviceModelController.dispose();
    _manufacturerController.dispose();
    _serialNumberController.dispose();
    _errorCodeController.dispose();
    _serviceHistoryController.dispose();
    _previousIssuesController.dispose();
    
    // FocusNodes aufräumen
    _descriptionFocus.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _deviceModelFocus.dispose();
    _manufacturerFocus.dispose();
    _serialNumberFocus.dispose();
    _errorCodeFocus.dispose();
    _serviceHistoryFocus.dispose();
    _previousIssuesFocus.dispose();
    
    _scrollController.dispose();
    super.dispose();
  }

  // Methoden für die Aktualisierung der Auswahlwerte
  void _updateRequestType(RequestType? value) {
    if (value != null && value != _selectedType) {
      setState(() => _selectedType = value);
      _viewModel.setType(value);
    }
  }

  void _updateUrgencyLevel(UrgencyLevel? value) {
    if (value != null && value != _selectedUrgencyLevel) {
      setState(() => _selectedUrgencyLevel = value);
      _viewModel.setUrgencyLevel(value);
    }
  }

  void _updateDate(DateTime? value) {
    if (value != null && value != _selectedDate) {
      setState(() => _selectedDate = value);
      _viewModel.setOccurrenceDate(value);
    }
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      // Fokus vorübergehend entfernen, um Fokus-Sprünge zu vermeiden
      final currentFocus = FocusScope.of(context).focusedChild;
      FocusScope.of(context).unfocus();
      
      setState(() => _images.removeAt(index));
      _viewModel.removeImagePath(index);
      
      // Kurze Verzögerung, damit setState abgeschlossen ist
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && currentFocus != null) {
          // Fokus wieder auf den vorherigen Bereich setzen
          FocusScope.of(context).requestFocus(currentFocus);
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });
    
    final picker = ImagePicker();
    
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isNotEmpty && mounted) {
          // Duplikate zählen
          int duplicateCount = 0;
          
          for (final file in pickedFiles) {
            final imageFile = File(file.path);
            
            // Prüfen, ob ein Bild mit dem gleichen Pfad bereits existiert
            bool isDuplicate = await _isImageDuplicate(imageFile);
            if (isDuplicate) {
              duplicateCount++;
              continue;
            }
            
            setState(() {
              _images.add(imageFile);
            });
            final path = await _viewModel.repository.saveImage(imageFile);
            _viewModel.addImagePath(path);
          }
          
          // Benutzer informieren, wenn Duplikate gefunden wurden
          if (duplicateCount > 0 && mounted) {
            _showDuplicateImageMessage(duplicateCount);
          }
        }
      } else {
        final XFile? pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null && mounted) {
          final imageFile = File(pickedFile.path);
          
          // Prüfen, ob ein Bild mit dem gleichen Pfad bereits existiert
          bool isDuplicate = await _isImageDuplicate(imageFile);
          if (isDuplicate) {
            _showDuplicateImageMessage(1);
          } else {
            setState(() {
              _images.add(imageFile);
            });
            final path = await _viewModel.repository.saveImage(imageFile);
            _viewModel.addImagePath(path);
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Hilfsmethode zum Prüfen, ob ein Bild bereits in der Liste ist
  Future<bool> _isImageDuplicate(File newImage) async {
    for (final existingImage in _images) {
      if (existingImage.path == newImage.path) {
        return true;
      }
      
      // Wenn Pfade unterschiedlich sind, prüfe Größe und Zeitstempel
      if (await _isSameImage(existingImage, newImage)) {
        return true;
      }
    }
    return false;
  }
  
  // Verbessere die Duplikaterkennung in der _isSameImage-Methode
  Future<bool> _isSameImage(File image1, File image2) async {
    // Direkte Pfadprüfung als erster Check
    if (image1.path == image2.path) {
      return true;
    }
    
    try {
      // Vergleiche Dateigröße als schnellen Check
      final size1 = await image1.length();
      final size2 = await image2.length();
      if (size1 != size2) {
        return false;
      }
      
      // Bei gleicher Dateigröße, vergleiche die letzten Änderungszeitstempel
      final stat1 = await image1.stat();
      final stat2 = await image2.stat();
      
      // Wir betrachten Bilder als identisch, wenn sie gleich groß sind und
      // der Zeitunterschied ihrer letzten Änderung weniger als 1 Sekunde beträgt
      final isSameSize = stat1.size == stat2.size;
      final isCloseTimeStamp = (stat1.modified.difference(stat2.modified).inMilliseconds.abs() < 2000);
      
      if (isSameSize && isCloseTimeStamp) {
        print('Duplikat gefunden: ${image1.path} und ${image2.path}');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Fehler beim Vergleichen der Bilder: $e');
      // Bei Fehler sicherheitshalber als kein Duplikat behandeln
      return false;
    }
  }

  // Zeigt eine Meldung an, wenn Duplikate gefunden wurden
  void _showDuplicateImageMessage(int count) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Hinweis'),
          content: Text(
            count == 1
                ? 'Dieses Bild wurde bereits hinzugefügt und wird übersprungen.'
                : '$count Bilder wurden bereits hinzugefügt und werden übersprungen.'
          ),
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
          content: Text(
            count == 1
                ? 'Dieses Bild wurde bereits hinzugefügt und wird übersprungen.'
                : '$count Bilder wurden bereits hinzugefügt und werden übersprungen.'
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Für iOS ein spezialisiertes Layout verwenden
    if (Platform.isIOS) {
      return _buildCupertinoForm(context);
    }
    
    // Ansonsten das Material Design-Layout beibehalten
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.defaultPadding / 2,
          AppConstants.defaultPadding,
          AppConstants.defaultPadding / 2,
          AppConstants.defaultPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMaterialRequestTypeSection(),
            const SizedBox(height: AppConstants.defaultPadding / 2),
            _buildPersonalData(),
            const SizedBox(height: AppConstants.defaultPadding / 2),
            _buildDeviceData(),
            const SizedBox(height: AppConstants.defaultPadding / 2),
            _buildTroubleDescription(),
            const SizedBox(height: AppConstants.defaultPadding / 2),
            _buildMaterialUrgencySection(),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildMaterialSubmitButton(),
            const SizedBox(height: AppConstants.defaultPadding),
          ],
        ),
      ),
    );
  }

  // iOS-spezifisches Formular-Layout
  Widget _buildCupertinoForm(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Form(
          key: widget.formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                _buildCupertinoRequestTypeSection(),
                _buildCupertinoPersonalData(),
                _buildCupertinoDeviceData(),
                _buildCupertinoTroubleDescription(),
                _buildCupertinoUrgencySection(),
                _buildCupertinoSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cupertino-Implementierung des Anliegens-Auswahlbereichs für iOS
  Widget _buildCupertinoRequestTypeSection() {
    return CupertinoFormSection.insetGrouped(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Art des Anliegens *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Wählen Sie die passende Kategorie aus',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
      children: [
        CupertinoFormRow(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefix: const Text(
            'Kategorie *',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.label,
            ),
          ),
          child: GestureDetector(
            onTap: _showCupertinoRequestTypePicker,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _selectedType?.label ?? 'Bitte wählen',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedType != null 
                        ? CupertinoColors.label 
                        : CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_right, 
                  size: 16, 
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Cupertino-Implementierung für persönliche Daten
  Widget _buildCupertinoPersonalData() {
    return CupertinoFormSection.insetGrouped(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Persönliche Daten',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ihre Kontaktinformationen',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
      children: [
        _buildCupertinoFormRow(
          label: 'Name *',
          placeholder: 'Ihr vollständiger Name',
          controller: _nameController,
          keyboardType: TextInputType.name,
          focusNode: _nameFocus,
          nextFocus: _emailFocus,
          validator: (value) => Validators.validateRequired(value, 'Name'),
        ),
        _buildCupertinoFormRow(
          label: 'E-Mail *',
          placeholder: 'Ihre E-Mail-Adresse',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          focusNode: _emailFocus,
          nextFocus: _phoneFocus,
          validator: Validators.validateEmail,
        ),
        _buildCupertinoFormRow(
          label: 'Telefon *',
          placeholder: 'Ihre Telefonnummer',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          focusNode: _phoneFocus,
          nextFocus: _addressFocus,
          validator: (value) => Validators.validateRequired(value, 'Telefonnummer'),
        ),
        _buildCupertinoFormRow(
          label: 'Adresse',
          placeholder: 'Ihre Adresse',
          controller: _addressController,
          keyboardType: TextInputType.streetAddress,
          focusNode: _addressFocus,
          nextFocus: _deviceModelFocus,
        ),
      ],
    );
  }

  // Helfer-Methode für Cupertino-Formularzeilen
  Widget _buildCupertinoFormRow({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    FormFieldValidator<String>? validator,
    bool multiline = false,
  }) {
    return CupertinoFormRow(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefix: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          color: CupertinoColors.label,
        ),
      ),
      error: validator != null && controller.text.isNotEmpty 
          ? (validator(controller.text) == null ? null : Text(validator(controller.text)!)) 
          : null,
      child: CupertinoTextField.borderless(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        focusNode: focusNode,
        onSubmitted: nextFocus != null ? (_) => nextFocus.requestFocus() : null,
        clearButtonMode: OverlayVisibilityMode.editing,
        padding: const EdgeInsets.only(left: 8),
        textAlign: TextAlign.end,
        maxLines: multiline ? 3 : 1,
        style: const TextStyle(
          fontSize: 16,
          color: CupertinoColors.label,
        ),
        placeholderStyle: const TextStyle(
          fontSize: 16,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  // Cupertino-Implementierung für Gerätedaten
  Widget _buildCupertinoDeviceData() {
    // Formatiere das Datum im deutschen Format
    final dateFormatter = DateFormat.yMd();
    final String dateText = _selectedDate != null
        ? dateFormatter.format(_selectedDate!)
        : 'Bitte wählen';

    return CupertinoFormSection.insetGrouped(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Gerätedaten',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Informationen zum betroffenen Gerät',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
      children: [
        _buildCupertinoFormRow(
          label: 'Gerätemodell',
          placeholder: 'z.B. Vitodens 200-W',
          controller: _deviceModelController,
          keyboardType: TextInputType.text,
          focusNode: _deviceModelFocus,
          nextFocus: _manufacturerFocus,
        ),
        _buildCupertinoFormRow(
          label: 'Hersteller',
          placeholder: 'z.B. Viessmann',
          controller: _manufacturerController,
          keyboardType: TextInputType.text,
          focusNode: _manufacturerFocus,
          nextFocus: _serialNumberFocus,
        ),
        _buildCupertinoFormRow(
          label: 'Seriennummer',
          placeholder: 'Seriennummer',
          controller: _serialNumberController,
          keyboardType: TextInputType.text,
          focusNode: _serialNumberFocus,
          nextFocus: _errorCodeFocus,
        ),
        _buildCupertinoFormRow(
          label: 'Fehlercode',
          placeholder: 'Falls vorhanden',
          controller: _errorCodeController,
          keyboardType: TextInputType.text,
          focusNode: _errorCodeFocus,
          nextFocus: _serviceHistoryFocus,
        ),
        CupertinoFormRow(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefix: const Text(
            'Servicehistorie',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.label,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CupertinoTextField.borderless(
                controller: _serviceHistoryController,
                placeholder: 'Letzte Wartungen oder Reparaturen (Datum und Art der Maßnahme)',
                keyboardType: TextInputType.multiline,
                focusNode: _serviceHistoryFocus,
                onSubmitted: (_) => _descriptionFocus.requestFocus(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textAlign: TextAlign.end,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
                placeholderStyle: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey4,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        CupertinoFormRow(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefix: const Text(
            'Datum des Vorfalls',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.label,
            ),
          ),
          child: GestureDetector(
            onTap: _showCupertinoDatePicker,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate != null 
                        ? CupertinoColors.label 
                        : CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.calendar, 
                  size: 20, 
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Cupertino-Implementierung für Störungsbeschreibung
  Widget _buildCupertinoTroubleDescription() {
    return CupertinoFormSection.insetGrouped(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Störungsbeschreibung',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Beschreiben Sie das Problem so genau wie möglich',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Beschreibung *',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: _descriptionController,
                placeholder: 'Detaillierte Beschreibung des Problems (Fehlercodes, Symptome, Zeitpunkt des Auftretens)',
                focusNode: _descriptionFocus,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                clearButtonMode: OverlayVisibilityMode.editing,
                minLines: 4,
                maxLines: 6,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _descriptionController.text.isEmpty && _formWasSubmitted
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey4,
                    width: _descriptionController.text.isEmpty && _formWasSubmitted ? 1.5 : 0.5,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
                placeholderStyle: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              if (_descriptionController.text.isEmpty && _formWasSubmitted)
                const Padding(
                  padding: EdgeInsets.only(top: 6.0, left: 4.0),
                  child: Text(
                    'Bitte geben Sie eine Problembeschreibung ein',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 14),
                borderRadius: BorderRadius.circular(10),
                onPressed: _showCupertinoImagePickerOptions,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.photo_camera, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _images.isEmpty
                          ? 'Fotos hinzufügen'
                          : '${_images.length} Foto${_images.length == 1 ? '' : 's'} ausgewählt',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CupertinoActivityIndicator(radius: 12),
                ),
              ],
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: _buildCupertinoImagePreview,
                  ),
                ),
                const SizedBox(height: 10),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    if (_images.isNotEmpty) {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          title: const Text('Fotos verwalten'),
                          message: const Text('Was möchten Sie mit den Fotos tun?'),
                          actions: [
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(context);
                                _showCupertinoImagePickerOptions();
                              },
                              child: const Text('Weitere Fotos hinzufügen'),
                            ),
                            CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _images.clear();
                                  while (_viewModel.images.isNotEmpty) {
                                    _viewModel.removeImagePath(0);
                                  }
                                });
                              },
                              child: const Text('Alle Fotos entfernen'),
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Abbrechen'),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Fotos verwalten'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Cupertino-Implementierung der Dringlichkeitsauswahl
  Widget _buildCupertinoUrgencySection() {
    return CupertinoFormSection.insetGrouped(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Dringlichkeit *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Wie dringend benötigen Sie Unterstützung?',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: UrgencyLevel.values.map((level) {
                    final isSelected = _selectedUrgencyLevel == level;
                    Color backgroundColor;
                    Color textColor;
                    IconData icon;
                    String label;
                    
                    switch (level) {
                      case UrgencyLevel.low:
                        backgroundColor = isSelected 
                            ? CupertinoColors.systemGreen.withOpacity(0.2) 
                            : CupertinoColors.systemBackground;
                        textColor = isSelected 
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemGrey;
                        icon = CupertinoIcons.checkmark_circle_fill;
                        label = 'Niedrig';
                        break;
                      case UrgencyLevel.medium:
                        backgroundColor = isSelected 
                            ? CupertinoColors.systemOrange.withOpacity(0.2)
                            : CupertinoColors.systemBackground;
                        textColor = isSelected 
                            ? CupertinoColors.systemOrange
                            : CupertinoColors.systemGrey;
                        icon = CupertinoIcons.exclamationmark_circle_fill;
                        label = 'Mittel';
                        break;
                      case UrgencyLevel.high:
                        backgroundColor = isSelected 
                            ? CupertinoColors.systemRed.withOpacity(0.2)
                            : CupertinoColors.systemBackground;
                        textColor = isSelected 
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGrey;
                        icon = CupertinoIcons.exclamationmark_triangle_fill;
                        label = 'Hoch';
                        break;
                    }
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _updateUrgencyLevel(level),
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: textColor, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: textColor,
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
              if (_selectedUrgencyLevel == null && _formWasSubmitted)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    'Bitte wählen Sie eine Dringlichkeitsstufe',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ),
              if (_selectedUrgencyLevel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(_selectedUrgencyLevel!).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getUrgencyColor(_selectedUrgencyLevel!).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _selectedUrgencyLevel!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getUrgencyColor(_selectedUrgencyLevel!),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Helfer-Methode zum Erstellen eines Segments in der Dringlichkeitsauswahl
  Widget _buildUrgencySegment(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hilfsmethod zur Bestimmung der Farbe für eine Dringlichkeitsstufe
  Color _getUrgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.high:
        return CupertinoColors.systemRed;
      case UrgencyLevel.medium:
        return CupertinoColors.systemOrange;
      case UrgencyLevel.low:
        return CupertinoColors.systemGreen;
    }
  }

  // Methode zum Anzeigen des Cupertino Pickers für die Art des Anliegens
  void _showCupertinoRequestTypePicker() {
    int selectedIndex = _selectedType != null 
        ? RequestType.values.indexOf(_selectedType!)
        : 0;
        
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Abbrechen'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Fertig'),
                    onPressed: () {
                      final selectedType = RequestType.values[selectedIndex];
                      Navigator.pop(context);
                      Future.delayed(Duration.zero, () {
                        if (mounted) {
                          _updateRequestType(selectedType);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                magnification: 1.1,
                squeeze: 1.1,
                useMagnifier: true,
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (int selectedItem) {
                  selectedIndex = selectedItem;
                },
                children: 
                  RequestType.values.map(
                    (type) => Center(
                      child: Text(
                        type.label,
                        style: const TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                  ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Methode zum Anzeigen des CupertinoDatePickers
  void _showCupertinoDatePicker() {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Abbrechen'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Fertig'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: initialDate,
                mode: CupertinoDatePickerMode.date,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(2000),
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDateTime) {
                  _updateDate(newDateTime);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CupertinoActionSheet für Bildauswahl
  void _showCupertinoImagePickerOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Foto hinzufügen'),
        message: const Text('Wählen Sie eine Option'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, color: CupertinoColors.activeBlue),
                const SizedBox(width: 10),
                const Text('Kamera'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, color: CupertinoColors.activeBlue),
                const SizedBox(width: 10),
                const Text('Galerie'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Abbrechen'),
        ),
      ),
    );
  }

  // Bild-Vorschau für Cupertino
  Widget _buildCupertinoImagePreview(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showCupertinoImage(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(
                  _images[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _removeImage(index);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bild in Vollansicht anzeigen (Cupertino-Stil)
  void _showCupertinoImage(int index) {
    // Fokus entfernen, um Fokus-Sprünge zu vermeiden
    final currentFocus = FocusScope.of(context).focusedChild;
    FocusScope.of(context).unfocus();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Bildvorschau'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(CupertinoIcons.delete, color: CupertinoColors.destructiveRed),
                SizedBox(width: 4),
                Text('Löschen', style: TextStyle(color: CupertinoColors.destructiveRed)),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              // Verzögerung hinzufügen, um sicherzustellen, dass der Dialog geschlossen ist
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _removeImage(index);
                  
                  // Fokus wiederherstellen, um unerwünschte Fokus-Sprünge zu vermeiden
                  if (currentFocus != null && mounted) {
                    Future.delayed(const Duration(milliseconds: 50), () {
                      FocusScope.of(context).requestFocus(currentFocus);
                    });
                  }
                }
              });
            },
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Fertig'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: InteractiveViewer(
              child: Image.file(_images[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }

  // Material-Implementierung für persönliche Daten
  Widget _buildPersonalData() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(51)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Persönliche Daten',
              'Ihre Kontaktinformationen',
            ),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Name *',
                hintText: 'Ihr vollständiger Name',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              validator: (value) => Validators.validateRequired(value, 'Name'),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'E-Mail *',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              validator: Validators.validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Telefon *',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _addressFocus.requestFocus(),
              keyboardType: TextInputType.phone,
              validator: (value) => Validators.validateRequired(value, 'Telefonnummer'),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _addressController,
              focusNode: _addressFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Adresse (optional)',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _deviceModelFocus.requestFocus(),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // Material-Implementierung für Gerätedaten
  Widget _buildDeviceData() {
    // Formatiere das Datum im deutschen Format
    final dateFormatter = DateFormat.yMd();
    final String dateText = _selectedDate != null
        ? dateFormatter.format(_selectedDate!)
        : 'Bitte wählen Sie ein Datum';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(51)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Gerätedaten',
              'Informationen zum betroffenen Gerät',
            ),
            TextFormField(
              controller: _deviceModelController,
              focusNode: _deviceModelFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Gerätemodell',
                hintText: 'z.B. Vitodens 200-W',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _manufacturerFocus.requestFocus(),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _manufacturerController,
              focusNode: _manufacturerFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Hersteller',
                hintText: 'z.B. Viessmann',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _serialNumberFocus.requestFocus(),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _serialNumberController,
              focusNode: _serialNumberFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Seriennummer',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _errorCodeFocus.requestFocus(),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _errorCodeController,
              focusNode: _errorCodeFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Fehlermeldung/Fehlercode',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _serviceHistoryFocus.requestFocus(),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _serviceHistoryController,
              focusNode: _serviceHistoryFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Servicehistorie',
                hintText: 'Letzte Wartungen oder Reparaturen (Datum und Art der Maßnahme)',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            InkWell(
              onTap: _showDatePicker,
              child: InputDecorator(
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'Datum des Vorfalls',
                ),
                child: Text(dateText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Material-Implementierung für Störungsbeschreibung
  Widget _buildTroubleDescription() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(51)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Störungsbeschreibung',
              'Beschreiben Sie das Problem so genau wie möglich',
            ),
            TextFormField(
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Problembeschreibung',
                hintText: 'Detaillierte Beschreibung des Problems (Fehlercodes, Symptome, Zeitpunkt des Auftretens)',
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
              textInputAction: TextInputAction.done,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte geben Sie eine Problembeschreibung ein';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            OutlinedButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(
                _images.isEmpty
                    ? 'Fotos hinzufügen'
                    : '${_images.length} Foto${_images.length == 1 ? '' : 's'} ausgewählt',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: _buildImagePreview,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Material-Implementierung des Anliegens-Auswahlbereichs (original)
  Widget _buildMaterialRequestTypeSection() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSectionHeader(
              'Art des Anliegens *',
              'Wählen Sie die passende Kategorie',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: RequestType.values.map((type) {
                final isSelected = _selectedType == type;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                      ? [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                  ),
                  child: InkWell(
                    onTap: () => _updateRequestType(type),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.blue : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.blue : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Material-Implementierung der Dringlichkeitsauswahl
  Widget _buildMaterialUrgencySection() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSectionHeader(
              'Dringlichkeit *',
              'Wie dringend benötigen Sie Unterstützung?',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: UrgencyLevel.values.map((level) {
                  final isSelected = _selectedUrgencyLevel == level;
                  // Farbkodierung basierend auf Dringlichkeitsstufe
                  Color urgencyColor;
                  IconData urgencyIcon;
                  switch (level) {
                    case UrgencyLevel.high:
                      urgencyColor = Colors.redAccent;
                      urgencyIcon = Icons.warning_rounded;
                      break;
                    case UrgencyLevel.medium:
                      urgencyColor = Colors.orangeAccent;
                      urgencyIcon = Icons.error_outline_rounded;
                      break;
                    case UrgencyLevel.low:
                      urgencyColor = Colors.greenAccent;
                      urgencyIcon = Icons.check_circle_outline_rounded;
                      break;
                  }
                  
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _updateUrgencyLevel(level),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? urgencyColor.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                urgencyIcon,
                                color: urgencyColor,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                level.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? urgencyColor : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_selectedUrgencyLevel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getUrgencyColorMaterial(_selectedUrgencyLevel!).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getUrgencyColorMaterial(_selectedUrgencyLevel!).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _selectedUrgencyLevel!.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _getUrgencyColorMaterial(_selectedUrgencyLevel!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Hilfsmethode zur Bestimmung der Farbe für Material-Design
  Color _getUrgencyColorMaterial(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.high:
        return Colors.redAccent;
      case UrgencyLevel.medium:
        return Colors.orangeAccent;
      case UrgencyLevel.low:
        return Colors.greenAccent;
    }
  }

  // Material-Version des DatePickers
  Future<void> _showDatePicker() async {
    if (Platform.isIOS) {
      _showCupertinoDatePicker();
    } else {
      // Material Date Picker für Android-Geräte
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (picked != null && mounted) {
        _updateDate(picked);
      }
    }
  }

  // Material-Bildvorschau
  Widget _buildImagePreview(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showImage(index),
              child: Image.file(
                _images[index],
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _removeImage(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Methode zum Anzeigen der Bildauswahloptionen (Material Design für Android)
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Foto hinzufügen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Foto mit der Kamera aufnehmen'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('Galerie'),
              subtitle: const Text('Ein oder mehrere Fotos aus der Galerie auswählen'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Material-Dialog für Bildvorschau
  void _showImage(int index) {
    // Fokus entfernen, um Fokus-Sprünge zu vermeiden
    final currentFocus = FocusScope.of(context).focusedChild;
    FocusScope.of(context).unfocus();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InteractiveViewer(
                  child: Image.file(_images[index]),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Verzögerung hinzufügen, um sicherzustellen, dass der Dialog geschlossen ist
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              _removeImage(index);
                              
                              // Fokus wiederherstellen, um unerwünschte Fokus-Sprünge zu vermeiden
                              if (currentFocus != null && mounted) {
                                Future.delayed(const Duration(milliseconds: 50), () {
                                  FocusScope.of(context).requestFocus(currentFocus);
                                });
                              }
                            }
                          });
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Löschen', style: TextStyle(color: Colors.red)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Fokus wiederherstellen, um unerwünschte Fokus-Sprünge zu vermeiden
                          if (currentFocus != null && mounted) {
                            Future.delayed(const Duration(milliseconds: 50), () {
                              FocusScope.of(context).requestFocus(currentFocus);
                            });
                          }
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Schließen'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: () => {
                  Navigator.pop(context),
                  // Fokus wiederherstellen, um unerwünschte Fokus-Sprünge zu vermeiden
                  if (currentFocus != null && mounted) {
                    Future.delayed(const Duration(milliseconds: 50), () {
                      FocusScope.of(context).requestFocus(currentFocus);
                    })
                  }
                },
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withAlpha(128),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Schaltfläche zum Absenden für Material Design (Android)
  Widget _buildMaterialSubmitButton() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(51)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: _isLoading
                ? LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.7),
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).colorScheme.primary,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLocalSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Wird gesendet...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.send, size: 22),
                      SizedBox(width: 12),
                      Text('Serviceanfrage absenden'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Lokale Methode zum Handling des Absenden-Buttons
  void _handleLocalSubmit() {
    setState(() => _formWasSubmitted = true);
    
    // Prüfen, ob alle erforderlichen Felder ausgefüllt sind
    final FormState? formState = Form.of(context);
    if (formState != null && !formState.validate()) {
      // Zeige eine Fehlermeldung an
      _showValidationErrorSnackbar(context);
      return;
    }
    
    // Überprüfe Dringlichkeitsstufe
    if (_selectedUrgencyLevel == null) {
      _showUrgencyLevelErrorSnackbar(context);
      return;
    }
    
    // Überprüfe Art des Anliegens
    if (_selectedType == null) {
      _showRequestTypeErrorSnackbar(context);
      return;
    }
    
    // Wenn alle Validierungen erfolgreich sind, rufe die onSubmit-Funktion auf
    if (widget.onSubmit != null) {
      widget.onSubmit!();
    }
  }

  // Hilfsmethode, um eine Fehlermeldung für die Dringlichkeitsstufe anzuzeigen
  void _showUrgencyLevelErrorSnackbar(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Dringlichkeit auswählen'),
          content: const Text('Bitte wählen Sie eine Dringlichkeitsstufe aus.'),
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
        const SnackBar(
          content: Text('Bitte wählen Sie eine Dringlichkeitsstufe aus.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Hilfsmethode, um eine Fehlermeldung für die Art des Anliegens anzuzeigen
  void _showRequestTypeErrorSnackbar(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Art des Anliegens auswählen'),
          content: const Text('Bitte wählen Sie eine Art des Anliegens aus.'),
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
        const SnackBar(
          content: Text('Bitte wählen Sie eine Art des Anliegens aus.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Hilfsmethode, um eine Fehlermeldung anzuzeigen
  void _showValidationErrorSnackbar(BuildContext context) {
    // Je nach Plattform unterschiedliche Fehlermeldungen anzeigen
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Formularfehler'),
          content: const Text('Bitte füllen Sie alle Pflichtfelder korrekt aus, bevor Sie die Serviceanfrage absenden.'),
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
        const SnackBar(
          content: Text('Bitte füllen Sie alle Pflichtfelder korrekt aus.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Schaltfläche zum Absenden für Cupertino (iOS)
  Widget _buildCupertinoSubmitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? LinearGradient(
                        colors: [
                          CupertinoColors.systemBlue.withOpacity(0.7),
                          CupertinoColors.activeBlue.withOpacity(0.7),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : LinearGradient(
                        colors: [
                          CupertinoColors.systemBlue,
                          CupertinoColors.activeBlue,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                onPressed: _isLoading ? null : _handleLocalSubmit,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(color: CupertinoColors.white),
                          const SizedBox(width: 12),
                          const Text(
                            'Wird gesendet...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.paperplane_fill, color: CupertinoColors.white, size: 22),
                          const SizedBox(width: 12),
                          const Text(
                            'Serviceanfrage absenden',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 