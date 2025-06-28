class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    
    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    
    if (value.length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    
    if (value.length > 50) {
      return 'الاسم يجب أن يكون أقل من 50 حرف';
    }
    
    // Check if name contains only letters and spaces
    final nameRegex = RegExp(r'^[a-zA-Zأ-ي\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'الاسم يجب أن يحتوي على أحرف فقط';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    
    // Remove any non-digit characters
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length < 10) {
      return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
    }
    
    if (cleanPhone.length > 15) {
      return 'رقم الهاتف يجب أن يكون أقل من 15 رقم';
    }
    
    // Check if phone starts with valid country/area codes
    final phoneRegex = RegExp(r'^(05|009665|9665|\+9665)[0-9]{8,12}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'يرجى إدخال رقم هاتف صحيح';
    }
    
    return null;
  }

  // Student name validation
  static String? validateStudentName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال اسم الطالب';
    }
    
    if (value.length < 2) {
      return 'اسم الطالب يجب أن يكون حرفين على الأقل';
    }
    
    if (value.length > 50) {
      return 'اسم الطالب يجب أن يكون أقل من 50 حرف';
    }
    
    return null;
  }

  // Grade validation
  static String? validateGrade(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الصف الدراسي';
    }
    
    if (value.length > 20) {
      return 'الصف الدراسي يجب أن يكون أقل من 20 حرف';
    }
    
    return null;
  }

  // School name validation
  static String? validateSchoolName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال اسم المدرسة';
    }
    
    if (value.length < 3) {
      return 'اسم المدرسة يجب أن يكون 3 أحرف على الأقل';
    }
    
    if (value.length > 100) {
      return 'اسم المدرسة يجب أن يكون أقل من 100 حرف';
    }
    
    return null;
  }

  // Bus route validation
  static String? validateBusRoute(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال خط الباص';
    }
    
    if (value.length > 50) {
      return 'خط الباص يجب أن يكون أقل من 50 حرف';
    }
    
    return null;
  }

  // QR Code validation
  static String? validateQRCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'رمز QR غير صحيح';
    }
    
    if (value.length < 10) {
      return 'رمز QR قصير جداً';
    }
    
    if (value.length > 100) {
      return 'رمز QR طويل جداً';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    if (value.length < minLength) {
      return '$fieldName يجب أن يكون $minLength أحرف على الأقل';
    }
    
    return null;
  }

  // Maximum length validation
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName يجب أن يكون أقل من $maxLength حرف';
    }
    
    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    final numericRegex = RegExp(r'^[0-9]+$');
    if (!numericRegex.hasMatch(value)) {
      return '$fieldName يجب أن يحتوي على أرقام فقط';
    }
    
    return null;
  }

  // Arabic text validation
  static String? validateArabicText(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    final arabicRegex = RegExp(r'^[أ-ي\s]+$');
    if (!arabicRegex.hasMatch(value)) {
      return '$fieldName يجب أن يحتوي على أحرف عربية فقط';
    }
    
    return null;
  }

  // English text validation
  static String? validateEnglishText(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    
    final englishRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!englishRegex.hasMatch(value)) {
      return '$fieldName يجب أن يحتوي على أحرف إنجليزية فقط';
    }
    
    return null;
  }

  // URL validation
  static String? validateURL(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الرابط';
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'يرجى إدخال رابط صحيح';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال التاريخ';
    }
    
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'تاريخ غير صحيح';
    }
  }

  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال العمر';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'العمر يجب أن يكون رقم';
    }
    
    if (age < 3 || age > 18) {
      return 'العمر يجب أن يكون بين 3 و 18 سنة';
    }
    
    return null;
  }
}
