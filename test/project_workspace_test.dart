import 'package:app_quan_ly_sinh_vien/screens/learning_sample_screen.dart';
import 'package:app_quan_ly_sinh_vien/screens/project_workspace.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_data.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1440, 960)]) {
    testWidgets('Dashboard and sample layout fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      await tester.pumpWidget(
        MaterialApp(
          theme: projectTheme(),
          home: ProjectWorkspace(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('TRÌNH DIỄN'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(theme: projectTheme(), home: const LearningSampleScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('HỘP QUÀ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }

  testWidgets('Student form keeps invalid input and saves valid student', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = ProjectStore.demo(persist: false);
    await store.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: projectTheme(),
        home: ProjectWorkspace(store: store),
      ),
    );
    await tester.tap(find.text('Thêm sinh viên').first);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'NEWTEST');
    await tester.enterText(fields.at(1), 'Sinh viên kiểm thử');
    await tester.enterText(fields.at(3), '20.5');
    await tester.tap(find.text('Lưu thông tin'));
    await tester.pumpAndSettle();
    expect(find.text('Tuổi phải là số nguyên từ 1 đến 120.'), findsOneWidget);
    expect(store.students.any((v) => v.studentId == 'NEWTEST'), false);
    await tester.enterText(fields.at(3), '20');
    await tester.tap(find.text('Lưu thông tin'));
    await tester.pumpAndSettle();
    expect(
      store.students.singleWhere((v) => v.studentId == 'NEWTEST').name,
      'Sinh viên kiểm thử',
    );
    expect(find.text('Lưu thông tin'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  group('US08 - delete a student from the list', () {
    Future<ProjectStore> openStudents(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      await tester.pumpWidget(
        MaterialApp(
          theme: projectTheme(),
          home: ProjectWorkspace(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sinh viên').first);
      await tester.pumpAndSettle();
      return store;
    }

    Future<void> chooseDelete(WidgetTester tester, String id) async {
      final menu = find.byTooltip('Thao tác $id');
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa sinh viên'));
      await tester.pumpAndSettle();
    }

    testWidgets('cancel keeps the student, confirm removes it', (tester) async {
      final store = await openStudents(tester);
      await chooseDelete(tester, 'SV008');
      expect(find.text('Xóa sinh viên?'), findsOneWidget);
      await tester.tap(find.text('Giữ lại'));
      await tester.pumpAndSettle();
      expect(store.students.any((v) => v.studentId == 'SV008'), true);
      await chooseDelete(tester, 'SV008');
      await tester.tap(find.text('Xác nhận xóa'));
      await tester.pumpAndSettle();
      expect(store.students.any((v) => v.studentId == 'SV008'), false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });

    testWidgets('a student with grades is blocked with an explanation', (
      tester,
    ) async {
      final store = await openStudents(tester);
      await chooseDelete(tester, 'SV001');
      expect(find.text('Xóa sinh viên?'), findsNothing);
      expect(find.textContaining('2 bản ghi điểm'), findsOneWidget);
      expect(store.students.any((v) => v.studentId == 'SV001'), true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  });

  Future<ProjectStore> openStudentsPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = ProjectStore.demo(persist: false);
    await store.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: projectTheme(),
        home: ProjectWorkspace(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sinh viên').first);
    await tester.pumpAndSettle();
    return store;
  }

  final searchBox = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        w.decoration?.hintText == 'Tìm tên, mã sinh viên hoặc ngành…',
  );

  group('US05 - student list', () {
    testWidgets('search and class filter narrow the list', (tester) async {
      final store = await openStudentsPage(tester);
      expect(find.text('Hiển thị 8 hồ sơ'), findsOneWidget);

      await tester.enterText(searchBox, 'sv003');
      await tester.pumpAndSettle();
      expect(find.text('Hiển thị 1 hồ sơ'), findsOneWidget);

      await tester.enterText(searchBox, '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'CNTT01'));
      await tester.pumpAndSettle();
      expect(find.text('Hiển thị 4 hồ sơ'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });

    testWidgets('a search without result explains the empty list', (
      tester,
    ) async {
      final store = await openStudentsPage(tester);
      await tester.enterText(searchBox, 'khong-co-ai-ten-nhu-vay');
      await tester.pumpAndSettle();
      expect(find.text('Không có sinh viên phù hợp'), findsOneWidget);
      expect(find.text('Hiển thị 0 hồ sơ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });

    testWidgets('the list follows a student added to the store', (
      tester,
    ) async {
      final store = await openStudentsPage(tester);
      await store.saveStudent(
        sampleStudent(studentId: 'LIVE01', name: 'Sinh viên mới thêm'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hiển thị 9 hồ sơ'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  });

  group('US06 - add student form', () {
    Future<void> openForm(WidgetTester tester) async {
      await tester.tap(find.text('Thêm sinh viên').first);
      await tester.pumpAndSettle();
    }

    testWidgets('a duplicate ID is refused and nothing is overwritten', (
      tester,
    ) async {
      final store = await openStudentsPage(tester);
      await openForm(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'SV001');
      await tester.enterText(fields.at(1), 'Tên khác hoàn toàn');
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(find.text('Mã sinh viên đã tồn tại.'), findsOneWidget);
      expect(store.students.length, 8);
      expect(
        store.students.singleWhere((v) => v.studentId == 'SV001').name,
        'Sinh viên Mẫu 01',
      );
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });

    testWidgets('an invalid email keeps the form open with a message', (
      tester,
    ) async {
      final store = await openStudentsPage(tester);
      await openForm(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'EMAILBAD');
      await tester.enterText(fields.at(1), 'Sinh viên email sai');
      await tester.enterText(fields.at(4), 'khong-hop-le');
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(find.text('Email không hợp lệ.'), findsOneWidget);
      expect(store.students.any((v) => v.studentId == 'EMAILBAD'), false);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });

    testWidgets('required fields are checked before saving', (tester) async {
      final store = await openStudentsPage(tester);
      await openForm(tester);
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập mã sinh viên'), findsOneWidget);
      expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
      expect(store.students.length, 8);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  });
}
