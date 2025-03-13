import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../common/viewmodels/trouble_report_viewmodel.dart';
import '../common/widgets/trouble_report_form_android.dart';
import '../common/widgets/trouble_report_form_ios.dart';
import '../../core/platform/platform_helper.dart';

class CreateTroubleReportPage extends StatelessWidget {
  const CreateTroubleReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<TroubleReportViewModel>(context, listen: false);
    
    if (PlatformHelper.isIOS()) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Störungsmeldung erstellen'),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TroubleReportFormIOS(
              formKey: GlobalKey<FormState>(),
              onSubmit: (report) async {
                await viewModel.submitReport();
              },
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Störungsmeldung erstellen'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TroubleReportFormAndroid(
            formKey: GlobalKey<FormState>(),
            onSubmit: (report) async {
              await viewModel.submitReport();
            },
          ),
        ),
      );
    }
  }
} 