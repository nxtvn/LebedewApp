import 'package:flutter/material.dart';
import 'package:lebedew_app/src/constants/design_constants.dart';
import 'package:lebedew_app/src/theme/app_theme.dart';

class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Function(String?)? onSaved;

  const FormTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines,
    this.onSaved,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: AppTheme.inputDecoration.copyWith(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      style: const TextStyle(fontSize: DesignConstants.minTextSize),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onSaved: onSaved,
    );
  }
} 