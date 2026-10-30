import 'package:app_quan_ly_sinh_vien/models/student.dart';

/// Fictitious student for tests. The Student model itself has no defaults, so
/// tests state only the fields they care about and get neutral sample values.
Student sampleStudent({
  String studentId = 'SV001',
  String name = 'Sinh viên Mẫu',
  String major = 'Công nghệ thông tin',
  int age = 21,
  String? classId,
  String email = '',
}) => Student(
  studentId: studentId,
  name: name,
  major: major,
  age: age,
  classId: classId,
  email: email,
);
