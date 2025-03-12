import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class PlatformHelper {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  
  static T platformWidget<T>({
    required T Function() androidBuilder,
    required T Function() iosBuilder,
  }) {
    return isIOS ? iosBuilder() : androidBuilder();
  }
} 