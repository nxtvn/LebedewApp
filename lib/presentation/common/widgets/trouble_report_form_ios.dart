import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/trouble_report.dart';
import '../../../domain/enums/urgency_level.dart';
import '../viewmodels/trouble_report_viewmodel.dart';
import 'trouble_report_form.dart';

class TroubleReportFormIOS extends TroubleReportForm {
  const TroubleReportFormIOS({
    Key? key,
    required GlobalKey<FormState> formKey,
    required Function(TroubleReport) onSubmit,
  }) : super(key: key, formKey: formKey, onSubmit: onSubmit);

  @override
  State<TroubleReportFormIOS> createState() => TroubleReportFormIOSState();
}

class TroubleReportFormIOSState extends State<TroubleReportFormIOS> with TroubleReportFormResetMixin {
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Foto hinzufügen'),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPersonalDataSection(),
                  const SizedBox(height: 16),
                  _buildDeviceDataSection(),
                  const SizedBox(height: 16),
                  _buildDescriptionSection(),
                  const SizedBox(height: 16),
                  _buildUrgencySection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataSection() {
    return CupertinoFormSection(
      header: const Text('Persönliche Daten'),
      children: [
        CupertinoFormRow(
          prefix: const Text('Name'),
          child: CupertinoTextFormFieldRow(
            controller: _nameController,
            placeholder: 'Geben Sie Ihren Namen ein',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihren Namen ein';
              }
              return null;
            },
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('E-Mail'),
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
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Telefon'),
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
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Adresse'),
          child: CupertinoTextFormFieldRow(
            controller: _addressController,
            placeholder: 'Geben Sie Ihre Adresse ein',
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceDataSection() {
    return CupertinoFormSection(
      header: const Text('Gerätedaten'),
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
            placeholder: 'Fehlercode, falls vorhanden',
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
              prefix: const Text('Wartungsvertrag'),
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
    return CupertinoFormSection(
      header: const Text('Störungsbeschreibung'),
      children: [
        CupertinoFormRow(
          child: CupertinoTextFormFieldRow(
            controller: _descriptionController,
            placeholder: 'Beschreiben Sie das Problem so genau wie möglich',
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte beschreiben Sie das Problem';
              }
              return null;
            },
          ),
        ),
        CupertinoFormRow(
          child: CupertinoButton(
            onPressed: _showImagePickerOptions,
            child: Consumer<TroubleReportViewModel>(
              builder: (context, viewModel, _) {
                return Text(
                  viewModel.images.isEmpty
                      ? 'Fotos hinzufügen'
                      : '${viewModel.images.length} Foto${viewModel.images.length == 1 ? '' : 's'} ausgewählt',
                );
              },
            ),
          ),
        ),
        if (_isLoading)
          const CupertinoFormRow(
            child: Center(child: CupertinoActivityIndicator()),
          ),
      ],
    );
  }

  Widget _buildUrgencySection() {
    return CupertinoFormSection(
      header: const Text('Dringlichkeit'),
      children: [
        Consumer<TroubleReportViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: UrgencyLevel.values.map((level) {
                final isSelected = viewModel.urgencyLevel == level;
                Color color;
                
                switch (level) {
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
                  prefix: Text(level.label),
                  child: GestureDetector(
                    onTap: () => viewModel.setUrgencyLevel(level),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : CupertinoColors.systemGrey3,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
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
} 