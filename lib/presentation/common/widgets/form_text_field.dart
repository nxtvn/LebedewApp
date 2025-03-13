import 'package:flutter/material.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/theme/app_theme.dart';

class FormTextField extends StatefulWidget {
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
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignConstants.defaultRadius),
        boxShadow: _focusNode.hasFocus
            ? [BoxShadow(color: Colors.blue.withAlpha(DesignConstants.lowOpacityAlpha), blurRadius: 10)]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: AppTheme.inputDecoration.copyWith(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon),
        ),
        style: const TextStyle(fontSize: DesignConstants.minTextSize),
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        onSaved: widget.onSaved,
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
} 