import 'package:flutter/material.dart';
import '../../domain/entities/trouble_report.dart';

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
              // TODO: Add email validation logic
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
              if (value == null || value.isEmpty) {
                return 'Bitte geben Sie Ihre Telefonnummer ein';
              }
              // TODO: Add phone number validation logic
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
        type: RequestType.other, // TODO: Add type selection
        urgencyLevel: UrgencyLevel.normal, // TODO: Add urgency level selection
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