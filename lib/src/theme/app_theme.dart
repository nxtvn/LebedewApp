import 'package:flutter/material.dart';
import 'package:lebedew_app/src/constants/design_constants.dart';

class AppTheme {
  static InputDecoration get inputDecoration => InputDecoration(
    contentPadding: const EdgeInsets.all(DesignConstants.defaultPadding),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    filled: true,
    fillColor: Colors.grey[50],
  );

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(DesignConstants.minButtonHeight),
    padding: const EdgeInsets.all(DesignConstants.defaultPadding),
    textStyle: const TextStyle(fontSize: DesignConstants.minTextSize),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
} 