import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal stand-in for [FirebaseAuth]: no network and no Firebase.initializeApp.
/// Only the calls used by AuthService are implemented.
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  FakeFirebaseAuth({
    this.uid = 'manager-1',
    this.signInError,
    this.signOutError,
  });

  final String uid;

  /// When set, signInWithEmailAndPassword throws it (wrong password, offline…).
  final Object? signInError;

  /// When set, signOut throws it.
  final Object? signOutError;

  int signInCalls = 0;
  int signOutCalls = 0;
  String? lastEmail;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    final error = signInError;
    if (error != null) throw error;
    return _FakeCredential(_FakeUser(uid));
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    final error = signOutError;
    if (error != null) throw error;
  }
}

class _FakeCredential extends Fake implements UserCredential {
  _FakeCredential(this._user);
  final User _user;

  @override
  User? get user => _user;
}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);
  final String _uid;

  @override
  String get uid => _uid;
}
