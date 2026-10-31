import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/project_store.dart';
import '../services/student_data_service.dart';
import '../ui/project_theme.dart';
import 'learning_sample_screen.dart';
import 'project_workspace.dart';

/// Signs in with email and password and returns the store of that session.
/// Tests inject their own; the app uses [openFirebaseSession].
typedef CloudSessionOpener =
    Future<ProjectStore> Function(String email, String password);

Future<ProjectStore> openFirebaseSession(String email, String password) async {
  final data = StudentDataService(FirebaseFirestore.instance);
  final auth = AuthService(auth: FirebaseAuth.instance, data: data);
  return ProjectStore.cloud(
    data,
    auth,
    await auth.signIn(email: email, password: password),
  );
}

class ProjectLoginScreen extends StatefulWidget {
  const ProjectLoginScreen({super.key, this.openCloudSession});
  final CloudSessionOpener? openCloudSession;
  @override
  State<ProjectLoginScreen> createState() => _ProjectLoginScreenState();
}

class _ProjectLoginScreenState extends State<ProjectLoginScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false, _hidden = true;
  String? _error;
  Future<void> _open(bool demo) async {
    if (_busy || (!demo && !_form.currentState!.validate())) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    ProjectStore? store;
    try {
      if (demo) {
        store = ProjectStore.demo();
      } else {
        store = await (widget.openCloudSession ?? openFirebaseSession)(
          _email.text,
          _password.text,
        );
      }
      await store.initialize();
      if (!mounted) {
        store.dispose();
        return;
      }
      final active = store;
      _password.clear();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProjectWorkspace(store: active),
        ),
      );
      active.dispose();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == 'network-request-failed'
              ? 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.'
              : 'Sai thông tin đăng nhập, chưa được cấp quyền hoặc đã thử quá nhiều lần.\nChi tiết: ${e.code}',
        );
      }
      store?.dispose();
    } catch (e) {
      // Only the reason is shown (a message we wrote or a Firebase error code);
      // never the credentials.
      final reason = e is StateError
          ? e.message
          : e is FirebaseException
          ? '${e.plugin}/${e.code}'
          : null;
      if (mounted) {
        setState(
          () => _error =
              'Không mở được phiên làm việc. Kiểm tra quyền tài khoản và kết nối.'
              '${reason == null ? '' : '\nChi tiết: $reason'}',
        );
      }
      store?.dispose();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4B3BC4), Color(0xFF7B4FE0), Color(0xFFFF8FB8)],
              ),
            ),
          ),
        ),
        Positioned(top: -90, left: -70,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x26FFFFFF),
            ),
          ),
        ),
        Positioned(bottom: -120, right: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x33FFD36B),
            ),
          ),
        ),
        Positioned(top: 120, right: 90,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x33FFFFFF),
            ),
          ),
        ),
        Positioned(bottom: 90, left: 110,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x40FF8FB8),
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F1A5C).withValues(alpha: .35),
                      blurRadius: 50,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                                      const Padding(
                              padding: EdgeInsets.only(bottom: 35),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    color: green,
                                    size: 35,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'UniNest',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Pill('CHÀO MỪNG TRỞ LẠI'),
                          const SizedBox(height: 18),
                          Text(
                            'Một ngày học tập\nthật hiệu quả!',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Đăng nhập để quản lý dữ liệu của nhóm.',
                            style: TextStyle(color: muted),
                          ),
                          const SizedBox(height: 30),
                          ...[
                            TextFormField(
                              controller: _email,
                              enabled: !_busy,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email quản lý',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (v) => v == null || !v.contains('@')
                                  ? 'Nhập email hợp lệ'
                                  : null,
                            ),
                            const SizedBox(height: 17),
                            TextFormField(
                              controller: _password,
                              enabled: !_busy,
                              obscureText: _hidden,
                              onFieldSubmitted: (_) => _open(false),
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _hidden = !_hidden),
                                  icon: Icon(
                                    _hidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Nhập mật khẩu'
                                  : null,
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _busy ? null : () => _open(false),
                                child: const Text('Đăng nhập Firebase'),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : () => _open(true),
                              icon: _busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.play_circle_outline),
                              label: Text(
                                _busy
                                    ? 'Đang mở không gian…'
                                    : 'Khám phá bản trình diễn',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Bản trình diễn dùng dữ liệu mẫu riêng, không ghi Firebase.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: muted,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Divider(),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const LearningSampleScreen(),
                                  ),
                                ),
                                child: const Text('Xem màn hình mẫu'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
