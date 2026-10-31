import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/student.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/screens/grades_screen.dart';
import 'package:app_quan_ly_sinh_vien/screens/subjects_screen.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_data.dart';

/// US13-US16: the subject and grade screens, driven directly with lists and
/// callbacks so that each rule and each state (loading, empty, error) is
/// checked on its own.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: projectTheme(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  // ---------------------------------------------------------------- subjects

  Future<List<Subject>> pumpSubjects(
    WidgetTester tester, {
    List<Subject>? initial,
    Future<void> Function(Subject)? onCreate,
    bool loading = false,
    String? error,
    VoidCallback? onRetry,
  }) async {
    final subjects = List<Subject>.of(initial ?? const []);
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SubjectsScreen(
            subjects: subjects,
            loading: loading,
            error: error,
            onRetry: onRetry,
            onCreate:
                onCreate ??
                (subject) async {
                  subjects.add(subject);
                  setState(() {});
                },
          ),
        ),
      ),
    );
    // A loading screen shows an endless spinner, so it can never "settle".
    if (loading) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
    return subjects;
  }

  Future<void> openSubjectForm(WidgetTester tester) async {
    await tester.tap(find.text('Thêm môn'));
    await tester.pumpAndSettle();
  }

  Future<void> fillSubject(
    WidgetTester tester, {
    String? id,
    String? name,
    String? credits,
  }) async {
    final fields = find.byType(TextFormField);
    if (id != null) await tester.enterText(fields.at(0), id);
    if (name != null) await tester.enterText(fields.at(1), name);
    if (credits != null) await tester.enterText(fields.at(2), credits);
  }

  Future<void> saveSubject(WidgetTester tester) async {
    await tester.tap(find.text('Lưu môn'));
    await tester.pumpAndSettle();
  }

  group('US13 - subject list', () {
    testWidgets('shows code, name and credits, sorted by code', (tester) async {
      await pumpSubjects(
        tester,
        initial: [
          Subject(id: 'B02', name: 'Môn thứ hai', credits: 4),
          Subject(id: 'A01', name: 'Môn thứ nhất', credits: 2),
        ],
      );
      expect(find.text('2 môn học'), findsOneWidget);
      expect(find.text('A01'), findsOneWidget);
      expect(find.text('Môn thứ nhất'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('tín chỉ'), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Môn thứ nhất')).dy,
        lessThan(tester.getTopLeft(find.text('Môn thứ hai')).dy),
      );
    });

    testWidgets('an empty list explains what to do', (tester) async {
      await pumpSubjects(tester);
      expect(find.text('Chưa có môn học'), findsOneWidget);
      expect(find.text('0 môn học'), findsOneWidget);
    });

    testWidgets('a search without result says so', (tester) async {
      await pumpSubjects(
        tester,
        initial: [Subject(id: 'CS101', name: 'Cơ sở dữ liệu', credits: 3)],
      );
      await tester.enterText(find.byType(TextField), 'khong-co');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy môn học'), findsOneWidget);
      expect(find.text('Cơ sở dữ liệu'), findsNothing);
      await tester.enterText(find.byType(TextField), 'dữ liệu');
      await tester.pumpAndSettle();
      expect(find.text('Cơ sở dữ liệu'), findsOneWidget);
    });

    testWidgets('while loading it shows a spinner and no list or empty text', (
      tester,
    ) async {
      await pumpSubjects(
        tester,
        initial: [Subject(id: 'CS101', name: 'Cơ sở dữ liệu', credits: 3)],
        loading: true,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cơ sở dữ liệu'), findsNothing);
      expect(find.text('Chưa có môn học'), findsNothing);
      // The add button is disabled while loading.
      await tester.tap(find.text('Thêm môn'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a load error is shown with a retry that is wired up', (
      tester,
    ) async {
      var retries = 0;
      await pumpSubjects(
        tester,
        error: 'Không tải được danh sách môn học.',
        onRetry: () => retries++,
      );
      expect(find.text('Không tải được danh sách môn học.'), findsOneWidget);
      // No made-up data appears next to the error.
      expect(find.text('Chưa có môn học'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(retries, 1);
    });
  });

  group('US14 - add a subject', () {
    testWidgets('credits 1 and 10 are accepted, 0 and 11 are not', (
      tester,
    ) async {
      final subjects = await pumpSubjects(tester);
      for (final bad in ['0', '11', '-1', 'abc', '']) {
        await openSubjectForm(tester);
        await fillSubject(tester, id: 'MON$bad'.replaceAll(RegExp('[^A-Za-z0-9]'), 'X'), name: 'Môn thử', credits: bad);
        await saveSubject(tester);
        expect(
          find.text('Tín chỉ phải là số nguyên từ 1 đến 10.'),
          findsOneWidget,
          reason: 'credits "$bad"',
        );
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
      }
      expect(subjects, isEmpty);
      for (final good in ['1', '10']) {
        await openSubjectForm(tester);
        await fillSubject(tester, id: 'TC$good', name: 'Môn $good tín chỉ', credits: good);
        await saveSubject(tester);
      }
      expect(subjects.map((s) => s.credits), [1, 10]);
    });

    testWidgets('required fields and the code format are checked', (
      tester,
    ) async {
      final subjects = await pumpSubjects(tester);
      await openSubjectForm(tester);
      await tester.tap(find.text('Lưu môn'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập mã môn học.'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên môn học.'), findsOneWidget);

      await fillSubject(tester, id: 'Môn 01', name: '   ');
      await saveSubject(tester);
      expect(find.text('Mã chỉ gồm chữ không dấu, số, _ hoặc -.'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên môn học.'), findsOneWidget);
      expect(subjects, isEmpty);
    });

    testWidgets('a name over 150 characters is refused with the reason', (
      tester,
    ) async {
      final subjects = await pumpSubjects(tester);
      await openSubjectForm(tester);
      await fillSubject(tester, id: 'DAI01', name: 'A' * 151);
      await saveSubject(tester);
      expect(
        find.text('Tên môn không được trống hoặc dài quá 150 ký tự.'),
        findsOneWidget,
      );
      expect(find.text('Thêm môn học'), findsOneWidget);
      expect(subjects, isEmpty);
      await fillSubject(tester, name: 'A' * 150);
      await saveSubject(tester);
      expect(subjects.single.name.length, 150);
    });

    testWidgets('the code is compared without regard to letter case', (
      tester,
    ) async {
      final subjects = await pumpSubjects(
        tester,
        initial: [Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3)],
      );
      await openSubjectForm(tester);
      await fillSubject(tester, id: 'mob01', name: 'Môn trùng mã');
      await saveSubject(tester);
      expect(find.text('Mã môn học đã tồn tại.'), findsOneWidget);
      expect(subjects, hasLength(1));
    });

    testWidgets('cancel adds nothing and closes the form', (tester) async {
      final subjects = await pumpSubjects(tester);
      await openSubjectForm(tester);
      await fillSubject(tester, id: 'HUY01', name: 'Sẽ không lưu');
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(subjects, isEmpty);
    });

    testWidgets('a refusal from the data layer is shown and keeps the form', (
      tester,
    ) async {
      var calls = 0;
      await pumpSubjects(
        tester,
        onCreate: (_) async {
          calls++;
          throw StateError('Mã môn học đã tồn tại.');
        },
      );
      await openSubjectForm(tester);
      await fillSubject(tester, id: 'LOI01', name: 'Môn bị từ chối');
      await saveSubject(tester);
      expect(calls, 1);
      expect(find.text('Mã môn học đã tồn tại.'), findsOneWidget);
      expect(find.text('Thêm môn học'), findsOneWidget);
    });

    testWidgets('an unexpected failure gives a generic retry message', (
      tester,
    ) async {
      await pumpSubjects(
        tester,
        onCreate: (_) async => throw Exception('mạng lỗi'),
      );
      await openSubjectForm(tester);
      await fillSubject(tester, id: 'LOI02', name: 'Môn lỗi mạng');
      await saveSubject(tester);
      expect(find.text('Không lưu được môn học. Vui lòng thử lại.'), findsOneWidget);
      expect(find.textContaining('mạng lỗi'), findsNothing);
    });
  });

  // ------------------------------------------------------------------ grades

  final students = [
    sampleStudent(studentId: 'SV01', name: 'An'),
    sampleStudent(studentId: 'SV02', name: 'Bình'),
  ];
  final subjectList = [
    Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3),
    Subject(id: 'WEB01', name: 'Lập trình Web', credits: 3),
  ];
  Grade grade(String studentId, String subjectId, String semester, double score) =>
      Grade(
        studentId: studentId,
        subjectId: subjectId,
        semester: semester,
        score: score,
      );

  Future<List<Grade>> pumpGrades(
    WidgetTester tester, {
    List<Student>? studentList,
    List<Subject>? subjects,
    List<Grade>? initial,
    Future<void> Function(Grade)? onSave,
    bool loading = false,
    String? error,
    VoidCallback? onRetry,
  }) async {
    final grades = List<Grade>.of(initial ?? const []);
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => GradesScreen(
            students: studentList ?? students,
            subjects: subjects ?? subjectList,
            grades: grades,
            loading: loading,
            error: error,
            onRetry: onRetry,
            onSave:
                onSave ??
                (g) async {
                  final index = grades.indexWhere((old) => old.id == g.id);
                  if (index < 0) {
                    grades.add(g);
                  } else {
                    grades[index] = g;
                  }
                  setState(() {});
                },
          ),
        ),
      ),
    );
    if (loading) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
    return grades;
  }

  Future<void> openGradeForm(WidgetTester tester) async {
    await tester.tap(find.text('Nhập / cập nhật điểm'));
    await tester.pumpAndSettle();
  }

  Future<void> submitGrade(
    WidgetTester tester, {
    String? semester,
    String? score,
  }) async {
    final fields = find.byType(TextFormField);
    if (semester != null) await tester.enterText(fields.at(0), semester);
    if (score != null) await tester.enterText(fields.at(1), score);
    await tester.tap(find.text('Lưu điểm'));
    await tester.pumpAndSettle();
  }

  group('US15 - save a grade', () {
    testWidgets('the semester must look like YYYY-1 or YYYY-2', (tester) async {
      final grades = await pumpGrades(tester);
      for (final bad in ['2026-3', '2026-0', '2026', '26-1', 'abc', '']) {
        await openGradeForm(tester);
        await submitGrade(tester, semester: bad, score: '8');
        expect(
          find.text('Học kỳ có dạng YYYY-1 hoặc YYYY-2.'),
          findsOneWidget,
          reason: 'semester "$bad"',
        );
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
      }
      expect(grades, isEmpty);
      for (final good in ['2026-1', '2026-2']) {
        await openGradeForm(tester);
        await submitGrade(tester, semester: good, score: '8');
      }
      expect(grades.map((g) => g.semester), ['2026-1', '2026-2']);
    });

    testWidgets('the score must be a number from 0 to 10', (tester) async {
      final grades = await pumpGrades(tester);
      for (final bad in ['-0.1', '10.1', 'abc', '', 'NaN']) {
        await openGradeForm(tester);
        await submitGrade(tester, semester: '2026-1', score: bad);
        expect(
          find.text('Điểm phải là số từ 0 đến 10.'),
          findsOneWidget,
          reason: 'score "$bad"',
        );
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
      }
      expect(grades, isEmpty);
    });

    testWidgets('both ends of the range and a decimal comma are accepted', (
      tester,
    ) async {
      final grades = await pumpGrades(tester);
      for (final entry in {'2026-1': '0', '2026-2': '10', '2027-1': '8,5'}.entries) {
        await openGradeForm(tester);
        await submitGrade(tester, semester: entry.key, score: entry.value);
      }
      expect(grades.map((g) => g.score), [0, 10, 8.5]);
    });

    testWidgets('the same student, subject and semester updates one record', (
      tester,
    ) async {
      final grades = await pumpGrades(tester);
      await openGradeForm(tester);
      await submitGrade(tester, semester: '2026-1', score: '6');
      await openGradeForm(tester);
      await submitGrade(tester, semester: '2026-1', score: '9');
      expect(grades, hasLength(1));
      expect(grades.single.score, 9);
      // Another semester is kept as a separate record.
      await openGradeForm(tester);
      await submitGrade(tester, semester: '2026-2', score: '7');
      expect(grades, hasLength(2));
    });

    testWidgets('a refusal such as a missing student is shown in the form', (
      tester,
    ) async {
      await pumpGrades(
        tester,
        onSave: (_) async =>
            throw StateError('Sinh viên hoặc môn học không còn tồn tại.'),
      );
      await openGradeForm(tester);
      await submitGrade(tester, semester: '2026-1', score: '8');
      expect(
        find.text('Sinh viên hoặc môn học không còn tồn tại.'),
        findsOneWidget,
      );
      expect(find.text('Lưu điểm'), findsOneWidget);
    });

    testWidgets('an unexpected failure gives a generic retry message', (
      tester,
    ) async {
      await pumpGrades(tester, onSave: (_) async => throw Exception('lỗi mạng'));
      await openGradeForm(tester);
      await submitGrade(tester, semester: '2026-1', score: '8');
      expect(find.text('Không lưu được điểm. Vui lòng thử lại.'), findsOneWidget);
    });

    testWidgets('cancel saves nothing', (tester) async {
      final grades = await pumpGrades(tester);
      await openGradeForm(tester);
      await tester.enterText(find.byType(TextFormField).at(1), '9');
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(grades, isEmpty);
    });

    testWidgets('entering grades needs at least one student and one subject', (
      tester,
    ) async {
      await pumpGrades(tester, subjects: const <Subject>[]);
      await tester.tap(find.text('Nhập / cập nhật điểm'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      await pumpGrades(tester, studentList: const <Student>[]);
      expect(find.text('Thêm sinh viên trước khi nhập điểm.'), findsOneWidget);
      await tester.tap(find.text('Nhập / cập nhật điểm'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('US16 - grade sheet of one student', () {
    testWidgets('shows subject, code, semester and score, newest first', (
      tester,
    ) async {
      await pumpGrades(
        tester,
        initial: [
          grade('SV01', 'MOB01', '2026-1', 8.5),
          grade('SV01', 'WEB01', '2026-2', 9),
          grade('SV02', 'MOB01', '2026-1', 4),
        ],
      );
      expect(find.text('Kết quả của An'), findsOneWidget);
      expect(find.text('MOB01 · 2026-1'), findsOneWidget);
      expect(find.text('WEB01 · 2026-2'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      // Another student's grade does not leak into this sheet.
      expect(find.text('4'), findsNothing);
      expect(
        tester.getTopLeft(find.text('WEB01 · 2026-2')).dy,
        lessThan(tester.getTopLeft(find.text('MOB01 · 2026-1')).dy),
      );
    });

    testWidgets('a student without grades is reported as such', (tester) async {
      await pumpGrades(tester, initial: [grade('SV02', 'MOB01', '2026-1', 4)]);
      expect(find.text('An chưa có điểm.'), findsOneWidget);
      await tester.tap(find.text('An · SV01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bình · SV02').last);
      await tester.pumpAndSettle();
      expect(find.text('An chưa có điểm.'), findsNothing);
      expect(find.text('Kết quả của Bình'), findsOneWidget);
    });

    testWidgets('a grade saved for the selected student appears at once', (
      tester,
    ) async {
      await pumpGrades(tester);
      expect(find.text('An chưa có điểm.'), findsOneWidget);
      await openGradeForm(tester);
      await submitGrade(tester, semester: '2026-1', score: '7.5');
      expect(find.text('An chưa có điểm.'), findsNothing);
      expect(find.text('7.5'), findsOneWidget);
      expect(find.text('MOB01 · 2026-1'), findsOneWidget);
    });

    testWidgets('the choice of student changes the rows shown', (tester) async {
      await pumpGrades(
        tester,
        initial: [
          grade('SV01', 'MOB01', '2026-1', 6),
          grade('SV02', 'WEB01', '2026-1', 9),
        ],
      );
      expect(find.text('6'), findsOneWidget);
      await tester.tap(find.text('An · SV01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bình · SV02').last);
      await tester.pumpAndSettle();
      expect(find.text('9'), findsOneWidget);
      expect(find.text('6'), findsNothing);
      await tester.tap(find.text('Bình · SV02'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('An · SV01').last);
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('without students there is nothing to select', (tester) async {
      await pumpGrades(tester, studentList: const <Student>[]);
      expect(find.text('Thêm sinh viên trước khi nhập điểm.'), findsOneWidget);
    });

    testWidgets('while loading it shows a spinner and no sheet', (tester) async {
      await pumpGrades(
        tester,
        initial: [grade('SV01', 'MOB01', '2026-1', 8)],
        loading: true,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Kết quả của An'), findsNothing);
      expect(find.text('An chưa có điểm.'), findsNothing);
    });

    testWidgets('a load error is shown with a retry that is wired up', (
      tester,
    ) async {
      var retries = 0;
      await pumpGrades(
        tester,
        error: 'Không tải được bảng điểm.',
        onRetry: () => retries++,
      );
      expect(find.text('Không tải được bảng điểm.'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(retries, 1);
    });
  });
}
