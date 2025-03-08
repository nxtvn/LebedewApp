import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// LoadingIndicator Widget zur plattformspezifischen Anzeige eines Ladeindikators
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoIndicator() : _buildMaterialIndicator();
  }

  /// Cupertino Ladeindikator für iOS
  Widget _buildCupertinoIndicator() {
    return const Center(
      child: CupertinoActivityIndicator(radius: 16),
    );
  }

  /// Material Ladeindikator für Android
  Widget _buildMaterialIndicator() {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Wird geladen...'),
            ],
          ),
        ),
      ),
    );
  }
} 