import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/class_room.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import 'auth_service.dart';
import 'student_data_service.dart';

/// The demo is a separate, persistent local dataset. It never writes to Firebase.
class ProjectStore extends ChangeNotifier {
  ProjectStore.demo({this.persist = true}) : data = null, auth = null;
  ProjectStore.cloud(this.data, this.auth, this.profile) : persist = false;

  static const storageKey = 'qlsv.presentation.v1';
  final StudentDataService? data;
  final AuthService? auth;
  final bool persist;
  bool get isDemo => data == null;
  AppUser profile = AppUser(
    uid: 'demo-manager',
    email: 'demo@example.invalid',
    displayName: 'Quản lý Mẫu',
  );
  List<Student> students = [];
  List<ClassRoom> classes = [];
  List<Subject> subjects = [];
  List<Grade> grades = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool loading = true;
  String? error;
  bool _disposed = false;
  bool _signingOut = false;
  final List<String> activities = [];

  Future<void> initialize() async {
    try {
      if (isDemo) {
        final saved = persist
            ? (await SharedPreferences.getInstance()).getString(storageKey)
            : null;
        if (saved == null) {
          _seed();
          await _persist();
        } else {
          final map = jsonDecode(saved) as Map<String, dynamic>;
          students = _decode(map['students'], Student.fromMap);
          classes = _decode(map['classes'], ClassRoom.fromMap);
          subjects = _decode(map['subjects'], Subject.fromMap);
          grades = _decode(map['grades'], Grade.fromMap);
          profile = AppUser.fromMap(
            'demo-manager',
            Map<String, dynamic>.from(map['profile']),
          );
        }
        loading = false;
      } else {
        final received = <String>{};
        void ready(String collection) {
          received.add(collection);
          if (received.length == 4) loading = false;
          _changed();
        }

        _subscriptions.add(
          data!.students.watchAll().listen((v) {
            students = v;
            ready('students');
          }, onError: _loadError),
        );
        _subscriptions.add(
          data!.classes.watchAll().listen((v) {
            classes = v;
            ready('classes');
          }, onError: _loadError),
        );
        _subscriptions.add(
          data!.subjects.watchAll().listen((v) {
            subjects = v;
            ready('subjects');
          }, onError: _loadError),
        );
        _subscriptions.add(
          data!.grades.watchAll().listen((v) {
            grades = v;
            ready('grades');
          }, onError: _loadError),
        );
      }
    } catch (e) {
      loading = false;
      error = 'Không tải được dữ liệu. Hãy kiểm tra kết nối hoặc bộ nhớ trình duyệt.';
    }
    _changed();
  }

  List<T> _decode<T>(
    dynamic rows,
    T Function(String, Map<String, dynamic>) from,
  ) => (rows as List)
      .map(
        (row) =>
            from(row['id'] as String, Map<String, dynamic>.from(row['data'])),
      )
      .toList();

  void _seed() {
    classes = [
      ClassRoom(
        id: 'CNTT01',
        name: 'Công nghệ thông tin 01',
        major: 'Công nghệ thông tin',
        cohort: 'K17',
      ),
      ClassRoom(
        id: 'CNTT02',
        name: 'Công nghệ thông tin 02',
        major: 'Công nghệ thông tin',
        cohort: 'K17',
      ),
      ClassRoom(
        id: 'KT01',
        name: 'Kế toán 01',
        major: 'Kế toán',
        cohort: 'K18',
      ),
    ];
    const names = [
      'Sinh viên Mẫu 01',
      'Sinh viên Mẫu 02',
      'Sinh viên Mẫu 03',
      'Sinh viên Mẫu 04',
      'Sinh viên Mẫu 05',
      'Sinh viên Mẫu 06',
      'Sinh viên Mẫu 07',
      'Sinh viên Mẫu 08',
    ];
    students = List.generate(
      names.length,
      (i) => Student(
        studentId: 'SV00${i + 1}',
        name: names[i],
        age: 20 + i % 3,
        major: i == 6 ? 'Kế toán' : 'Công nghệ thông tin',
        classId: i == 7
            ? null
            : (i == 6
                  ? 'KT01'
                  : i < 4
                  ? 'CNTT01'
                  : 'CNTT02'),
        email: 'sv00${i + 1}@example.invalid',
      ),
    );
    subjects = [
      Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3),
      Subject(id: 'WEB01', name: 'Lập trình Web nâng cao', credits: 3),
      Subject(id: 'CSDL01', name: 'Cơ sở dữ liệu', credits: 3),
      Subject(id: 'CTDL01', name: 'Cấu trúc dữ liệu và giải thuật', credits: 4),
    ];
    grades = List.generate(
      10,
      (i) => Grade(
        studentId: 'SV00${i % 5 + 1}',
        subjectId: i < 5 ? 'MOB01' : 'CSDL01',
        semester: '2026-1',
        score: [8.5, 7.0, 9.0, 6.5, 8.0][i % 5],
      ),
    );
  }

  Future<void> _persist() async {
    if (!isDemo || !persist) return;
    final saved = jsonEncode({
      'students': students
          .map((s) => {'id': s.studentId, 'data': s.toMap()})
          .toList(),
      'classes': classes.map((s) => {'id': s.id, 'data': s.toMap()}).toList(),
      'subjects': subjects.map((s) => {'id': s.id, 'data': s.toMap()}).toList(),
      'grades': grades.map((s) => {'id': s.id, 'data': s.toMap()}).toList(),
      'profile': profile.toMap(),
    });
    if (!await (await SharedPreferences.getInstance()).setString(
      storageKey,
      saved,
    )) {
      throw StateError('Không lưu được dữ liệu trên máy.');
    }
  }

  Future<void> _change(Future<void> Function() action, String message) async {
    // Restore the previous local snapshot if durable storage fails.
    final oldStudents = List<Student>.of(students);
    final oldClasses = List<ClassRoom>.of(classes);
    final oldSubjects = List<Subject>.of(subjects);
    final oldGrades = List<Grade>.of(grades);
    final oldProfile = profile;
    try {
      await action();
      await _persist();
    } catch (_) {
      students = oldStudents;
      classes = oldClasses;
      subjects = oldSubjects;
      grades = oldGrades;
      profile = oldProfile;
      rethrow;
    }
    activities.insert(0, message);
    _changed();
  }

  Future<void> saveStudent(
    Student student, {
    bool editing = false,
  }) => _change(() async {
    student.validate();
    if (student.classId != null &&
        !classes.any((v) => v.id == student.classId)) {
      throw StateError('Lớp được chọn không còn tồn tại.');
    }
    final index = students.indexWhere((v) => v.studentId == student.studentId);
    if (!editing && index >= 0) throw StateError('Mã sinh viên đã tồn tại.');
    if (editing && index < 0) throw StateError('Sinh viên không còn tồn tại.');
    if (isDemo) {
      if (editing) {
        students[index] = student;
      } else {
        students.add(student);
      }
    } else {
      if (editing) {
        await data!.updateStudent(student);
      } else {
        await data!.createStudent(student);
      }
    }
  }, '${editing ? 'Cập nhật' : 'Thêm'} sinh viên ${student.studentId}');

  /// Number of grade records the student already has, as currently known.
  int gradeCountFor(String studentId) =>
      grades.where((v) => v.studentId == studentId).length;

  Future<void> deleteStudent(String id) => _change(() async {
    // The list is only a friendly early check. On Firebase the transaction and
    // the rules decide, using the counter kept in the student document.
    if (gradeCountFor(id) > 0) {
      throw StateError('Sinh viên đã có điểm. Không thể xóa hồ sơ.');
    }
    if (!students.any((v) => v.studentId == id)) {
      throw StateError('Sinh viên không còn tồn tại.');
    }
    if (isDemo) {
      students.removeWhere((v) => v.studentId == id);
    } else {
      await data!.deleteStudent(id);
    }
  }, 'Xóa sinh viên $id');

  Future<void> saveClass(ClassRoom room, {bool editing = false}) =>
      _change(() async {
        final index = classes.indexWhere((v) => v.id == room.id);
        if (!editing && index >= 0) throw StateError('Mã lớp đã tồn tại.');
        if (editing && index < 0) throw StateError('Lớp không còn tồn tại.');
        if (isDemo) {
          if (editing) {
            classes[index] = room;
          } else {
            classes.add(room);
          }
        } else {
          if (editing) {
            await data!.classes.update(room);
          } else {
            await data!.classes.create(room);
          }
        }
      }, '${editing ? 'Cập nhật' : 'Thêm'} lớp ${room.id}');

  Future<void> saveSubject(Subject subject) => _change(() async {
    if (subjects.any((v) => v.id == subject.id)) {
      throw StateError('Mã môn học đã tồn tại.');
    }
    if (isDemo) {
      subjects.add(subject);
    } else {
      await data!.subjects.create(subject);
    }
  }, 'Thêm môn học ${subject.id}');

  Future<void> saveGrade(Grade grade) => _change(() async {
    if (!students.any((v) => v.studentId == grade.studentId) ||
        !subjects.any((v) => v.id == grade.subjectId)) {
      throw StateError('Sinh viên hoặc môn học không còn tồn tại.');
    }
    if (isDemo) {
      final index = grades.indexWhere((v) => v.id == grade.id);
      if (index < 0) {
        grades.add(grade);
      } else {
        grades[index] = grade;
      }
    } else {
      await data!.saveGrade(grade);
    }
  }, 'Lưu điểm ${grade.studentId} · ${grade.subjectId}');

  Future<void> updateName(String value) => _change(() async {
    final updated = AppUser(
      uid: profile.uid,
      email: profile.email,
      displayName: value.trim(),
    );
    if (!isDemo) await auth!.updateDisplayName(profile, updated.displayName);
    profile = updated;
  }, 'Cập nhật hồ sơ cá nhân');

  String className(String? id) =>
      classes.where((v) => v.id == id).firstOrNull?.name ?? 'Chưa xếp lớp';
  String subjectName(String id) =>
      subjects.where((v) => v.id == id).firstOrNull?.name ?? id;
  double? averageFor(String studentId) {
    final rows = grades.where((g) => g.studentId == studentId).toList();
    if (rows.isEmpty) return null;
    var points = 0.0;
    var credits = 0;
    for (final g in rows) {
      final weight =
          subjects.where((s) => s.id == g.subjectId).firstOrNull?.credits ?? 1;
      points += g.score * weight;
      credits += weight;
    }
    return points / credits;
  }

  /// Ends the signed-in session. Streams may report permission errors while the
  /// account is being signed out; those are ignored. Afterwards the streams are
  /// cancelled and the cached data is dropped. The demo has no session.
  Future<void> signOut() async {
    if (isDemo) return;
    _signingOut = true;
    try {
      await auth!.signOut();
    } catch (_) {
      _signingOut = false;
      rethrow;
    }
    final active = List.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in active) {
      await subscription.cancel();
    }
    students = [];
    classes = [];
    subjects = [];
    grades = [];
  }

  void _loadError(Object e) {
    if (_signingOut) return;
    loading = false;
    error =
        'Không tải được dữ liệu Firebase. Kiểm tra mạng và quyền tài khoản.';
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
