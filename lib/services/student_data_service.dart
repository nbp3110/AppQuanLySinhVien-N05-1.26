import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/class_room.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import 'firestore_repository.dart';

/// One shared entry point for all four members. Inject Firestore in tests.
/// References are checked again by Firestore rules on the server.
class StudentDataService {
  final FirebaseFirestore firestore;
  late final users = FirestoreRepository<AppUser>(
    firestore: firestore,
    path: 'users',
    decode: AppUser.fromMap,
    encode: (user) => user.toMap(),
    idOf: (user) => user.uid,
  );
  late final students = FirestoreRepository<Student>(
    firestore: firestore,
    path: 'students',
    decode: Student.fromMap,
    encode: (student) => student.toMap(),
    idOf: (student) => student.studentId,
  );
  late final classes = FirestoreRepository<ClassRoom>(
    firestore: firestore,
    path: 'classes',
    decode: ClassRoom.fromMap,
    encode: (room) => room.toMap(),
    idOf: (room) => room.id,
  );
  late final subjects = FirestoreRepository<Subject>(
    firestore: firestore,
    path: 'subjects',
    decode: Subject.fromMap,
    encode: (subject) => subject.toMap(),
    idOf: (subject) => subject.id,
  );
  late final grades = FirestoreRepository<Grade>(
    firestore: firestore,
    path: 'grades',
    decode: Grade.fromMap,
    encode: (grade) => grade.toMap(),
    idOf: (grade) => grade.id,
  );

  StudentDataService(this.firestore);

  /// Counts the grades of a student. It lives only in the Firestore document
  /// (not in [Student]) and is changed in the same transaction that creates a
  /// grade, so the rules can refuse to delete a student that already has grades.
  static const gradeCountField = 'gradeCount';

  DocumentReference<Map<String, dynamic>> _studentDoc(String studentId) =>
      firestore.collection('students').doc(studentId);

  Stream<List<Student>> watchStudentsInClass(String classId) => students
      .collection
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Stream<List<Grade>> watchGradesForStudent(String studentId) => grades
      .collection
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Future<void> createStudent(Student student) async {
    student.validate();
    final ref = _studentDoc(student.studentId);
    await firestore.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) {
        throw StateError('Mã sinh viên đã tồn tại.');
      }
      if (student.classId != null &&
          !(await transaction.get(classes.collection.doc(student.classId)))
              .exists) {
        throw StateError('Lớp học không tồn tại.');
      }
      transaction.set(ref, {...student.toMap(), gradeCountField: 0});
    });
  }

  /// Edits the profile fields only. The grade counter is never sent, so an
  /// outdated copy of the student cannot overwrite it.
  Future<void> updateStudent(Student student) async {
    student.validate();
    final ref = _studentDoc(student.studentId);
    await firestore.runTransaction((transaction) async {
      if (!(await transaction.get(ref)).exists) {
        throw StateError('Sinh viên không còn tồn tại.');
      }
      if (student.classId != null &&
          !(await transaction.get(classes.collection.doc(student.classId)))
              .exists) {
        throw StateError('Lớp học không tồn tại.');
      }
      transaction.update(ref, student.toMap());
    });
  }

  /// Deletes a student only while the grade counter is zero. Reading and
  /// deleting happen in one transaction, and the rules check the counter again,
  /// so a grade created at the same moment cannot be orphaned.
  Future<void> deleteStudent(String studentId) async {
    final ref = _studentDoc(studentId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw StateError('Sinh viên không còn tồn tại.');
      }
      final count = snapshot.data()?[gradeCountField];
      if (count is! int) {
        throw StateError(
          'Hồ sơ này chưa có bộ đếm điểm nên chưa thể xóa an toàn.',
        );
      }
      if (count > 0) {
        throw StateError('Sinh viên đã có điểm. Không thể xóa hồ sơ.');
      }
      transaction.delete(ref);
    });
  }

  Future<void> saveGrade(Grade grade) async {
    final studentRef = _studentDoc(grade.studentId);
    final gradeRef = grades.collection.doc(grade.id);
    await firestore.runTransaction((transaction) async {
      final student = await transaction.get(studentRef);
      final subject = await transaction.get(
        subjects.collection.doc(grade.subjectId),
      );
      final existing = await transaction.get(
        firestore.collection('grades').doc(grade.id),
      );
      if (!student.exists || !subject.exists) {
        throw StateError('Sinh viên hoặc môn học không tồn tại.');
      }
      if (!existing.exists) {
        // A new grade raises the counter by exactly one in the same commit.
        final count = student.data()?[gradeCountField];
        transaction.update(studentRef, {
          gradeCountField: (count is int ? count : 0) + 1,
        });
      }
      transaction.set(gradeRef, grade);
    });
  }
}
