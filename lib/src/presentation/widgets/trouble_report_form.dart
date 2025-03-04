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
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.defaultPadding,
          AppConstants.defaultPadding,
          AppConstants.defaultPadding,
          AppConstants.defaultPadding + 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRequestTypeSection(),
            const SizedBox(height: AppConstants.defaultPadding),
            Platform.isIOS ? _buildCupertinoPersonalData() : _buildPersonalData(),
            const SizedBox(height: AppConstants.defaultPadding),
            Platform.isIOS ? _buildCupertinoDeviceData() : _buildDeviceData(),
            const SizedBox(height: AppConstants.defaultPadding),
            Platform.isIOS ? _buildCupertinoTroubleDescription() : _buildTroubleDescription(),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildUrgencySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTypeSection() {
    // Plattformspezifische Implementierung
    if (Platform.isIOS) {
      return _buildCupertinoRequestTypeSection();
    } else {
      return _buildMaterialRequestTypeSection();
    }
  }

  // Cupertino-Implementierung des Anliegens-Auswahlbereichs für iOS
  Widget _buildCupertinoRequestTypeSection() {
    return Card(
      elevation: 0,
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
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: _buildSectionHeader(
              'Art des Anliegens',
              'Wählen Sie die passende Kategorie',
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: _showCupertinoRequestTypePicker,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedType?.label ?? 'Bitte wählen',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedType != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  // Material-Implementierung des Anliegens-Auswahlbereichs (original)
  Widget _buildMaterialRequestTypeSection() {
    return Card(
      elevation: 0,
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
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: _buildSectionHeader(
              'Art des Anliegens',
              'Wählen Sie die passende Kategorie',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      padding: const EdgeInsets.all(16.0),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 16,
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

  // Methode zum Anzeigen des Cupertino Pickers für die Art des Anliegens
  void _showCupertinoRequestTypePicker() {
    int selectedIndex = _selectedType != null 
        ? RequestType.values.indexOf(_selectedType!)
        : 0;
        
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Fertig'),
                    onPressed: () {
                      // Auswahl aktualisieren ohne Scrollposition zu verändern
                      final selectedType = RequestType.values[selectedIndex];
                      Navigator.pop(context);
                      // Verzögerung hinzufügen, damit die Änderung erst nach dem Schließen des Dialogs erfolgt
                      Future.delayed(Duration.zero, () {
                        if (mounted) {
                          _updateRequestType(selectedType);
                        }
                      });
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
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
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cupertino-Implementierung für persönliche Daten
  Widget _buildCupertinoPersonalData() {
    return CupertinoFormSection.insetGrouped(
      header: Text(
        'Persönliche Daten',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.activeBlue,
        ),
      ),
      footer: Text(
        'Ihre Kontaktinformationen',
        style: TextStyle(color: CupertinoColors.systemGrey),
      ),
      children: [
        CupertinoFormRow(
          prefix: const Text('Name *'),
          child: CupertinoTextField(
            controller: _nameController,
            placeholder: 'Ihr vollständiger Name',
            onSubmitted: (_) => _emailFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('E-Mail *'),
          child: CupertinoTextField(
            controller: _emailController,
            placeholder: 'Ihre E-Mail-Adresse',
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            onSubmitted: (_) => _phoneFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Telefon'),
          child: CupertinoTextField(
            controller: _phoneController,
            placeholder: 'Ihre Telefonnummer',
            keyboardType: TextInputType.phone,
            focusNode: _phoneFocus,
            onSubmitted: (_) => _addressFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Adresse'),
          child: CupertinoTextField(
            controller: _addressController,
            placeholder: 'Ihre Adresse',
            focusNode: _addressFocus,
            onSubmitted: (_) => _deviceModelFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  // Cupertino-Implementierung für Gerätedaten
  Widget _buildCupertinoDeviceData() {
    // Formatiere das Datum im deutschen Format
    final dateFormatter = DateFormat.yMd();
    final String dateText = _selectedDate != null
        ? dateFormatter.format(_selectedDate!)
        : 'Bitte wählen Sie ein Datum';

    return CupertinoFormSection.insetGrouped(
      header: Text(
        'Gerätedaten',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.activeBlue,
        ),
      ),
      footer: Text(
        'Informationen zum betroffenen Gerät',
        style: TextStyle(color: CupertinoColors.systemGrey),
      ),
      children: [
        CupertinoFormRow(
          prefix: const Text('Gerätemodell'),
          child: CupertinoTextField(
            controller: _deviceModelController,
            placeholder: 'z.B. iPhone 13',
            focusNode: _deviceModelFocus,
            onSubmitted: (_) => _manufacturerFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Hersteller'),
          child: CupertinoTextField(
            controller: _manufacturerController,
            placeholder: 'z.B. Apple',
            focusNode: _manufacturerFocus,
            onSubmitted: (_) => _serialNumberFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Seriennummer'),
          child: CupertinoTextField(
            controller: _serialNumberController,
            placeholder: 'Seriennummer Ihres Gerätes',
            focusNode: _serialNumberFocus,
            onSubmitted: (_) => _errorCodeFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Fehlercode'),
          child: CupertinoTextField(
            controller: _errorCodeController,
            placeholder: 'Falls vorhanden',
            focusNode: _errorCodeFocus,
            onSubmitted: (_) => _serviceHistoryFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Servicehistorie'),
          child: CupertinoTextField(
            controller: _serviceHistoryController,
            placeholder: 'Letzte Wartungen oder Reparaturen',
            focusNode: _serviceHistoryFocus,
            onSubmitted: (_) => _descriptionFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
            maxLines: 2,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Datum des Vorfalls'),
          child: GestureDetector(
            onTap: _showDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerRight,
              child: Text(
                dateText,
                style: TextStyle(
                  color: _selectedDate != null ? CupertinoColors.black : CupertinoColors.systemGrey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Cupertino-Implementierung für Störungsbeschreibung
  Widget _buildCupertinoTroubleDescription() {
    return CupertinoFormSection.insetGrouped(
      header: Text(
        'Störungsbeschreibung',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.activeBlue,
        ),
      ),
      footer: Text(
        'Beschreiben Sie das Problem so genau wie möglich',
        style: TextStyle(color: CupertinoColors.systemGrey),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: CupertinoTextField(
            controller: _descriptionController,
            placeholder: 'Beschreibung des Problems *',
            focusNode: _descriptionFocus,
            onSubmitted: (_) => _alternativeContactFocus.requestFocus(),
            clearButtonMode: OverlayVisibilityMode.editing,
            minLines: 3,
            maxLines: 5,
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Alternative Kontaktmöglichkeit'),
          child: CupertinoTextField(
            controller: _alternativeContactController,
            placeholder: 'z.B. alternative E-Mail oder Telefonnummer',
            focusNode: _alternativeContactFocus,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoButton.filled(
                onPressed: _showCupertinoImagePickerOptions,
                child: Text(
                  _images.isEmpty
                      ? 'Fotos hinzufügen'
                      : '${_images.length} Foto${_images.length == 1 ? '' : 's'} ausgewählt',
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: const CupertinoActivityIndicator(radius: 15.0),
                ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: _buildCupertinoImagePreview,
                  ),
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
      header: Text(
        'Dringlichkeit',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.activeBlue,
        ),
      ),
      footer: Text(
        'Wie dringend benötigen Sie Unterstützung?',
        style: TextStyle(color: CupertinoColors.systemGrey),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CupertinoSegmentedControl<UrgencyLevel>(
            children: {
              UrgencyLevel.low: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Icon(CupertinoIcons.checkmark_circle, color: CupertinoColors.systemGreen),
                    const SizedBox(height: 5),
                    const Text('Niedrig'),
                  ],
                ),
              ),
              UrgencyLevel.medium: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.systemOrange),
                    const SizedBox(height: 5),
                    const Text('Mittel'),
                  ],
                ),
              ),
              UrgencyLevel.high: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed),
                    const SizedBox(height: 5),
                    const Text('Hoch'),
                  ],
                ),
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
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _selectedUrgencyLevel!.description,
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Wie zufrieden sind Sie mit dem Service bisher?',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
              Text('${_ratingValue.toInt()} / 5'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
      ],
    );
  }

  // Gesamte Urgency-Sektion mit Plattform-Auswahl
  Widget _buildUrgencySection() {
    return Platform.isIOS 
        ? _buildCupertinoUrgencySection() 
        : _buildMaterialUrgencySection();
  }

  // Material-Implementierung der Dringlichkeitsauswahl (original)
  Widget _buildMaterialUrgencySection() {
    return Card(
      elevation: 0,
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
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: _buildSectionHeader(
              'Dringlichkeit',
              'Wie dringend benötigen Sie Unterstützung?',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  padding: const EdgeInsets.only(bottom: 12.0),
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
                        padding: const EdgeInsets.all(16.0),
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    level.label,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? urgencyColor : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    level.description,
                                    style: TextStyle(
                                      fontSize: 14,
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

  // Bild-Vorschau für Cupertino
  Widget _buildCupertinoImagePreview(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: CupertinoContextMenu(
        actions: [
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              _showImage(index);
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
          child: Image.file(
            _images[index],
            height: 120,
            width: 120,
            fit: BoxFit.cover,
          ),
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
            child: const Text('Kamera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Galerie'),
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

  Future<void> _showDatePicker() async {
    if (Platform.isIOS) {
      _showCupertinoDatePicker();
    } else {
      // Material Date Picker für Android-Geräte (bisherige Implementierung)
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

  // Methode zum Anzeigen des CupertinoDatePickers
  void _showCupertinoDatePicker() {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Fertig'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
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
      ),
    );
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
} 