import 'package:app_quan_ly_sinh_vien/models/grade.dart';
import 'package:app_quan_ly_sinh_vien/models/subject.dart';
import 'package:app_quan_ly_sinh_vien/screens/grades_screen.dart';
import 'package:app_quan_ly_sinh_vien/screens/subjects_screen.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_data.dart';

void main() {
  testWidgets(
    'Subject search and add enforce unique code, name and integer credits',
    (tester) async {
      final subjects = <Subject>[
        Subject(id: 'CS101', name: 'Cơ sở dữ liệu', credits: 3),
      ];
      Future<void> create(Subject subject) async => subjects.add(subject);

      await tester.pumpWidget(
        MaterialApp(
          theme: projectTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => SubjectsScreen(
                  subjects: subjects,
                  onCreate: (subject) async {
                    await create(subject);
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Cơ sở dữ liệu'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'CS101');
      await tester.pumpAndSettle();
      expect(find.text('Cơ sở dữ liệu'), findsOneWidget);
      expect(find.text('Lập trình di động'), findsNothing);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm môn'));
      await tester.pumpAndSettle();
      var fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'cs101');
      await tester.enterText(fields.at(1), 'Môn trùng mã');
      await tester.enterText(fields.at(2), '3');
      await tester.tap(find.text('Lưu môn'));
      await tester.pumpAndSettle();
      expect(find.text('Mã môn học đã tồn tại.'), findsOneWidget);
      expect(subjects, hasLength(1));

      await tester.enterText(fields.at(0), 'MOB01');
      await tester.enterText(fields.at(1), 'Lập trình di động');
      await tester.enterText(fields.at(2), '2.5');
      await tester.tap(find.text('Lưu môn'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tín chỉ phải là số nguyên từ 1 đến 10.'),
        findsOneWidget,
      );
      await tester.enterText(fields.at(2), '4');
      await tester.tap(find.text('Lưu môn'));
      await tester.pumpAndSettle();
      expect(subjects, hasLength(2));
      expect(subjects.last.credits, 4);
      expect(find.text('Lập trình di động'), findsOneWidget);
    },
  );

  testWidgets(
    'Grades select student, validate score, and update the matching tuple',
    (tester) async {
      final students = [
        sampleStudent(studentId: 'SV01', name: 'An'),
        sampleStudent(studentId: 'SV02', name: 'Bình'),
      ];
      final subjects = [
        Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3),
      ];
      final grades = <Grade>[
        Grade(
          studentId: 'SV01',
          subjectId: 'MOB01',
          semester: '2026-1',
          score: 6,
        ),
        Grade(
          studentId: 'SV02',
          subjectId: 'MOB01',
          semester: '2026-1',
          score: 9,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: projectTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => GradesScreen(
                  students: students,
                  subjects: subjects,
                  grades: grades,
                  onSave: (grade) async {
                    final index = grades.indexWhere(
                      (old) => old.id == grade.id,
                    );
                    if (index < 0) {
                      grades.add(grade);
                    } else {
                      grades[index] = grade;
                    }
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('An chưa có điểm.'), findsNothing);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('9'), findsNothing);

      await tester.tap(find.text('An · SV01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bình · SV02').last);
      await tester.pumpAndSettle();
      expect(find.text('9'), findsOneWidget);
      expect(find.text('6'), findsNothing);

      await tester.tap(find.text('Nhập / cập nhật điểm'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), '11');
      await tester.tap(find.text('Lưu điểm'));
      await tester.pumpAndSettle();
      expect(find.text('Điểm phải là số từ 0 đến 10.'), findsOneWidget);
      expect(grades, hasLength(2));

      await tester.enterText(fields.at(1), '7.5');
      await tester.tap(find.text('Lưu điểm'));
      await tester.pumpAndSettle();
      expect(grades, hasLength(2));
      expect(grades.singleWhere((g) => g.studentId == 'SV02').score, 7.5);
      expect(find.text('7.5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
