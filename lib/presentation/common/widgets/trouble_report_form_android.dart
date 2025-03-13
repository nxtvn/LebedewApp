import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/trouble_report.dart';
import '../../../domain/enums/request_type.dart';
import '../../../domain/enums/urgency_level.dart';
import '../../../core/constants/design_constants.dart';
import '../viewmodels/trouble_report_viewmodel.dart';
import 'trouble_report_form.dart';

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

  @override
  void initState() {
    super.initState();
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
  }

  /// Wählt ein Bild aus der Galerie oder Kamera aus
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      await _viewModel.pickImage(source, context);
    } finally {
      setState(() => _isLoading = false);
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

  Widget _buildImagePreview(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              _viewModel.images[index],
              height: 120,
              width: 120,
              fit: BoxFit.cover,
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
                onTap: () => _viewModel.removeImage(index),
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
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildRequestTypeSection() {
    return Card(
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
                      title: Text(type.label),
                      value: type,
                      groupValue: viewModel.type,
                      onChanged: (value) {
                        if (value != null) {
                          viewModel.setType(value);
                        }
                      },
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte geben Sie Ihren Namen ein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
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
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
                }
                return null;
              },
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
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: viewModel.images.length,
                        itemBuilder: _buildImagePreview,
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

  Widget _buildSubmitButton() {
    return Consumer<TroubleReportViewModel>(
      builder: (context, viewModel, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (widget.formKey.currentState!.validate()) {
                      // Erstelle TroubleReport-Objekt und übergebe es an onSubmit
                      final report = TroubleReport(
                        type: viewModel.type,
                        name: viewModel.name ?? '',
                        email: viewModel.email ?? '',
                        phone: viewModel.phone,
                        address: viewModel.address,
                        hasMaintenanceContract: viewModel.hasMaintenanceContract,
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
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
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