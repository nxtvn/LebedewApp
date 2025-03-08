import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:lebedew_app/src/constants/design_constants.dart';

/// FormSection Widget zur plattformspezifischen Darstellung von Formularabschnitten
class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FormSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoFormSection() : _buildMaterialFormSection(context);
  }

  /// Cupertino FormSection für iOS
  Widget _buildCupertinoFormSection() {
    return CupertinoFormSection(
      header: Text(title),
      children: children,
    );
  }

  /// Material FormSection für Android
  Widget _buildMaterialFormSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignConstants.defaultPadding),
            ...children,
          ],
        ),
      ),
    );
  }
} 