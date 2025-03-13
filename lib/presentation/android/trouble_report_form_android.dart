import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import '../common/widgets/trouble_report_form.dart';
import '../../domain/enums/request_type.dart';
import '../../domain/enums/urgency_level.dart';
import '../../domain/entities/trouble_report.dart';
import '../../core/constants/design_constants.dart';

class TroubleReportFormAndroid extends TroubleReportForm {
  const TroubleReportFormAndroid({
    Key? key,
    required GlobalKey<FormState> formKey,
    required Function(TroubleReport) onSubmit,
  }) : super(key: key, formKey: formKey, onSubmit: onSubmit);

  @override
  State<TroubleReportFormAndroid> createState() => _TroubleReportFormAndroidState();
}

class _TroubleReportFormAndroidState extends State<TroubleReportFormAndroid> with TroubleReportFormResetMixin {
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

  late TroubleReportViewModel _viewModel;
  bool _isLoading = false;
  
  // Add timer variable
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<TroubleReportViewModel>(context, listen: false);
    
    // Versuche, gespeicherten Formularstatus zu laden
    _viewModel.loadFormState().then((hasState) {
      _initControllers();
    });
    
    // Setze einen Timer, um regelmäßig den Formularstatus zu speichern
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _viewModel.saveFormState();
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
  }

  @override
  void dispose() {
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
    
    _viewModel.reset();
    _viewModel.clearSavedFormState();
  }

  /// Wählt ein Bild aus der Galerie oder Kamera aus
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      await _viewModel.pickImage(source, context);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
            Semantics(
              label: 'Mit Kamera fotografieren',
              hint: 'Öffnet die Kamera, um ein Foto aufzunehmen',
              button: true,
              child: ListTile(
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
            ),
            Semantics(
              label: 'Aus Galerie auswählen',
              hint: 'Öffnet die Bildergalerie zur Fotoauswahl',
              button: true,
              child: ListTile(
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
            ),
            const SizedBox(height: 8),
          ],
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
            border: Border.all(color: Colors.grey.shade300),
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
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 8.0;
    if (width < 600) return 16.0;
    return 24.0;
  }

  @override
  Widget build(BuildContext context) {
    final padding = _getResponsivePadding(context);
    
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildRequestTypeSection(),
          ),
          SizedBox(height: padding / 2),
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildPersonalDataSection(),
          ),
          SizedBox(height: padding / 2),
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildDeviceDataSection(),
          ),
          SizedBox(height: padding / 2),
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildDescriptionSection(),
          ),
          SizedBox(height: padding / 2),
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildUrgencySection(),
          ),
          SizedBox(height: padding / 2),
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildTermsSection(),
          ),
          SizedBox(height: padding),
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildSubmitButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTypeSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          // ignore: deprecated_member_use
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Art des Anliegens *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wählen Sie die passende Kategorie',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<TroubleReportViewModel>(
              builder: (context, viewModel, _) {
                return Column(
                  children: RequestType.values.map((type) {
                    return RadioListTile<RequestType>(
                      title: Text(
                        type.label,
                        style: TextStyle(
                          fontWeight: viewModel.type == type ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      value: type,
                      groupValue: viewModel.type,
                      onChanged: (value) {
                        if (value != null) {
                          viewModel.setType(value);
                        }
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      tileColor: viewModel.type == type 
                        // ignore: deprecated_member_use
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
                        : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Persönliche Daten',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ihre Kontaktinformationen',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Name Eingabefeld',
              hint: 'Geben Sie Ihren vollständigen Namen ein',
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie Ihren Namen ein';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'E-Mail Eingabefeld',
              hint: 'Geben Sie Ihre E-Mail-Adresse ein',
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail *',
                  border: OutlineInputBorder(),
                ),
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
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte geben Sie Ihre Telefonnummer ein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gerätedaten',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informationen zum betroffenen Gerät',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deviceModelController,
              decoration: const InputDecoration(
                labelText: 'Gerätemodell',
                hintText: 'z.B. Vitodens 200-W',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _manufacturerController,
              decoration: const InputDecoration(
                labelText: 'Hersteller',
                hintText: 'z.B. Viessmann',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serialNumberController,
              decoration: const InputDecoration(
                labelText: 'Seriennummer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _errorCodeController,
              decoration: const InputDecoration(
                labelText: 'Fehlercode',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serviceHistoryController,
              decoration: const InputDecoration(
                labelText: 'Servicehistorie',
                hintText: 'Letzte Wartungen oder Reparaturen',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Consumer<TroubleReportViewModel>(
              builder: (context, viewModel, _) {
                return InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: viewModel.occurrenceDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      viewModel.setOccurrenceDate(date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Datum des Vorfalls',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      viewModel.occurrenceDate != null
                          ? '${viewModel.occurrenceDate!.day}.${viewModel.occurrenceDate!.month}.${viewModel.occurrenceDate!.year}'
                          : 'Bitte wählen',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer<TroubleReportViewModel>(
              builder: (context, viewModel, _) {
                return CheckboxListTile(
                  title: const Text('Wartungsvertrag vorhanden'),
                  value: viewModel.hasMaintenanceContract,
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setHasMaintenanceContract(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Störungsbeschreibung',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Beschreiben Sie das Problem so genau wie möglich',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Problembeschreibung *',
                hintText: 'Detaillierte Beschreibung des Problems',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte beschreiben Sie das Problem';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.add_photo_alternate),
              label: Consumer<TroubleReportViewModel>(
                builder: (context, viewModel, _) {
                  return Text(
                    viewModel.images.isEmpty
                        ? 'Fotos hinzufügen'
                        : '${viewModel.images.length} Foto${viewModel.images.length == 1 ? '' : 's'} ausgewählt',
                  );
                },
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            Consumer<TroubleReportViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.images.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: MediaQuery.of(context).size.width < 400
                          ? GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: viewModel.images.length,
                              itemBuilder: _buildImagePreview,
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: viewModel.images.length,
                              itemBuilder: _buildImagePreview,
                              itemExtent: 120,
                            ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dringlichkeit *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wie dringend benötigen Sie Unterstützung?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<TroubleReportViewModel>(
              builder: (context, viewModel, _) {
                return Row(
                  children: UrgencyLevel.values.map((level) {
                    Color color = Colors.blue;
                    IconData icon = Icons.info;
                    
                    switch (level) {
                      case UrgencyLevel.low:
                        color = Colors.green;
                        icon = Icons.info;
                        break;
                      case UrgencyLevel.medium:
                        color = Colors.orange;
                        icon = Icons.warning;
                        break;
                      case UrgencyLevel.high:
                        color = Colors.red;
                        icon = Icons.error;
                        break;
                    }
                    
                    return Expanded(
                      child: InkWell(
                        onTap: () => viewModel.setUrgencyLevel(level),
                        child: Card(
                          color: viewModel.urgencyLevel == level
                              ? color.withAlpha(DesignConstants.lowOpacityAlpha)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(icon, color: color, size: 32),
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
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer<TroubleReportViewModel>(
              builder: (context, viewModel, _) {
                Color color = Colors.blue;
                final urgencyLevel = viewModel.urgencyLevel;
                switch (urgencyLevel) {
                  case UrgencyLevel.low:
                    color = Colors.green;
                    break;
                  case UrgencyLevel.medium:
                    color = Colors.orange;
                    break;
                  case UrgencyLevel.high:
                    color = Colors.red;
                    break;
                }
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withAlpha(DesignConstants.lowOpacityAlpha),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withAlpha(DesignConstants.mediumOpacityAlpha)),
                  ),
                  child: Text(
                    urgencyLevel.description,
                    style: TextStyle(color: color),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Text(
                'Bedingungen und Datenschutz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<TroubleReportViewModel>(
              builder: (context, viewModel, _) {
                return Semantics(
                  label: 'Allgemeine Geschäftsbedingungen akzeptieren',
                  hint: 'Aktivieren Sie die Checkbox, um die AGBs zu akzeptieren',
                  child: CheckboxListTile(
                    title: const Text(
                      'Ich habe die Allgemeinen Geschäftsbedingungen gelesen und akzeptiere sie',
                    ),
                    value: viewModel.hasAcceptedTerms,
                    onChanged: (value) {
                      if (value != null) {
                        viewModel.setHasAcceptedTerms(value);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'AGBs anzeigen',
              hint: 'Zeigt die vollständigen Allgemeinen Geschäftsbedingungen an',
              button: true,
              child: TextButton(
                onPressed: _showTermsAndConditions,
                child: const Text('Allgemeine Geschäftsbedingungen anzeigen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allgemeine Geschäftsbedingungen'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Allgemeine Geschäftsbedingungen der Lebedew Haustechnik',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
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
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<TroubleReportViewModel>(
      builder: (context, viewModel, _) {
        return Semantics(
          label: 'Störungsmeldung absenden',
          hint: 'Sendet das ausgefüllte Formular ab',
          button: true,
          enabled: !_isLoading,
          child: FilledButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (widget.formKey.currentState?.validate() ?? false) {
                      widget.formKey.currentState?.save();
                      
                      // Check if terms are accepted
                      if (!viewModel.hasAcceptedTerms) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bitte akzeptieren Sie die Allgemeinen Geschäftsbedingungen'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // Create TroubleReport
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
                        imagesPaths: const [],
                      );
                      widget.onSubmit(report);
                    }
                  },
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(double.infinity, 56)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Störungsmeldung absenden',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        );
      },
    );
  }
}