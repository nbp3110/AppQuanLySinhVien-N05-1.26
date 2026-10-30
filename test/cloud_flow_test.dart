import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/services/auth_service.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:app_quan_ly_sinh_vien/services/student_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_firebase_auth.dart';
import 'support/sample_data.dart';

/// G4-01: one full session on the "cloud" code path (ProjectStore.cloud with a
/// fake Firestore and a fake Auth). It does not replace testing on Android with
/// the real Firebase project.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;
  late StudentDataService data;
  late FakeFirebaseAuth auth;
  late AuthService authService;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    data = StudentDataService(firestore);
    auth = FakeFirebaseAuth();
    authService = AuthService(auth: auth, data: data);
    // The project owner provisions the manager profile.
    await firestore.collection('users').doc('manager-1').set({
      'email': 'manager@example.com',
      'displayName': 'Quản lý thử',
      'role': 'manager',
    });
  });

  Future<ProjectStore> signInAndOpen() async {
    final profile = await authService.signIn(
      email: 'manager@example.com',
      password: 'secret',
    );
    final store = ProjectStore.cloud(data, authService, profile);
    addTearDown(store.dispose);
    await store.initialize();
    await pumpEventQueue();
    return store;
  }

  test('sign in, class, student, subject, grade, blocked delete, sign out', () async {
    final store = await signInAndOpen();
    expect(store.loading, false);
    expect(store.error, isNull);
    expect(store.profile.displayName, 'Quản lý thử');
    expect(store.students, isEmpty);

    await store.saveClass(
      ClassRoom(id: 'CNTT01', name: 'CNTT 01', major: 'CNTT', cohort: 'K17'),
    );
    await store.saveSubject(Subject(id: 'MOB01', name: 'Di động', credits: 3));
    await pumpEventQueue();
    expect(store.classes.map((v) => v.id), ['CNTT01']);
    expect(store.subjects.map((v) => v.id), ['MOB01']);

    await store.saveStudent(
      sampleStudent(studentId: 'SV1', name: 'Sinh viên Một', classId: 'CNTT01'),
    );
    await pumpEventQueue();
    expect(store.students.map((v) => v.studentId), ['SV1']);
    expect(store.className('CNTT01'), 'CNTT 01');

    // A student without grades could still be deleted, so it is checked first
    // with a second student.
    await store.saveStudent(sampleStudent(studentId: 'SV2', name: 'Sinh viên Hai'));
    await pumpEventQueue();
    await store.deleteStudent('SV2');
    await pumpEventQueue();
    expect(store.students.map((v) => v.studentId), ['SV1']);

    await store.saveGrade(
      Grade(
        studentId: 'SV1',
        subjectId: 'MOB01',
        semester: '2026-1',
        score: 8.5,
      ),
    );
    await pumpEventQueue();
    expect(store.grades.single.score, 8.5);
    expect((await data.watchGradesForStudent('SV1').first).single.score, 8.5);

    await expectLater(store.deleteStudent('SV1'), throwsStateError);
    expect(
      (await firestore.collection('students').doc('SV1').get()).exists,
      true,
    );

    await store.updateName('  Tên mới  ');
    expect(store.profile.displayName, 'Tên mới');
    expect(
      (await firestore.collection('users').doc('manager-1').get())
          .data()!['displayName'],
      'Tên mới',
    );

    await store.signOut();
    expect(auth.signOutCalls, 1);
    expect(store.students, isEmpty);
    expect(store.grades, isEmpty);

    // Data written by someone else after sign out must not reach this store.
    await data.createStudent(sampleStudent(studentId: 'LATE'));
    await pumpEventQueue();
    expect(store.students, isEmpty);
    expect(store.error, isNull);
  });

  test('a second session sees the data saved by the first', () async {
    final first = await signInAndOpen();
    await first.saveClass(
      ClassRoom(id: 'KT01', name: 'Kế toán 01', major: 'Kế toán', cohort: 'K17'),
    );
    await pumpEventQueue();
    await first.saveStudent(
      sampleStudent(studentId: 'SV9', name: 'Sinh viên Chín', classId: 'KT01'),
    );
    await pumpEventQueue();

    final second = await signInAndOpen();
    expect(second.students.single.studentId, 'SV9');
    expect(second.students.single.classId, 'KT01');
    expect(second.className('KT01'), 'Kế toán 01');
  });
}
