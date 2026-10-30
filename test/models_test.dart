import 'package:app_quan_ly_sinh_vien/models/app_user.dart';
import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_data.dart';

void main() {
  test('All five models round-trip with document IDs separate from data', () {
    final user = AppUser(
      uid: 'uid-1',
      email: 'manager@example.com',
      displayName: 'Quản lý Mẫu',
    );
    expect(AppUser.fromMap(user.uid, user.toMap()).displayName, 'Quản lý Mẫu');
    final room = ClassRoom(
      id: 'CNTT01',
      name: 'CNTT 01',
      major: 'CNTT',
      cohort: 'K17',
    );
    expect(ClassRoom.fromMap(room.id, room.toMap()).cohort, 'K17');
    final student = sampleStudent(classId: room.id, email: 'student@example.com');
    final restored = Student.fromMap(student.studentId, student.toMap());
    expect(restored.studentId, student.studentId);
    expect(restored.classId, room.id);
    expect(restored.name, student.name);
    expect(student.toMap().containsKey('id'), false);
    final subject = Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3);
    expect(Subject.fromMap(subject.id, subject.toMap()).credits, 3);
    final grade = Grade(
      studentId: student.studentId,
      subjectId: subject.id,
      semester: '2026-1',
      score: 8.5,
    );
    expect(Grade.fromMap(grade.id, grade.toMap()).score, 8.5);
  });

  test('Student rejects invalid values before creating a document', () {
    expect(() => sampleStudent(age: -1), throwsFormatException);
    expect(() => sampleStudent(studentId: 'invalid/id'), throwsFormatException);
    expect(() => sampleStudent(name: '   '), throwsFormatException);
    final original = sampleStudent(name: 'Sinh viên mẫu', classId: 'CNTT01');
    final restored = Student.fromMap(original.studentId, original.toMap());
    expect(restored.name, original.name);
    expect(restored.classId, original.classId);
  });

  test('Models reject malformed or incomplete Firestore documents', () {
    expect(() => Student.fromMap('SV1', {'name': 'A'}), throwsFormatException);
    expect(
      () => ClassRoom(id: 'bad/id', name: 'A', major: 'CNTT', cohort: 'K17'),
      throwsFormatException,
    );
    expect(
      () => Subject(id: 'S1', name: 'A', credits: 0),
      throwsFormatException,
    );
    expect(
      () => Subject(id: 'S1', name: '   ', credits: 3),
      throwsFormatException,
    );
    expect(
      () => AppUser(uid: 'u1', email: 'invalid', displayName: 'A'),
      throwsFormatException,
    );
    expect(() => sampleStudent(classId: ''), throwsFormatException);
  });

  group('US06/US07 - student field limits', () {
    test('age accepts 1 and 120 and rejects 0, 121 and negatives', () {
      expect(sampleStudent(age: 1).age, 1);
      expect(sampleStudent(age: 120).age, 120);
      for (final age in [0, 121, -1]) {
        expect(() => sampleStudent(age: age), throwsFormatException);
      }
    });

    test('name and major accept 150 characters and reject 151', () {
      expect(sampleStudent(name: 'a' * 150).name.length, 150);
      expect(sampleStudent(major: 'a' * 150).major.length, 150);
      expect(() => sampleStudent(name: 'a' * 151), throwsFormatException);
      expect(() => sampleStudent(major: 'a' * 151), throwsFormatException);
      expect(() => sampleStudent(major: ''), throwsFormatException);
    });

    test('email may be empty, otherwise it must look like an address', () {
      expect(sampleStudent(email: '').email, '');
      expect(sampleStudent(email: 'sv001@example.com').email, 'sv001@example.com');
      for (final email in [
        'khong-hop-le',
        'a@b',
        'a b@c.com',
        '@c.com',
        '${'a' * 250}@b.co',
      ]) {
        expect(
          () => sampleStudent(email: email),
          throwsFormatException,
          reason: email,
        );
      }
    });

    test('student ID allows 1-80 safe characters only', () {
      expect(sampleStudent(studentId: 'a' * 80).studentId.length, 80);
      expect(sampleStudent(studentId: 'SV_1-x').studentId, 'SV_1-x');
      for (final id in ['', 'a' * 81, 'SV 1', 'SV~1', 'SV/1', 'SV.1']) {
        expect(
          () => sampleStudent(studentId: id),
          throwsFormatException,
          reason: id,
        );
      }
    });

    test('a stored document with a text age or a missing field is refused', () {
      final map = sampleStudent(studentId: 'SV1').toMap();
      expect(
        () => Student.fromMap('SV1', {...map, 'age': '21'}),
        throwsFormatException,
      );
      expect(
        () => Student.fromMap('SV1', {...map, 'age': 21.5}),
        throwsFormatException,
      );
      expect(
        () => Student.fromMap('SV1', {...map}..remove('email')),
        throwsFormatException,
      );
    });

    test('editing builds a new object and never changes the ID', () {
      final old = sampleStudent(studentId: 'SV1', name: 'Tên cũ', age: 20);
      final edited = sampleStudent(studentId: old.studentId, name: 'Tên mới', age: 21);
      expect(old.name, 'Tên cũ');
      expect(edited.studentId, old.studentId);
      expect(edited.toMap().containsKey('studentId'), false);
    });
  });

  for (final score in [-0.1, 10.1, double.nan, double.infinity]) {
    test('Grade rejects score $score', () {
      expect(
        () => Grade(
          studentId: 'SV1',
          subjectId: 'M1',
          semester: '2026-1',
          score: score,
        ),
        throwsFormatException,
      );
    });
  }
  test('Grade allows both boundaries and rejects mismatched document IDs', () {
    for (final score in [0.0, 10.0]) {
      final grade = Grade(
        studentId: 'SV1',
        subjectId: 'M1',
        semester: '2026-1',
        score: score,
      );
      expect(Grade.fromMap(grade.id, grade.toMap()).score, score);
      expect(
        () => Grade.fromMap('wrong', grade.toMap()),
        throwsFormatException,
      );
    }
  });
}
