import 'package:flutter/material.dart';
import '../../domain/entities/trouble_report.dart';
import '../../../domain/enums/request_type.dart';
import '../../../domain/enums/urgency_level.dart';

class TroubleReportFormAndroid extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(TroubleReport) onSubmit;

  const TroubleReportFormAndroid({
    super.key,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  State<TroubleReportFormAndroid> createState() => _TroubleReportFormAndroidState();
}

class _TroubleReportFormAndroidState extends State<TroubleReportFormAndroid> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  RequestType? _selectedType;
  UrgencyLevel? _selectedUrgency;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
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
              labelText: 'E-Mail',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihre E-Mail-Adresse ein';
              }
              // E-Mail-Validierung mit RegExp
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                // Telefonnummer-Validierung mit RegExp (erlaubt verschiedene Formate)
                final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$');
                if (!phoneRegex.hasMatch(value)) {
                  return 'Bitte geben Sie eine gültige Telefonnummer ein';
                }
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihre Adresse ein';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Beschreibung',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte beschreiben Sie Ihr Problem';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Absenden'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (widget.formKey.currentState?.validate() ?? false) {
      final troubleReport = TroubleReport(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        description: _descriptionController.text,
        type: _selectedType ?? RequestType.other,
        urgencyLevel: _selectedUrgency ?? UrgencyLevel.medium,
      );
      widget.onSubmit(troubleReport);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}