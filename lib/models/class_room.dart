import 'model_validation.dart';

/// Lớp học (collection `classes`): mã lớp, tên, ngành, khóa. Mã lớp là ID document và không đổi khi sửa.
class ClassRoom {
  final String id;
  final String name;
  final String major;
  final String cohort;

  ClassRoom({
    required this.id,
    required this.name,
    required this.major,
    required this.cohort,
  }) {
    ModelValidation.id(id, 'Mã lớp');
    ModelValidation.text(name, 'Tên lớp');
    ModelValidation.text(major, 'Ngành');
    ModelValidation.text(cohort, 'Khóa học', max: 30);
  }

  factory ClassRoom.fromMap(String id, Map<String, dynamic> data) => ClassRoom(
    id: id,
    name: ModelValidation.string(data, 'name'),
    major: ModelValidation.string(data, 'major'),
    cohort: ModelValidation.string(data, 'cohort'),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'major': major,
    'cohort': cohort,
  };
}
