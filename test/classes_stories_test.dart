import 'package:app_quan_ly_sinh_vien/models/class_room.dart';
import 'package:app_quan_ly_sinh_vien/screens/project_workspace.dart';
import 'package:app_quan_ly_sinh_vien/services/project_store.dart';
import 'package:app_quan_ly_sinh_vien/ui/project_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sample_data.dart';

/// US09-US12: the class pages of the manager workspace (demo store).
/// The demo data has CNTT01 (4 students), CNTT02 (2), KT01 (1) and one
/// student, SV008, without a class.
void main() {
  Future<ProjectStore> openClasses(WidgetTester tester) async {
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
    await tester.tap(find.text('Lớp học').first);
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> finish(WidgetTester tester, ProjectStore store) async {
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  }

  Future<void> openNewClassForm(WidgetTester tester) async {
    await tester.tap(find.text('Thêm lớp học').first);
    await tester.pumpAndSettle();
  }

  Future<void> fillClass(
    WidgetTester tester, {
    String? id,
    String? name,
    String? major,
    String? cohort,
  }) async {
    final fields = find.byType(TextFormField);
    if (id != null) await tester.enterText(fields.at(0), id);
    if (name != null) await tester.enterText(fields.at(1), name);
    if (major != null) await tester.enterText(fields.at(2), major);
    if (cohort != null) await tester.enterText(fields.at(3), cohort);
  }

  group('US09 - class list', () {
    testWidgets('shows code, name, major, cohort and student count', (
      tester,
    ) async {
      final store = await openClasses(tester);
      expect(find.text('3 lớp · Kết nối sinh viên cùng ngành và khóa'),
          findsOneWidget);
      expect(find.text('Công nghệ thông tin 01'), findsOneWidget);
      expect(find.text('CNTT01 · Công nghệ thông tin'), findsOneWidget);
      expect(find.text('K17'), findsNWidgets(2));
      expect(find.text('K18'), findsOneWidget);
      expect(find.text('4 sinh viên'), findsOneWidget);
      expect(find.text('2 sinh viên'), findsOneWidget);
      expect(find.text('1 sinh viên'), findsOneWidget);
      await finish(tester, store);
    });

    testWidgets('a store without classes explains the empty list', (
      tester,
    ) async {
      final store = await openClasses(tester);
      store.classes.clear();
      store.students.clear();
      await store.saveStudent(sampleStudent(studentId: 'TMP1'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có lớp học'), findsOneWidget);
      expect(find.text('0 lớp · Kết nối sinh viên cùng ngành và khóa'),
          findsOneWidget);
      await finish(tester, store);
    });

    testWidgets('the list follows a class added to the store', (tester) async {
      final store = await openClasses(tester);
      await store.saveClass(
        ClassRoom(id: 'LIVE01', name: 'Lớp mới thêm', major: 'CNTT', cohort: 'K19'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lớp mới thêm'), findsOneWidget);
      expect(find.text('4 lớp · Kết nối sinh viên cùng ngành và khóa'),
          findsOneWidget);
      await finish(tester, store);
    });
  });

  group('US10 - create a class', () {
    testWidgets('a valid class is saved and shown', (tester) async {
      final store = await openClasses(tester);
      await openNewClassForm(tester);
      await fillClass(
        tester,
        id: 'CNTT03',
        name: 'Công nghệ thông tin 03',
        major: 'Công nghệ thông tin',
        cohort: 'K18',
      );
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(store.classes.any((c) => c.id == 'CNTT03'), true);
      expect(find.text('Công nghệ thông tin 03'), findsOneWidget);
      expect(find.text('Đã lưu lớp học.'), findsOneWidget);
      await finish(tester, store);
    });

    testWidgets('a duplicate code is refused and nothing is overwritten', (
      tester,
    ) async {
      final store = await openClasses(tester);
      await openNewClassForm(tester);
      await fillClass(
        tester,
        id: 'CNTT01',
        name: 'Tên khác hoàn toàn',
        major: 'Ngành khác',
        cohort: 'K20',
      );
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(find.text('Mã lớp đã tồn tại.'), findsOneWidget);
      expect(store.classes.length, 3);
      expect(
        store.classes.singleWhere((c) => c.id == 'CNTT01').name,
        'Công nghệ thông tin 01',
      );
      await finish(tester, store);
    });

    testWidgets('empty fields are flagged before saving', (tester) async {
      final store = await openClasses(tester);
      await openNewClassForm(tester);
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập mã lớp'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên lớp'), findsOneWidget);
      expect(find.text('Vui lòng nhập ngành học'), findsOneWidget);
      expect(store.classes.length, 3);
      await finish(tester, store);
    });

    testWidgets('a code with spaces or accents is refused', (tester) async {
      final store = await openClasses(tester);
      await openNewClassForm(tester);
      await fillClass(
        tester,
        id: 'Lớp 01',
        name: 'Tên lớp',
        major: 'Ngành',
        cohort: 'K17',
      );
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(
        find.text('Mã lớp chỉ gồm chữ không dấu, số, _ hoặc - (1–80 ký tự).'),
        findsOneWidget,
      );
      expect(store.classes.length, 3);
      await finish(tester, store);
    });

    testWidgets('a name or major over 150 characters is refused', (
      tester,
    ) async {
      final store = await openClasses(tester);
      await openNewClassForm(tester);
      await fillClass(
        tester,
        id: 'DAI01',
        name: 'A' * 151,
        major: 'Ngành',
        cohort: 'K17',
      );
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tên lớp không được trống hoặc dài quá 150 ký tự.'),
        findsOneWidget,
      );
      await fillClass(tester, name: 'Tên lớp', major: 'B' * 151);
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ngành không được trống hoặc dài quá 150 ký tự.'),
        findsOneWidget,
      );
      expect(store.classes.any((c) => c.id == 'DAI01'), false);
      await finish(tester, store);
    });

    testWidgets('a cohort over 30 characters is refused, 30 is accepted', (
      tester,
    ) async {
      final store = await openClasses(tester);
      await openNewClassForm(tester);
      await fillClass(
        tester,
        id: 'KHOA01',
        name: 'Tên lớp',
        major: 'Ngành',
        cohort: 'K' * 31,
      );
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(
        find.text('Khóa học không được trống hoặc dài quá 30 ký tự.'),
        findsOneWidget,
      );
      expect(store.classes.any((c) => c.id == 'KHOA01'), false);
      await fillClass(tester, cohort: 'K' * 30);
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(store.classes.any((c) => c.id == 'KHOA01'), true);
      await finish(tester, store);
    });
  });

  group('US11 - edit a class', () {
    Future<void> openEdit(WidgetTester tester, String id) async {
      final button = find.byTooltip('Sửa $id');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('the code is locked and the other fields can change', (
      tester,
    ) async {
      final store = await openClasses(tester);
      await openEdit(tester, 'CNTT01');
      final fields = find.byType(TextFormField);
      expect(tester.widget<TextFormField>(fields.at(0)).enabled, false);
      await tester.enterText(fields.at(1), 'Tên lớp đã sửa');
      await tester.enterText(fields.at(3), 'K18');
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      final edited = store.classes.singleWhere((c) => c.id == 'CNTT01');
      expect(edited.name, 'Tên lớp đã sửa');
      expect(edited.cohort, 'K18');
      expect(store.classes.length, 3);
      await finish(tester, store);
    });

    testWidgets('students stay linked to the edited class', (tester) async {
      final store = await openClasses(tester);
      await openEdit(tester, 'CNTT01');
      await tester.enterText(find.byType(TextFormField).at(1), 'Tên mới');
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(store.students.where((s) => s.classId == 'CNTT01').length, 4);
      expect(find.text('4 sinh viên'), findsOneWidget);
      await finish(tester, store);
    });

    testWidgets('an invalid edit keeps the form open and the old data', (
      tester,
    ) async {
      final store = await openClasses(tester);
      await openEdit(tester, 'KT01');
      await tester.enterText(find.byType(TextFormField).at(1), 'X' * 151);
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tên lớp không được trống hoặc dài quá 150 ký tự.'),
        findsOneWidget,
      );
      expect(find.text('Sửa lớp học'), findsOneWidget);
      expect(store.classes.singleWhere((c) => c.id == 'KT01').name, 'Kế toán 01');
      await finish(tester, store);
    });

    test('a class that no longer exists cannot be edited into existence', () async {
      final store = ProjectStore.demo(persist: false);
      await store.initialize();
      await expectLater(
        store.saveClass(
          ClassRoom(id: 'GONE01', name: 'Đã xóa', major: 'CNTT', cohort: 'K17'),
          editing: true,
        ),
        throwsStateError,
      );
      expect(store.classes.any((c) => c.id == 'GONE01'), false);
      store.dispose();
    });
  });

  group('US12 - students of one class', () {
    testWidgets('"Xem lớp" lists only the students of that class', (
      tester,
    ) async {
      final store = await openClasses(tester);
      final view = find.text('Xem lớp →');
      await tester.ensureVisible(view.first);
      await tester.tap(view.first);
      await tester.pumpAndSettle();
      expect(find.text('Hiển thị 4 hồ sơ'), findsOneWidget);
      expect(find.text('Sinh viên Mẫu 01'), findsOneWidget);
      expect(find.text('Sinh viên Mẫu 05'), findsNothing);
      expect(find.text('Sinh viên Mẫu 08'), findsNothing);
      await finish(tester, store);
    });

    testWidgets('a class without students is reported as empty', (
      tester,
    ) async {
      final store = await openClasses(tester);
      await store.saveClass(
        ClassRoom(id: 'TRONG01', name: 'Lớp trống', major: 'CNTT', cohort: 'K19'),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 sinh viên'), findsOneWidget);
      final view = find.text('Xem lớp →');
      await tester.ensureVisible(view.last);
      await tester.tap(view.last);
      await tester.pumpAndSettle();
      expect(find.text('Không có sinh viên phù hợp'), findsOneWidget);
      expect(find.text('Hiển thị 0 hồ sơ'), findsOneWidget);
      await finish(tester, store);
    });

    testWidgets('moving a student to another class updates both lists', (
      tester,
    ) async {
      final store = await openClasses(tester);
      final old = store.students.singleWhere((s) => s.studentId == 'SV001');
      await store.saveStudent(
        sampleStudent(
          studentId: old.studentId,
          name: old.name,
          major: old.major,
          age: old.age,
          email: old.email,
          classId: 'KT01',
        ),
        editing: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('3 sinh viên'), findsOneWidget);
      expect(find.text('2 sinh viên'), findsNWidgets(2));
      await finish(tester, store);
    });
  });
}
