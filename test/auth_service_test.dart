import 'package:app_quan_ly_sinh_vien/models/app_user.dart';
import 'package:app_quan_ly_sinh_vien/services/auth_service.dart';
import 'package:app_quan_ly_sinh_vien/services/student_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_firebase_auth.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late StudentDataService data;
  setUp(() {
    firestore = FakeFirebaseFirestore();
    data = StudentDataService(firestore);
  });

  Future<void> profile(String uid, {String role = 'manager'}) =>
      firestore.collection('users').doc(uid).set({
        'email': 'manager@example.com',
        'displayName': 'Quản lý thử',
        'role': role,
      });

  group('US01 - sign in', () {
    test('manager with a profile gets the AppUser', () async {
      await profile('manager-1');
      final auth = FakeFirebaseAuth();
      final user = await AuthService(auth: auth, data: data).signIn(
        email: '  manager@example.com ',
        password: 'secret',
      );
      expect(user.uid, 'manager-1');
      expect(user.displayName, 'Quản lý thử');
      expect(auth.lastEmail, 'manager@example.com');
      expect(auth.signOutCalls, 0);
    });

    test('account without a profile is rejected and signed out', () async {
      final auth = FakeFirebaseAuth(uid: 'nobody');
      await expectLater(
        AuthService(
          auth: auth,
          data: data,
        ).signIn(email: 'a@example.com', password: 'x'),
        throwsStateError,
      );
      expect(auth.signOutCalls, 1);
    });

    test('profile with another role is rejected and signed out', () async {
      await profile('guest-1', role: 'student');
      final auth = FakeFirebaseAuth(uid: 'guest-1');
      await expectLater(
        AuthService(
          auth: auth,
          data: data,
        ).signIn(email: 'a@example.com', password: 'x'),
        throwsA(anything),
      );
      expect(auth.signOutCalls, 1);
    });

    test('wrong password reaches the caller', () async {
      await profile('manager-1');
      final auth = FakeFirebaseAuth(
        signInError: FirebaseAuthException(code: 'wrong-password'),
      );
      await expectLater(
        AuthService(
          auth: auth,
          data: data,
        ).signIn(email: 'manager@example.com', password: 'bad'),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(auth.signInCalls, 1);
    });
  });

  group('US02 - sign out', () {
    test('signOut asks Firebase Auth to end the session', () async {
      final auth = FakeFirebaseAuth();
      await AuthService(auth: auth, data: data).signOut();
      expect(auth.signOutCalls, 1);
    });
  });

  group('US04 - update display name', () {
    test('trims the name and keeps email and role', () async {
      await profile('manager-1');
      final service = AuthService(auth: FakeFirebaseAuth(), data: data);
      final current = (await data.users.getById('manager-1'))!;
      await service.updateDisplayName(current, '  Tên mới  ');
      final saved = (await firestore.collection('users').doc('manager-1').get())
          .data()!;
      expect(saved['displayName'], 'Tên mới');
      expect(saved['email'], 'manager@example.com');
      expect(saved['role'], 'manager');
    });

    test('blank or too long names are refused and nothing is saved', () async {
      await profile('manager-1');
      final service = AuthService(auth: FakeFirebaseAuth(), data: data);
      final current = (await data.users.getById('manager-1'))!;
      // The model rejects the value before any write is attempted.
      await expectLater(
        () => service.updateDisplayName(current, '   '),
        throwsFormatException,
      );
      await expectLater(
        () => service.updateDisplayName(current, 'A' * 151),
        throwsFormatException,
      );
      await service.updateDisplayName(current, 'A' * 150);
      final saved = (await firestore.collection('users').doc('manager-1').get())
          .data()!;
      expect((saved['displayName'] as String).length, 150);
    });

    test('a missing profile is not recreated by an update', () async {
      final service = AuthService(auth: FakeFirebaseAuth(), data: data);
      final ghost = AppUser(
        uid: 'ghost',
        email: 'ghost@example.com',
        displayName: 'Chưa có hồ sơ',
      );
      await expectLater(
        () => service.updateDisplayName(ghost, 'Mới'),
        throwsA(anything),
      );
      expect(
        (await firestore.collection('users').doc('ghost').get()).exists,
        false,
      );
    });
  });
}
