import 'package:flutter/material.dart';
import '../../core/platform/platform_helper.dart';
import '../android/login_screen_android.dart';
import '../ios/login_screen_ios.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformHelper.platformWidget(
      iosBuilder: () => const LoginScreenIOS(),
      androidBuilder: () => const LoginScreenAndroid(),
    );
  }
} 