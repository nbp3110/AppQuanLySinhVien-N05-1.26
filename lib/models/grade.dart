import 'model_validation.dart';

/// Điểm một sinh viên ở một môn trong một học kỳ (collection `grades`).
/// ID document = `studentId~subjectId~semester` nên nhập lại chỉ cập nhật một bản ghi.
/// Học kỳ phải dạng YYYY-1 hoặc YYYY-2, điểm từ 0 đến 10.
class Grade {
  final String studentId;
  final String subjectId;
  final String semester;
  final double score;

  Grade({
    required this.studentId,
    required this.subjectId,
    required this.semester,
    required this.score,
  }) {
    ModelValidation.id(studentId, 'Mã sinh viên');
    ModelValidation.id(subjectId, 'Mã môn');
    ModelValidation.semester(semester);
    if (!score.isFinite || score < 0 || score > 10) {
      throw const FormatException('Điểm phải từ 0 đến 10.');
    }
  }

  // Components cannot contain ~, so the key cannot collide across tuples.
  String get id => '$studentId~$subjectId~$semester';

  factory Grade.fromMap(String id, Map<String, dynamic> data) {
    final score = data['score'];
    if (score is! num) throw const FormatException('Điểm phải là số.');
    final grade = Grade(
      studentId: ModelValidation.string(data, 'studentId'),
      subjectId: ModelValidation.string(data, 'subjectId'),
      semester: ModelValidation.string(data, 'semester'),
      score: score.toDouble(),
    );
    if (id != grade.id) {
      throw const FormatException('Mã bản ghi điểm không khớp.');
    }
    return grade;
  }

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'subjectId': subjectId,
    'semester': semester,
    'score': score,
  };
}
