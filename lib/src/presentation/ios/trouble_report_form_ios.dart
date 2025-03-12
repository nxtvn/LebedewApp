import 'package:flutter/cupertino.dart';
import '../../domain/entities/trouble_report.dart';

class TroubleReportFormIOS extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(TroubleReport) onSubmit;

  const TroubleReportFormIOS({
    super.key,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  State<TroubleReportFormIOS> createState() => _TroubleReportFormIOSState();
}

class _TroubleReportFormIOSState extends State<TroubleReportFormIOS> {
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
          CupertinoFormSection(
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
                    // TODO: Add email validation logic
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
                    // TODO: Add phone number validation logic
                    return null;
                  },
                ),
              ),
              CupertinoFormRow(
                prefix: const Text('Adresse'),
                child: CupertinoTextFormFieldRow(
                  controller: _addressController,
                  placeholder: 'Geben Sie Ihre Adresse ein',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie Ihre Adresse ein';
                    }
                    return null;
                  },
                ),
              ),
              CupertinoFormRow(
                prefix: const Text('Beschreibung'),
                child: CupertinoTextFormFieldRow(
                  controller: _descriptionController,
                  placeholder: 'Beschreiben Sie Ihr Problem',
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte beschreiben Sie Ihr Problem';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
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