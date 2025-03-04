class Validators {
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Bitte geben Sie Ihre E-Mail ein';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value!)) {
      return 'Bitte geben Sie eine gültige E-Mail ein';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value?.isEmpty ?? true) {
      return 'Bitte geben Sie $fieldName ein';
    }
    return null;
  }
} 