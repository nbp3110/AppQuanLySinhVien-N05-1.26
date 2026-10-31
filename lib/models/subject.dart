import 'model_validation.dart';

/// Môn học (collection `subjects`): mã môn, tên, số tín chỉ nguyên từ 1 đến 10.
class Subject {
  final String id;
  final String name;
  final int credits;

  Subject({required this.id, required this.name, required this.credits}) {
    ModelValidation.id(id, 'Mã môn');
    ModelValidation.text(name, 'Tên môn');
    if (credits < 1 || credits > 10) {
      throw const FormatException('Số tín chỉ phải từ 1 đến 10.');
    }
  }

  factory Subject.fromMap(String id, Map<String, dynamic> data) => Subject(
    id: id,
    name: ModelValidation.string(data, 'name'),
    credits: ModelValidation.integer(data, 'credits'),
  );

  Map<String, dynamic> toMap() => {'name': name, 'credits': credits};
}
