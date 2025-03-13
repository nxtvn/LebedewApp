import 'dart:io';

/// Hilfsmethoden für plattformspezifische Funktionen
class PlatformHelper {
  /// Prüft, ob die App auf iOS läuft
  static bool isIOS() {
    return Platform.isIOS;
  }
  
  /// Prüft, ob die App auf Android läuft
  static bool isAndroid() {
    return Platform.isAndroid;
  }
  
  /// Erstellt das passende Widget für die aktuelle Plattform
  static T platformWidget<T>({
    required T Function() iosBuilder,
    required T Function() androidBuilder,
  }) {
    if (isIOS()) {
      return iosBuilder();
    } else {
      return androidBuilder();
    }
  }
} 