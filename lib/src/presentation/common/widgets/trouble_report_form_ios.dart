import 'package:flutter/cupertino.dart';

class TroubleReportFormIOS extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const TroubleReportFormIOS({super.key, required this.formKey});

  @override
  State<TroubleReportFormIOS> createState() => TroubleReportFormIOSState();
}

class TroubleReportFormIOSState extends State<TroubleReportFormIOS> {
  void reset() {
    // TODO: Implement form reset logic
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TODO: Implement iOS-specific form fields
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: () {
              if (widget.formKey.currentState?.validate() ?? false) {
                // TODO: Handle form submission
              }
            },
            child: const Text('Absenden'),
          ),
        ],
      ),
    );
  }
} 