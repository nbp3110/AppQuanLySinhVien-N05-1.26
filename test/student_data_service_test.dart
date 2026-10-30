import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/services/student_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await data.createStudent(Student(classId: 'CNTT01'));
    await data.subjects.create(
      Subject(id: 'MOB01', name: 'Di động', credits: 3),
    );
  }

  test('Duplicate insertion does not overwrite existing data', () async {
    await seed();
    await expectLater(
      data.createStudent(Student(name: 'Không được ghi đè')),
      throwsStateError,
    );
    expect((await data.students.getById('23016960'))!.name, 'Nguyen Van Bac');
    await expectLater(
      data.classes.create(
        ClassRoom(id: 'CNTT01', name: 'Khác', major: 'CNTT', cohort: 'K17'),
      ),
      throwsStateError,
    );
  });
  test('Missing references fail before student/grade writes', () async {
    await expectLater(
      data.createStudent(Student(classId: 'MISSING')),
      throwsStateError,
    );
    expect(await data.students.getById('23016960'), isNull);
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
            studentId: '23016960',
            subjectId: 'MOB01',
            semester: '2026-1',
            score: score,
          ),
        );
      }
      expect((await firestore.collection('grades').get()).docs.length, 1);
      expect(
        (await data.watchGradesForStudent('23016960').first).single.score,
        9,
      );
    },
  );
  test('Update, typed snapshots and class filtering work', () async {
    await seed();
    await data.createStudent(Student(studentId: 'SV2'));
    final student = (await data.students.getById('23016960'))!;
    await data.students.update(
      Student(
        studentId: student.studentId,
        name: 'Nguyễn Văn Bắc',
        major: student.major,
        age: student.age,
        email: student.email,
        classId: student.classId,
      ),
    );
    expect((await data.students.getById('23016960'))!.name, 'Nguyễn Văn Bắc');
    expect(
      (await data.watchStudentsInClass('CNTT01').first).single.studentId,
      '23016960',
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
      expect(await idsIn('CNTT01'), ['23016960']);
      expect(await idsIn('KT01'), isEmpty);
      await data.updateStudent(Student(classId: 'KT01'));
      expect(await idsIn('CNTT01'), isEmpty);
      expect(await idsIn('KT01'), ['23016960']);
    });

    test('removing the class leaves the student without a class', () async {
      await withSecondClass();
      await data.updateStudent(Student());
      expect(await idsIn('CNTT01'), isEmpty);
      expect(await idsIn('KT01'), isEmpty);
      expect((await data.students.getById('23016960'))!.classId, isNull);
    });

    test('a failed class change keeps the previous class', () async {
      await withSecondClass();
      await expectLater(
        data.updateStudent(Student(classId: 'NOCLASS')),
        throwsStateError,
      );
      expect(await idsIn('CNTT01'), ['23016960']);
    });

    test('editing keeps one record and never changes the ID', () async {
      await withSecondClass();
      await data.updateStudent(Student(name: 'Tên đã sửa', classId: 'CNTT01'));
      final all = await data.students.watchAll().first;
      expect(all.length, 1);
      expect(all.single.studentId, '23016960');
      expect(all.single.name, 'Tên đã sửa');
    });
  });

  group('US08 - grade counter and safe deletion', () {
    Future<Map<String, dynamic>> rawStudent(String id) async =>
        (await firestore.collection('students').doc(id).get()).data()!;
    Future<Object?> counter(String id) async =>
        (await rawStudent(id))[StudentDataService.gradeCountField];
    Grade grade(String semester, double score) => Grade(
      studentId: '23016960',
      subjectId: 'MOB01',
      semester: semester,
      score: score,
    );

    test('a new student starts with a zero counter', () async {
      await seed();
      expect(await counter('23016960'), 0);
    });

    test('saveGrade raises the counter once per new grade only', () async {
      await seed();
      await data.saveGrade(grade('2026-1', 8));
      expect(await counter('23016960'), 1);
      await data.saveGrade(grade('2026-1', 9));
      expect(await counter('23016960'), 1);
      await data.saveGrade(grade('2026-2', 7));
      expect(await counter('23016960'), 2);
      expect((await firestore.collection('grades').get()).docs.length, 2);
    });

    test('a refused grade does not change any counter', () async {
      await seed();
      await expectLater(
        data.saveGrade(
          Grade(
            studentId: '23016960',
            subjectId: 'MISSING',
            semester: '2026-1',
            score: 8,
          ),
        ),
        throwsStateError,
      );
      expect(await counter('23016960'), 0);
      expect((await firestore.collection('grades').get()).docs, isEmpty);
    });

    test('profile edits keep the counter and the other fields', () async {
      await seed();
      await data.saveGrade(grade('2026-1', 8));
      await data.updateStudent(
        Student(
          studentId: '23016960',
          name: 'Tên mới',
          major: 'Kế toán',
          age: 22,
          email: 'moi@example.com',
        ),
      );
      final saved = await rawStudent('23016960');
      expect(saved['name'], 'Tên mới');
      expect(saved['classId'], isNull);
      expect(saved[StudentDataService.gradeCountField], 1);
    });

    test('updateStudent refuses a missing student or class', () async {
      await seed();
      await expectLater(
        data.updateStudent(Student(studentId: 'NOBODY')),
        throwsStateError,
      );
      expect(await data.students.getById('NOBODY'), isNull);
      await expectLater(
        data.updateStudent(Student(classId: 'MISSING')),
        throwsStateError,
      );
      expect((await data.students.getById('23016960'))!.classId, 'CNTT01');
    });

    test('a student without grades can be deleted', () async {
      await seed();
      await data.deleteStudent('23016960');
      expect(await data.students.getById('23016960'), isNull);
    });

    test('a student with grades is kept', () async {
      await seed();
      await data.saveGrade(grade('2026-1', 8));
      await expectLater(data.deleteStudent('23016960'), throwsStateError);
      expect(await data.students.getById('23016960'), isNotNull);
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
