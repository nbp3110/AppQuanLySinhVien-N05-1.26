import 'package:app_quan_ly_sinh_vien/models/app_user.dart';
import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/screens/project_login_screen.dart';
import 'package:app_quan_ly_sinh_vien/screens/project_workspace.dart';
import 'package:app_quan_ly_sinh_vien/services/auth_service.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:app_quan_ly_sinh_vien/services/student_data_service.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_firebase_auth.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpLogin(
    WidgetTester tester,
    CloudSessionOpener opener,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: projectTheme(),
        home: ProjectLoginScreen(openCloudSession: opener),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(
    WidgetTester tester, {
    String email = 'manager@example.com',
    String password = 'secret',
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.tap(find.text('Đăng nhập Firebase'));
    await tester.pumpAndSettle();
  }

  group('US01 - login', () {
    testWidgets('empty fields are rejected before any sign-in', (tester) async {
      var calls = 0;
      await pumpLogin(tester, (email, password) async {
        calls++;
        throw StateError('must not be called');
      });
      await tester.tap(find.text('Đăng nhập Firebase'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Nhập email hợp lệ'), findsOneWidget);
      expect(find.text('Nhập mật khẩu'), findsOneWidget);
      expect(find.byType(ProjectWorkspace), findsNothing);
    });

    testWidgets('wrong credentials show an error and stay on login', (
      tester,
    ) async {
      await pumpLogin(tester, (email, password) async {
        throw FirebaseAuthException(code: 'wrong-password');
      });
      await submit(tester);
      expect(find.textContaining('Sai thông tin đăng nhập'), findsOneWidget);
      expect(find.byType(ProjectWorkspace), findsNothing);
      expect(find.text('Đăng nhập Firebase'), findsOneWidget);
    });

    testWidgets('a network failure is reported separately', (tester) async {
      await pumpLogin(tester, (email, password) async {
        throw FirebaseAuthException(code: 'network-request-failed');
      });
      await submit(tester);
      expect(find.textContaining('Không kết nối được máy chủ'), findsOneWidget);
      expect(find.byType(ProjectWorkspace), findsNothing);
    });

    testWidgets('an account without manager rights never reaches the data', (
      tester,
    ) async {
      await pumpLogin(tester, (email, password) async {
        throw StateError('Tài khoản chưa được cấp quyền quản lý.');
      });
      await submit(tester);
      expect(
        find.textContaining('Không mở được phiên làm việc'),
        findsOneWidget,
      );
      expect(find.byType(ProjectWorkspace), findsNothing);
    });

    testWidgets('a valid manager opens the workspace', (tester) async {
      // The login screen disposes the store itself once the workspace closes.
      final store = ProjectStore.demo(persist: false);
      String? usedEmail;
      await pumpLogin(tester, (email, password) async {
        usedEmail = email;
        return store;
      });
      await submit(tester);
      expect(usedEmail, 'manager@example.com');
      expect(find.byType(ProjectWorkspace), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('US02 - logout', () {
    testWidgets('returns to login, ends the session and drops the data', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      final data = StudentDataService(firestore);
      await tester.runAsync(() async {
        await data.classes.create(
          ClassRoom(
            id: 'CNTT01',
            name: 'CNTT 01',
            major: 'CNTT',
            cohort: 'K17',
          ),
        );
        await data.createStudent(
          Student(studentId: 'SV1', name: 'Sinh viên Một', classId: 'CNTT01'),
        );
      });
      final auth = FakeFirebaseAuth();
      late ProjectStore opened;
      await pumpLogin(tester, (email, password) async {
        opened = ProjectStore.cloud(
          data,
          AuthService(auth: auth, data: data),
          AppUser(uid: 'manager-1', email: email, displayName: 'Quản lý thử'),
        );
        return opened;
      });
      await submit(tester);
      expect(find.byType(ProjectWorkspace), findsOneWidget);
      expect(find.textContaining('FIREBASE'), findsOneWidget);
      expect(find.text('Sinh viên Một'), findsOneWidget);

      await tester.tap(find.text('Cá nhân').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      // Sign out waits for the fake Firestore streams to cancel. pumpAndSettle
      // does not advance fake timers when no frame is scheduled, so let time pass.
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProjectWorkspace), findsNothing);
      expect(find.text('Đăng nhập Firebase'), findsOneWidget);
      expect(auth.signOutCalls, 1);
      expect(opened.students, isEmpty);
      expect(opened.classes, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
