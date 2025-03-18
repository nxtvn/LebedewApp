import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/enums/request_type.dart';
import '../../domain/enums/urgency_level.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import '../../core/constants/design_constants.dart';
import '../../domain/entities/trouble_report.dart';
import 'package:uuid/uuid.dart';

class TroubleReportFormAndroid extends ConsumerStatefulWidget {
  final Function(TroubleReport) onSubmit;

  const TroubleReportFormAndroid({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  ConsumerState<TroubleReportFormAndroid> createState() => _TroubleReportFormAndroidState();
}

class _TroubleReportFormAndroidState extends ConsumerState<TroubleReportFormAndroid> {
  late TroubleReportViewModel _viewModel;
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _customerNumberController = TextEditingController();
  final TextEditingController _deviceModelController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _errorCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(troubleReportViewModelProvider);
    
    // Versuche, gespeicherten Formularstatus zu laden
    _viewModel.loadFormState().then((hasState) {
      if (hasState) {
        _updateControllersFromViewModel();
      }
    });
    
    // Automatisches Speichern des Formularstatus alle 30 Sekunden
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _viewModel.saveFormState();
      }
    });
  }

  void _updateControllersFromViewModel() {
    // Hier die Controller mit den Werten aus dem ViewModel initialisieren
  }

  @override
  void dispose() {
    // Controller freigeben
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _customerNumberController.dispose();
    _deviceModelController.dispose();
    _manufacturerController.dispose();
    _serialNumberController.dispose();
    _errorCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    // Form zurücksetzen
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _customerNumberController.clear();
    _deviceModelController.clear();
    _manufacturerController.clear();
    _serialNumberController.clear();
    _errorCodeController.clear();
    _descriptionController.clear();
    
    _viewModel.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Wir greifen auf das ViewModel über ref zu
    final viewModel = ref.watch(troubleReportViewModelProvider);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Beispiel für ein Textfeld
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Ihr vollständiger Name',
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
          
          // Beispiel für eine RadioGroup für RequestType
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: RequestType.values.map((type) {
              return RadioListTile<RequestType>(
                title: Text(
                  type.displayName,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                tileColor: viewModel.type == type 
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
                  : null,
              );
            }).toList(),
          ),
          
          // Beispiel für UrgencyLevel-Auswahl
          Row(
            children: UrgencyLevel.values.map((level) {
              Color color;
              IconData icon;
              
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
                case UrgencyLevel.critical:
                  color = Colors.purple;
                  icon = Icons.dangerous;
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
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(icon, color: color),
                          const SizedBox(height: 4),
                          Text(
                            level.displayName,
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
          ),
          
          // Absendebutton
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      
                      // Prüfen, ob die AGB akzeptiert wurden
                      if (!viewModel.hasAcceptedTerms) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bitte akzeptieren Sie die Allgemeinen Geschäftsbedingungen'),
                          ),
                        );
                        return;
                      }
                      
                      // Erstelle TroubleReport-Objekt zur Übergabe
                      final report = TroubleReport(
                        id: const Uuid().v4(),
                        type: viewModel.type,
                        name: viewModel.name ?? '',
                        email: viewModel.email ?? '',
                        phone: viewModel.phone,
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
                      
                      widget.onSubmit(report);
                    }
                  },
            child: const Text('Störungsmeldung absenden'),
          ),
        ],
      ),
    );
  }
}