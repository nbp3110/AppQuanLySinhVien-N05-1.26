import 'package:app_quan_ly_sinh_vien/models/app_user.dart';
import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/services/auth_service.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:app_quan_ly_sinh_vien/services/student_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_firebase_auth.dart';
import 'support/sample_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Demo CRUD survives reopening without overwriting on duplicate',
    () async {
      final store = ProjectStore.demo();
      await store.initialize();
      await store.saveStudent(
        sampleStudent(studentId: 'NEW01', name: 'Sinh viên mới', classId: 'CNTT01'),
      );
      await expectLater(
        store.saveStudent(sampleStudent(studentId: 'NEW01')),
        throwsStateError,
      );
      await store.saveStudent(
        sampleStudent(studentId: 'NEW01', name: 'Tên đã sửa', classId: 'CNTT02'),
        editing: true,
      );
      await store.updateName('Quản lý thử');
      final reopened = ProjectStore.demo();
      await reopened.initialize();
      expect(
        reopened.students.where((v) => v.studentId == 'NEW01').single.name,
        'Tên đã sửa',
      );
      expect(
        reopened.students.where((v) => v.studentId == 'NEW01').single.classId,
        'CNTT02',
      );
      expect(reopened.profile.displayName, 'Quản lý thử');
      await reopened.deleteStudent('NEW01');
      expect(reopened.students.any((v) => v.studentId == 'NEW01'), false);
      store.dispose();
      reopened.dispose();
    },
  );

  test(
    'References and grade invariant prevent invalid student deletion',
    () async {
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      await expectLater(
        store.saveStudent(sampleStudent(studentId: 'NEW', classId: 'MISSING')),
        throwsStateError,
      );
      await expectLater(store.deleteStudent('SV001'), throwsStateError);
      expect(store.students.any((v) => v.studentId == 'SV001'), true);
      expect(store.students.any((v) => v.studentId == 'NEW'), false);
      await expectLater(
        store.saveStudent(sampleStudent(studentId: 'MISSING'), editing: true),
        throwsStateError,
      );
      store.dispose();
    },
  );

  test(
    'Class edit keeps student membership and refuses duplicate class',
    () async {
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      final c = ClassRoom(
        id: 'CNTT01',
        name: 'Tên mới',
        major: 'CNTT',
        cohort: 'K18',
      );
      await expectLater(store.saveClass(c), throwsStateError);
      await store.saveClass(c, editing: true);
      expect(store.className('CNTT01'), 'Tên mới');
      expect(store.students.where((v) => v.classId == 'CNTT01').length, 4);
      store.dispose();
    },
  );

  test(
    'Grade upsert preserves tuple identity and different semesters',
    () async {
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      final count = store.grades.length;
      await store.saveGrade(
        Grade(
          studentId: 'SV001',
          subjectId: 'MOB01',
          semester: '2026-1',
          score: 10,
        ),
      );
      expect(store.grades.length, count);
      expect(
        store.grades.singleWhere((v) => v.id == 'SV001~MOB01~2026-1').score,
        10,
      );
      await store.saveGrade(
        Grade(
          studentId: 'SV001',
          subjectId: 'MOB01',
          semester: '2026-2',
          score: 4,
        ),
      );
      expect(store.grades.length, count + 1);
      await expectLater(
        store.saveGrade(
          Grade(
            studentId: 'MISSING',
            subjectId: 'MOB01',
            semester: '2026-1',
            score: 8,
          ),
        ),
        throwsStateError,
      );
      store.dispose();
    },
  );

  group('Firebase session (fake Firestore and Auth)', () {
    late FakeFirebaseFirestore firestore;
    late StudentDataService data;
    late FakeFirebaseAuth fakeAuth;
    late ProjectStore store;

    ProjectStore openStore(FakeFirebaseAuth auth) => ProjectStore.cloud(
      data,
      AuthService(auth: auth, data: data),
      AppUser(
        uid: 'manager-1',
        email: 'manager@example.com',
        displayName: 'Quản lý thử',
      ),
    );

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      data = StudentDataService(firestore);
      fakeAuth = FakeFirebaseAuth();
      await data.classes.create(
        ClassRoom(id: 'CNTT01', name: 'CNTT 01', major: 'CNTT', cohort: 'K17'),
      );
      await data.subjects.create(
        Subject(id: 'MOB01', name: 'Di động', credits: 3),
      );
      await data.createStudent(
        sampleStudent(studentId: 'SV1', name: 'Sinh viên Một', classId: 'CNTT01'),
      );
      await data.createStudent(
        sampleStudent(studentId: 'SV2', name: 'Sinh viên Hai'),
      );
      await data.saveGrade(
        Grade(
          studentId: 'SV2',
          subjectId: 'MOB01',
          semester: '2026-1',
          score: 8,
        ),
      );
      store = openStore(fakeAuth);
      await store.initialize();
      await pumpEventQueue();
    });
    tearDown(() => store.dispose());

    Future<bool> exists(String id) async =>
        (await firestore.collection('students').doc(id).get()).exists;

    test('shows shared data and follows later changes', () async {
      expect(store.loading, false);
      expect(store.error, isNull);
      expect(store.students.map((v) => v.studentId), unorderedEquals(['SV1', 'SV2']));
      await data.createStudent(sampleStudent(studentId: 'SV3'));
      await pumpEventQueue();
      expect(store.students.length, 3);
    });

    test('editing a student keeps its grade counter', () async {
      await store.saveStudent(
        sampleStudent(studentId: 'SV2', name: 'Tên đã sửa'),
        editing: true,
      );
      await pumpEventQueue();
      expect(
        store.students.singleWhere((v) => v.studentId == 'SV2').name,
        'Tên đã sửa',
      );
      final saved = (await firestore.collection('students').doc('SV2').get())
          .data()!;
      expect(saved[StudentDataService.gradeCountField], 1);
    });

    test('a student without grades is deleted and the list refreshes', () async {
      await store.deleteStudent('SV1');
      await pumpEventQueue();
      expect(store.students.any((v) => v.studentId == 'SV1'), false);
      expect(await exists('SV1'), false);
    });

    test('a student with grades is kept', () async {
      await expectLater(store.deleteStudent('SV2'), throwsStateError);
      expect(await exists('SV2'), true);
      expect(store.students.any((v) => v.studentId == 'SV2'), true);
    });

    test('the transaction refuses even when the local list is stale', () async {
      store.grades = [];
      expect(store.gradeCountFor('SV2'), 0);
      await expectLater(store.deleteStudent('SV2'), throwsStateError);
      expect(await exists('SV2'), true);
    });

    test('sign out ends the session, stops streams and drops cached data', () async {
      await store.signOut();
      expect(fakeAuth.signOutCalls, 1);
      expect(store.students, isEmpty);
      expect(store.grades, isEmpty);
      await data.createStudent(sampleStudent(studentId: 'LATE'));
      await pumpEventQueue();
      expect(store.students, isEmpty);
      expect(store.error, isNull);
    });

    test('a failed sign out keeps the session and its data', () async {
      final failing = FakeFirebaseAuth(signOutError: StateError('offline'));
      final other = openStore(failing);
      addTearDown(other.dispose);
      await other.initialize();
      await pumpEventQueue();
      await expectLater(other.signOut(), throwsStateError);
      expect(other.students.length, 2);
      await data.createStudent(sampleStudent(studentId: 'SV3'));
      await pumpEventQueue();
      expect(other.students.length, 3);
    });

    test('the demo has no session to end', () async {
      final demo = ProjectStore.demo(persist: false);
      await demo.initialize();
      await demo.signOut();
      expect(demo.students, isNotEmpty);
      demo.dispose();
    });
  });
}
