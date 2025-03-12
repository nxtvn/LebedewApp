import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../domain/enums/request_type.dart';
import '../../../domain/enums/urgency_level.dart';
import '../viewmodels/trouble_report_viewmodel.dart';

class TroubleReportFormAndroid extends StatefulWidget {
  const TroubleReportFormAndroid({Key? key}) : super(key: key);

  @override
  State<TroubleReportFormAndroid> createState() => _TroubleReportFormAndroidState();
}

class _TroubleReportFormAndroidState extends State<TroubleReportFormAndroid> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      await _viewModel.pickImage(source);
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
      key: _formKey,
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
                    final isSelected = viewModel.type == type;
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
                    Color color;
                    IconData icon;
                    
                    switch (level) {
                      case UrgencyLevel.low:
                        color = Colors.green;
                        icon = Icons.check_circle;
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
                              ? color.withOpacity(0.1)
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
                if (viewModel.urgencyLevel == null) {
                  return const SizedBox.shrink();
                }
                
                Color color;
                switch (viewModel.urgencyLevel!) {
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    viewModel.urgencyLevel!.description,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() => _isLoading = true);
            try {
              final success = await _viewModel.submitReport();
              if (success && mounted) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    title: const Text('Störungsmeldung erfolgreich gesendet'),
                    content: const Text(
                      'Vielen Dank für Ihre Meldung. Wir haben Ihre Störungsmeldung erhalten und werden uns zeitnah mit Ihnen in Verbindung setzen.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _formKey.currentState?.reset();
                          _viewModel.reset();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fehler beim Senden der Störungsmeldung. Bitte versuchen Sie es später erneut.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Störungsmeldung absenden',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
} 