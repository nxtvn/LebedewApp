import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/platform/platform_helper.dart';
import '../viewmodels/trouble_report_viewmodel.dart';
import 'trouble_report_form_android.dart';
import 'trouble_report_form_ios.dart';

class TroubleReportForm extends StatelessWidget {
  const TroubleReportForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformHelper.platformWidget(
      iosBuilder: () => const TroubleReportFormIOS(),
      androidBuilder: () => const TroubleReportFormAndroid(),
    );
  }
} 