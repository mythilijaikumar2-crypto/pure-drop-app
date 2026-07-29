class AppValidators {
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{10,12}$').hasMatch(cleanPhone)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final numValue = double.tryParse(value);
    if (numValue == null || numValue < 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  static String? integer(String? value, {String fieldName = 'Quantity'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0) {
      return 'Enter a valid whole number';
    }
    return null;
  }
}
