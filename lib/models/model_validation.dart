/// Shared validation for document data. Invalid input fails before a write.
class ModelValidation {
  static String id(String value, String field) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(value)) {
      throw FormatException(
        '$field chỉ gồm chữ không dấu, số, _ hoặc - (1–80 ký tự).',
      );
    }
    return value;
  }

  /// Semester in the form YYYY-1 or YYYY-2 (the same rule as the grade form
  /// and firestore.rules), for example 2026-1.
  static String semester(String value) {
    if (!RegExp(r'^\d{4}-[12]$').hasMatch(value)) {
      throw const FormatException('Học kỳ có dạng YYYY-1 hoặc YYYY-2.');
    }
    return value;
  }

  static String text(String value, String field, {int max = 150}) {
    if (value.trim().isEmpty || value.length > max) {
      throw FormatException('$field không được trống hoặc dài quá $max ký tự.');
    }
    return value;
  }

  static String string(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! String) throw FormatException('$field phải là chuỗi.');
    return value;
  }

  static int integer(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! int) throw FormatException('$field phải là số nguyên.');
    return value;
  }

  static String email(String value, {bool optional = false}) {
    if (optional && value.isEmpty) return value;
    if (value.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      throw const FormatException('Email không hợp lệ.');
    }
    return value;
  }
}
