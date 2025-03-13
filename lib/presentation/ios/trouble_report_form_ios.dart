import 'package:flutter/cupertino.dart';
import '../../domain/entities/trouble_report.dart';
import '../../domain/enums/request_type.dart';
import '../../domain/enums/urgency_level.dart';
import '../common/widgets/trouble_report_form.dart';

class TroubleReportFormIOS extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(TroubleReport)? onSubmit;

  const TroubleReportFormIOS({
    super.key,
    required this.formKey,
    this.onSubmit,
  });

  @override
  State<TroubleReportFormIOS> createState() => _TroubleReportFormIOSState();
}

class _TroubleReportFormIOSState extends State<TroubleReportFormIOS> with TroubleReportFormResetMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void reset() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _descriptionController.clear();
  }

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
        type: RequestType.trouble,
        urgencyLevel: UrgencyLevel.medium,
      );
      
      if (widget.onSubmit != null) {
        widget.onSubmit!(troubleReport);
      }
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