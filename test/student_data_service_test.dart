import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/services/student_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_data.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late StudentDataService data;
  setUp(() {
    firestore = FakeFirebaseFirestore();
    data = StudentDataService(firestore);
  });
  Future<void> seed() async {
    await data.classes.create(
      ClassRoom(id: 'CNTT01', name: 'CNTT 01', major: 'CNTT', cohort: 'K17'),
    );
    await data.createStudent(sampleStudent(classId: 'CNTT01'));
    await data.subjects.create(
      Subject(id: 'MOB01', name: 'Di động', credits: 3),
    );
  }

  test('Duplicate insertion does not overwrite existing data', () async {
    await seed();
    await expectLater(
      data.createStudent(sampleStudent(name: 'Không được ghi đè')),
      throwsStateError,
    );
    expect((await data.students.getById('SV001'))!.name, 'Sinh viên Mẫu');
    await expectLater(
      data.classes.create(
        ClassRoom(id: 'CNTT01', name: 'Khác', major: 'CNTT', cohort: 'K17'),
      ),
      throwsStateError,
    );
  });
  test('Missing references fail before student/grade writes', () async {
    await expectLater(
      data.createStudent(sampleStudent(classId: 'MISSING')),
      throwsStateError,
    );
    expect(await data.students.getById('SV001'), isNull);
    await expectLater(
      data.saveGrade(
        Grade(studentId: 'SV1', subjectId: 'M1', semester: '2026-1', score: 8),
      ),
      throwsStateError,
    );
    expect((await firestore.collection('grades').get()).docs, isEmpty);
  });
  test(
    'Grade upsert preserves one record per student, subject and semester',
    () async {
      await seed();
      for (final score in [8.0, 9.0]) {
        await data.saveGrade(
          Grade(
            studentId: 'SV001',
            subjectId: 'MOB01',
            semester: '2026-1',
            score: score,
          ),
        );
      }
      expect((await firestore.collection('grades').get()).docs.length, 1);
      expect(
        (await data.watchGradesForStudent('SV001').first).single.score,
        9,
      );
    },
  );
  test('Update, typed snapshots and class filtering work', () async {
    await seed();
    await data.createStudent(sampleStudent(studentId: 'SV2'));
    final student = (await data.students.getById('SV001'))!;
    await data.students.update(
      sampleStudent(
        studentId: student.studentId,
        name: 'Nguyễn Văn A',
        major: student.major,
        age: student.age,
        email: student.email,
        classId: student.classId,
      ),
    );
    expect((await data.students.getById('SV001'))!.name, 'Nguyễn Văn A');
    expect(
      (await data.watchStudentsInClass('CNTT01').first).single.studentId,
      'SV001',
    );
    expect((await data.students.watchAll().first).length, 2);
    await expectLater(
      data.subjects.update(Subject(id: 'MISSING', name: 'A', credits: 3)),
      throwsA(anything),
    );
    expect(await data.subjects.getById('MISSING'), isNull);
  });

  group('US07 - editing a student and changing class', () {
    Future<void> withSecondClass() async {
      await seed();
      await data.classes.create(
        ClassRoom(
          id: 'KT01',
          name: 'Kế toán 01',
          major: 'Kế toán',
          cohort: 'K17',
        ),
      );
    }

    Future<List<String>> idsIn(String classId) async => (await data
            .watchStudentsInClass(classId)
            .first)
        .map((s) => s.studentId)
        .toList();

    test('moving a student updates both class lists', () async {
      await withSecondClass();
      expect(await idsIn('CNTT01'), ['SV001']);
      expect(await idsIn('KT01'), isEmpty);
      await data.updateStudent(sampleStudent(classId: 'KT01'));
      expect(await idsIn('CNTT01'), isEmpty);
      expect(await idsIn('KT01'), ['SV001']);
    });

    test('removing the class leaves the student without a class', () async {
      await withSecondClass();
      await data.updateStudent(sampleStudent());
      expect(await idsIn('CNTT01'), isEmpty);
      expect(await idsIn('KT01'), isEmpty);
      expect((await data.students.getById('SV001'))!.classId, isNull);
    });

    test('a failed class change keeps the previous class', () async {
      await withSecondClass();
      await expectLater(
        data.updateStudent(sampleStudent(classId: 'NOCLASS')),
        throwsStateError,
      );
      expect(await idsIn('CNTT01'), ['SV001']);
    });

    test('editing keeps one record and never changes the ID', () async {
      await withSecondClass();
      await data.updateStudent(sampleStudent(name: 'Tên đã sửa', classId: 'CNTT01'));
      final all = await data.students.watchAll().first;
      expect(all.length, 1);
      expect(all.single.studentId, 'SV001');
      expect(all.single.name, 'Tên đã sửa');
    });
  });

  group('US08 - grade counter and safe deletion', () {
    Future<Map<String, dynamic>> rawStudent(String id) async =>
        (await firestore.collection('students').doc(id).get()).data()!;
    Future<Object?> counter(String id) async =>
        (await rawStudent(id))[StudentDataService.gradeCountField];
    Grade grade(String semester, double score) => Grade(
      studentId: 'SV001',
      subjectId: 'MOB01',
      semester: semester,
      score: score,
    );

    test('a new student starts with a zero counter', () async {
      await seed();
      expect(await counter('SV001'), 0);
    });

    test('saveGrade raises the counter once per new grade only', () async {
      await seed();
      await data.saveGrade(grade('2026-1', 8));
      expect(await counter('SV001'), 1);
      await data.saveGrade(grade('2026-1', 9));
      expect(await counter('SV001'), 1);
      await data.saveGrade(grade('2026-2', 7));
      expect(await counter('SV001'), 2);
      expect((await firestore.collection('grades').get()).docs.length, 2);
    });

    test('a refused grade does not change any counter', () async {
      await seed();
      await expectLater(
        data.saveGrade(
          Grade(
            studentId: 'SV001',
            subjectId: 'MISSING',
            semester: '2026-1',
            score: 8,
          ),
        ),
        throwsStateError,
      );
      expect(await counter('SV001'), 0);
      expect((await firestore.collection('grades').get()).docs, isEmpty);
    });

    test('profile edits keep the counter and the other fields', () async {
      await seed();
      await data.saveGrade(grade('2026-1', 8));
      await data.updateStudent(
        sampleStudent(
          studentId: 'SV001',
          name: 'Tên mới',
          major: 'Kế toán',
          age: 22,
          email: 'moi@example.com',
        ),
      );
      final saved = await rawStudent('SV001');
      expect(saved['name'], 'Tên mới');
      expect(saved['classId'], isNull);
      expect(saved[StudentDataService.gradeCountField], 1);
    });

    test('updateStudent refuses a missing student or class', () async {
      await seed();
      await expectLater(
        data.updateStudent(sampleStudent(studentId: 'NOBODY')),
        throwsStateError,
      );
      expect(await data.students.getById('NOBODY'), isNull);
      await expectLater(
        data.updateStudent(sampleStudent(classId: 'MISSING')),
        throwsStateError,
      );
      expect((await data.students.getById('SV001'))!.classId, 'CNTT01');
    });

    test('a student without grades can be deleted', () async {
      await seed();
      await data.deleteStudent('SV001');
      expect(await data.students.getById('SV001'), isNull);
    });

    test('a student with grades is kept', () async {
      await seed();
      await data.saveGrade(grade('2026-1', 8));
      await expectLater(data.deleteStudent('SV001'), throwsStateError);
      expect(await data.students.getById('SV001'), isNotNull);
      expect((await firestore.collection('grades').get()).docs.length, 1);
    });

    test('unknown ids and documents without a counter are not deleted', () async {
      await seed();
      await expectLater(data.deleteStudent('NOBODY'), throwsStateError);
      await firestore.collection('students').doc('OLD').set({
        'name': 'Hồ sơ cũ',
        'major': 'CNTT',
        'age': 20,
        'classId': null,
        'email': '',
      });
      await expectLater(data.deleteStudent('OLD'), throwsStateError);
      expect((await firestore.collection('students').doc('OLD').get()).exists,
          true);
    });
  });
}
