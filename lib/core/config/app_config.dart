class AppConfig {
  static const bool isDevelopment = true;
  
  // SendGrid Konfiguration
  static const String sendGridApiKey = String.fromEnvironment(
    'SENDGRID_API_KEY',
    defaultValue: 'IHR_SENDGRID_API_KEY_HIER',
  );
  
  static const String targetEmail = String.fromEnvironment(
    'TARGET_EMAIL',
    defaultValue: 'empfaenger@email.com',
  );

  // Absender-E-Mail (muss bei SendGrid verifiziert sein)
  static const String senderEmail = 'absender@ihre-domain.com';
} 