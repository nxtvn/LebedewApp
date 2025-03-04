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
  
  const TroubleReportForm({
    required this.formKey,
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
  final TextEditingController _alternativeContactController = TextEditingController();
  
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
  final FocusNode _alternativeContactFocus = FocusNode();
  
  // Lokale Zustandsvariablen für Auswahlwerte
  RequestType? _selectedType;
  UrgencyLevel? _selectedUrgencyLevel;
  DateTime? _selectedDate;
  double _ratingValue = 0.0; // Für CupertinoSlider
  bool _isLoading = false; // Für CupertinoActivityIndicator
  
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
      _alternativeContactController.text = _viewModel.alternativeContact ?? '';
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
    _alternativeContactController.addListener(() => _viewModel.setAlternativeContact(_alternativeContactController.text));
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
      _alternativeContactController.clear();
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
    _alternativeContactController.dispose();
    
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
    _alternativeContactFocus.dispose();
    
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
      setState(() => _images.removeAt(index));
      _viewModel.removeImagePath(index);
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
          for (final file in pickedFiles) {
            final imageFile = File(file.path);
            setState(() {
              _images.add(imageFile);
            });
            final path = await _viewModel.repository.saveImage(imageFile);
            _viewModel.addImagePath(path);
          }
        }
      } else {
        final XFile? pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null && mounted) {
          final imageFile = File(pickedFile.path);
          setState(() {
            _images.add(imageFile);
          });
          final path = await _viewModel.repository.saveImage(imageFile);
          _viewModel.addImagePath(path);
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
          AppConstants.defaultPadding + 80,
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
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                _buildCupertinoRequestTypeSection(),
                _buildCupertinoPersonalData(),
                _buildCupertinoDeviceData(),
                _buildCupertinoTroubleDescription(),
                _buildCupertinoUrgencySection(),
                const SizedBox(height: 20),
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
            'Art des Anliegens',
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
            'Kategorie',
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
          label: 'Telefon',
          placeholder: 'Ihre Telefonnummer',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          focusNode: _phoneFocus,
          nextFocus: _addressFocus,
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
          placeholder: 'z.B. iPhone 13',
          controller: _deviceModelController,
          keyboardType: TextInputType.text,
          focusNode: _deviceModelFocus,
          nextFocus: _manufacturerFocus,
        ),
        _buildCupertinoFormRow(
          label: 'Hersteller',
          placeholder: 'z.B. Apple',
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
        _buildCupertinoFormRow(
          label: 'Servicehistorie',
          placeholder: 'Letzte Wartungen',
          controller: _serviceHistoryController,
          keyboardType: TextInputType.text,
          focusNode: _serviceHistoryFocus,
          nextFocus: _descriptionFocus,
          multiline: true,
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
                placeholder: 'Beschreibung des Problems',
                focusNode: _descriptionFocus,
                onSubmitted: (_) => _alternativeContactFocus.requestFocus(),
                clearButtonMode: OverlayVisibilityMode.editing,
                minLines: 4,
                maxLines: 6,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
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
            ],
          ),
        ),
        _buildCupertinoFormRow(
          label: 'Alternative Kontaktmöglichkeit',
          placeholder: 'z.B. alternative E-Mail',
          controller: _alternativeContactController,
          keyboardType: TextInputType.text,
          focusNode: _alternativeContactFocus,
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
            'Dringlichkeit',
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
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: CupertinoSegmentedControl<UrgencyLevel>(
            padding: EdgeInsets.zero,
            children: {
              UrgencyLevel.low: _buildUrgencySegment(
                'Niedrig',
                CupertinoIcons.checkmark_circle,
                CupertinoColors.systemGreen,
              ),
              UrgencyLevel.medium: _buildUrgencySegment(
                'Mittel',
                CupertinoIcons.exclamationmark_circle,
                CupertinoColors.systemOrange,
              ),
              UrgencyLevel.high: _buildUrgencySegment(
                'Hoch',
                CupertinoIcons.exclamationmark_triangle,
                CupertinoColors.systemRed,
              ),
            },
            onValueChanged: (value) {
              _updateUrgencyLevel(value);
            },
            groupValue: _selectedUrgencyLevel,
          ),
        ),
        if (_selectedUrgencyLevel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Text(
              _selectedUrgencyLevel!.description,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: Text(
            'Ihre Zufriedenheit mit dem Service bisher:',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Expanded(
                child: CupertinoSlider(
                  value: _ratingValue,
                  min: 0.0,
                  max: 5.0,
                  divisions: 5,
                  onChanged: (value) {
                    setState(() {
                      _ratingValue = value;
                    });
                  },
                ),
              ),
              const Text(
                '5',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 16.0),
            child: Text(
              '${_ratingValue.toInt()} Sterne',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helfer-Methode zum Erstellen eines Segments in der Dringlichkeitsauswahl
  Widget _buildUrgencySegment(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.only(right: 8.0),
      child: CupertinoContextMenu(
        actions: [
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _showCupertinoImage(index);
            },
            trailingIcon: CupertinoIcons.eye,
            child: const Text('Anzeigen'),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _removeImage(index);
            },
            isDestructiveAction: true,
            trailingIcon: CupertinoIcons.delete,
            child: const Text('Löschen'),
          ),
        ],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 90,
            width: 90,
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
    );
  }

  // Bild in Vollansicht anzeigen (Cupertino-Stil)
  void _showCupertinoImage(int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Bildvorschau'),
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
                labelText: 'Telefon (optional)',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _addressFocus.requestFocus(),
              keyboardType: TextInputType.phone,
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
                hintText: 'Letzte Wartungen oder Reparaturen',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
              maxLines: 2,
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
                labelText: 'Beschreibung *',
                alignLabelWithHint: true,
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _alternativeContactFocus.requestFocus(),
              maxLines: 5,
              validator: (value) => Validators.validateRequired(value, 'Beschreibung'),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _alternativeContactController,
              focusNode: _alternativeContactFocus,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Alternative Kontaktmöglichkeit',
                hintText: 'z.B. alternative E-Mail oder Telefonnummer',
              ),
              textInputAction: TextInputAction.done,
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
              'Art des Anliegens',
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
              'Dringlichkeit',
              'Wie dringend benötigen Sie Unterstützung?',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Column(
              children: UrgencyLevel.values.map((level) {
                final isSelected = _selectedUrgencyLevel == level;
                // Farbkodierung basierend auf Dringlichkeitsstufe
                Color urgencyColor;
                switch (level) {
                  case UrgencyLevel.high:
                    urgencyColor = Colors.redAccent;
                    break;
                  case UrgencyLevel.medium:
                    urgencyColor = Colors.orangeAccent;
                    break;
                  case UrgencyLevel.low:
                    urgencyColor = Colors.greenAccent;
                    break;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isSelected ? urgencyColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? urgencyColor : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                        ? [BoxShadow(color: urgencyColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                        : [],
                    ),
                    child: InkWell(
                      onTap: () => _updateUrgencyLevel(level),
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
                                color: isSelected ? urgencyColor : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? urgencyColor : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    level.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? urgencyColor : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    level.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
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

  // Material-Dialog für Bildvorschau
  void _showImage(int index) {
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
                        onPressed: () => _removeImage(index),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Löschen', style: TextStyle(color: Colors.red)),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
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
                onPressed: () => Navigator.pop(context),
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
} 