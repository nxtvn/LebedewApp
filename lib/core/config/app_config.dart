import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum Environment { development, production }

class AppConfig {
  static late final Environment _environment;
  static final _secureStorage = FlutterSecureStorage();
  
  static Future<void> initialize(Environment env) async {
    _environment = env;
    // Load initial configuration
  }
  
  // Safe access to credentials
  static Future<String> getApiKey(String keyName) async {
    return await _secureStorage.read(key: keyName) ?? '';
  }
  
  // App settings
  static bool get isDevelopment => _environment == Environment.development;
  static String get apiBaseUrl => isDevelopment 
    ? 'https://dev-api.lebedew.de' 
    : 'https://api.lebedew.de';
    
  // Email configuration getters
  static Future<String> get mailjetApiKey => getApiKey('mailjet_api_key');
  static Future<String> get mailjetSecretKey => getApiKey('mailjet_secret_key');
  static Future<String> get serviceEmail => getApiKey('service_email');
  static Future<String> get senderEmail => getApiKey('sender_email');
  static Future<String> get senderName => getApiKey('sender_name');
} 