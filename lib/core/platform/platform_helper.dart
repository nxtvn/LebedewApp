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
} 