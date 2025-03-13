import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import '../common/widgets/trouble_report_form.dart';
import '../../domain/entities/trouble_report.dart';
import '../../domain/enums/request_type.dart';
import '../../domain/enums/urgency_level.dart';

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

  late TroubleReportViewModel _viewModel;
  bool _isLoading = false;
  DateTime? _selectedDate;

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
    _selectedDate = null;
    _viewModel.reset();
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _viewModel.images[index],
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => _viewModel.removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
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
    return CupertinoFormSection.insetGrouped(
      header: const Text('Art des Anliegens *'),
      footer: const Text('Wählen Sie die passende Kategorie'),
      children: [
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: RequestType.values.map((type) {
                return CupertinoFormRow(
                  prefix: Text(type.label),
                  child: CupertinoRadioChoice(
                    selectedValue: viewModel.type,
                    value: type,
                    onChanged: (value) => viewModel.setType(value),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
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
            placeholder: 'Geben Sie Ihren Namen ein',
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
            placeholder: 'Geben Sie Ihre E-Mail-Adresse ein',
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
            placeholder: 'Geben Sie Ihre Telefonnummer ein',
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
            placeholder: 'Geben Sie Ihre Adresse ein',
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
            placeholder: 'z.B. Vitodens 200-W',
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Hersteller'),
          child: CupertinoTextFormFieldRow(
            controller: _manufacturerController,
            placeholder: 'z.B. Viessmann',
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Seriennummer'),
          child: CupertinoTextFormFieldRow(
            controller: _serialNumberController,
            placeholder: 'Seriennummer des Geräts',
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
            placeholder: 'Letzte Wartungen oder Reparaturen',
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
                        : 'Bitte wählen',
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
            placeholder: 'Detaillierte Beschreibung des Problems',
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
              onPressed: _showImagePickerOptions,
              child: Consumer<TroubleReportViewModel>(
                builder: (context, viewModel, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.photo_camera),
                      const SizedBox(width: 8),
                      Text(
                        viewModel.images.isEmpty
                            ? 'Fotos hinzufügen'
                            : '${viewModel.images.length} Foto${viewModel.images.length == 1 ? '' : 's'} ausgewählt',
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
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.images.isEmpty) {
              return const SizedBox.shrink();
            }
            return CupertinoFormRow(
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.images.length,
                  itemBuilder: _buildImagePreview,
                ),
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

  Widget _buildSubmitButton() {
    return Consumer<TroubleReportViewModel>(
      builder: (context, viewModel, _) {
        return SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
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
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
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

// Hilfswdget für Radio-Buttons im iOS-Stil
class CupertinoRadioChoice extends StatelessWidget {
  final RequestType selectedValue;
  final RequestType value;
  final Function(RequestType) onChanged;

  const CupertinoRadioChoice({
    Key? key,
    required this.selectedValue,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        alignment: Alignment.centerRight,
        child: selectedValue == value
            ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
            : const SizedBox(width: 24),
      ),
    );
  }
} 