class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Bitte geben Sie $fieldName ein';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bitte geben Sie eine E-Mail-Adresse ein';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Telefon ist optional
    }
    
    final phoneRegex = RegExp(r'^\+?[0-9\s-]{6,}$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'Bitte geben Sie eine gültige Telefonnummer ein';
    }
    
    return null;
  }
} 