import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Khởi tạo Firebase một lần khi mở ứng dụng và báo lỗi nếu không kết nối được.
class FirebaseBootstrap {
  static Future<void>? _initialization;

  // Share concurrent attempts, but allow retry after a failure.
  static Future<void> initialize() => _initialization ??= _initialize().onError(
    (Object error, StackTrace stack) {
      _initialization = null;
      Error.throwWithStackTrace(error, stack);
    },
  );

  static Future<void> _initialize() async {
    const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    if (useEmulators && kReleaseMode) {
      throw StateError('Không dùng emulator trong bản release.');
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (useEmulators) {
      const host = String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
        defaultValue: '10.0.2.2',
      );
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    }
  }
}
