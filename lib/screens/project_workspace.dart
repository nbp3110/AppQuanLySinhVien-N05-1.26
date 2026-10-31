import 'package:flutter/material.dart';

import '../models/class_room.dart';
import '../models/student.dart';
import '../services/project_store.dart';
import '../ui/project_theme.dart';
import '../ui/record_form.dart';
import 'grades_screen.dart';
import 'learning_sample_screen.dart';
import 'subjects_screen.dart';

/// Không gian quản lý sau đăng nhập: Tổng quan, Sinh viên, Lớp học, Môn & điểm, Cá nhân.
class ProjectWorkspace extends StatefulWidget {
  const ProjectWorkspace({super.key, required this.store});
  final ProjectStore store;
  @override
  State<ProjectWorkspace> createState() => _ProjectWorkspaceState();
}

class _ProjectWorkspaceState extends State<ProjectWorkspace> {
  ProjectStore get s => widget.store;
  int _page = 0;
  int _moduleTab = 0;
  String _search = '';
  String? _classFilter;
  final _searchInput = TextEditingController();
  static const _labels = [
    'Tổng quan',
    'Sinh viên',
    'Lớp học',
    'Môn & điểm',
    'Cá nhân',
  ];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.people_alt_outlined,
    Icons.meeting_room_outlined,
    Icons.menu_book_outlined,
    Icons.person_outline_rounded,
  ];
  void _go(int page) => setState(() {
    _page = page;
    _search = '';
    _searchInput.clear();
    _classFilter = null;
  });
  void _notice(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  @override
  void dispose() {
    _searchInput.dispose();
    super.dispose();
  }

  Future<void> _studentForm([Student? old]) => recordForm(
    context,
    title: old == null ? 'Thêm sinh viên' : 'Sửa sinh viên',
    subtitle: 'Mã sinh viên là duy nhất và không thay đổi sau khi tạo.',
    fields: [
      FieldSpec(
        'id',
        'Mã sinh viên',
        value: old?.studentId ?? '',
        locked: old != null,
      ),
      FieldSpec('name', 'Họ và tên', value: old?.name ?? ''),
      FieldSpec(
        'major',
        'Ngành học',
        value: old?.major ?? 'Công nghệ thông tin',
      ),
      FieldSpec(
        'age',
        'Tuổi',
        value: old?.age.toString() ?? '20',
        number: true,
      ),
      FieldSpec(
        'email',
        'Email (không bắt buộc)',
        value: old?.email ?? '',
        optional: true,
      ),
      FieldSpec(
        'classId',
        'Lớp học',
        value: old?.classId ?? '',
        optional: true,
        options: {
          '': 'Chưa xếp lớp',
          for (final c in s.classes) c.id: '${c.id} · ${c.name}',
        },
      ),
    ],
    onSave: (v) async {
      final age = int.tryParse(v['age']!);
      if (age == null) {
        throw const FormatException('Tuổi phải là số nguyên từ 1 đến 120.');
      }
      await s.saveStudent(
        Student(
          studentId: v['id']!,
          name: v['name']!,
          major: v['major']!,
          age: age,
          email: v['email']!,
          classId: v['classId']!.isEmpty ? null : v['classId'],
        ),
        editing: old != null,
      );
      _notice('Đã lưu thông tin sinh viên.');
    },
  );

  Future<void> _classForm([ClassRoom? old]) => recordForm(
    context,
    title: old == null ? 'Thêm lớp học' : 'Sửa lớp học',
    subtitle: 'Quản lý thông tin lớp, ngành và khóa học.',
    fields: [
      FieldSpec('id', 'Mã lớp', value: old?.id ?? '', locked: old != null),
      FieldSpec('name', 'Tên lớp', value: old?.name ?? ''),
      FieldSpec('major', 'Ngành học', value: old?.major ?? ''),
      FieldSpec('cohort', 'Khóa học', value: old?.cohort ?? 'K17'),
    ],
    onSave: (v) async {
      await s.saveClass(
        ClassRoom(
          id: v['id']!,
          name: v['name']!,
          major: v['major']!,
          cohort: v['cohort']!,
        ),
        editing: old != null,
      );
      _notice('Đã lưu lớp học.');
    },
  );

  /// First letter of the given name (last word), safe for empty or padded text.
  static String _initial(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final last = words.isEmpty ? '' : words.last;
    return last.isEmpty
        ? '?'
        : String.fromCharCode(last.runes.first).toUpperCase();
  }

  Future<void> _delete(Student student) async {
    final graded = s.gradeCountFor(student.studentId);
    if (graded > 0) {
      _notice(
        'Không thể xóa ${student.name}: sinh viên đã có $graded bản ghi điểm.',
      );
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa sinh viên?'),
        content: Text(
          'Xóa ${student.name} (${student.studentId})? Hồ sơ đã xóa không thể khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await s.deleteStudent(student.studentId);
      _notice('Đã xóa sinh viên.');
    } catch (e) {
      _notice(
        e is StateError ? e.message.toString() : 'Không xóa được sinh viên.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: s,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= 1050;
        return PopScope(
          canPop: false,
          child: Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  if (desktop) _sidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _topbar(desktop),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 24,
                          ),
                          color: s.isDemo
                              ? const Color(0xFFFFF4D8)
                              : const Color(0xFFEDE9FF),
                          child: Row(
                            children: [
                              Icon(
                                s.isDemo
                                    ? Icons.science_outlined
                                    : Icons.cloud_done_outlined,
                                size: 15,
                                color: s.isDemo
                                    ? const Color(0xFF99711C)
                                    : green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.isDemo
                                      ? 'TRÌNH DIỄN · Dữ liệu mẫu lưu riêng trên máy, không ghi Firebase'
                                      : 'FIREBASE · Dữ liệu dùng chung của nhóm',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: s.isDemo
                                        ? const Color(0xFF99711C)
                                        : green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: s.loading
                              ? const Center(child: CircularProgressIndicator())
                              : s.error != null
                              ? Center(
                                  child: Panel(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.cloud_off_rounded,
                                          size: 44,
                                          color: muted,
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          s.error!,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 18),
                                        OutlinedButton(
                                          onPressed: _logout,
                                          child: const Text('Về đăng nhập'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: EdgeInsets.all(desktop ? 30 : 18),
                                  child: switch (_page) {
                                    0 => _dashboard(box.maxWidth),
                                    1 => _students(),
                                    2 => _classes(),
                                    3 => _modules(),
                                    _ => _profile(),
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: desktop
                ? null
                : NavigationBar(
                    selectedIndex: _page,
                    onDestinationSelected: _go,
                    backgroundColor: Colors.white,
                    indicatorColor: const Color(0xFFE4DEFF),
                    destinations: List.generate(
                      _labels.length,
                      (i) => NavigationDestination(
                        icon: Icon(_icons[i]),
                        label: _labels[i],
                      ),
                    ),
                  ),
          ),
        );
      },
    ),
  );

  Widget _sidebar() => Container(
    width: 225,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Row(
            children: [
              Icon(Icons.school_rounded, size: 34, color: green),
              SizedBox(width: 9),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'EduSpace',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text(
            'QUẢN LÝ SINH VIÊN',
            style: TextStyle(fontSize: 9, letterSpacing: 2, color: muted),
          ),
        ),
        const SizedBox(height: 45),
        for (var i = 0; i < _labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _page == i ? const Color(0xFFEDE9FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: () => _go(i),
                borderRadius: BorderRadius.circular(13),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _icons[i],
                        size: 21,
                        color: _page == i ? green : muted,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          _labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _page == i ? green : muted,
                            fontWeight: _page == i
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FB),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFE7B038)),
              const SizedBox(height: 12),
              const Text(
                'Góc học tập',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              const Text(
                'Khám phá giao diện học tập\ntheo yêu cầu Câu 5.',
                style: TextStyle(fontSize: 11, color: muted, height: 1.6),
              ),
              const SizedBox(height: 7),
              TextButton(
                onPressed: () => _open(const LearningSampleScreen()),
                child: const Text(
                  'Xem giao diện →',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEDE9FF),
            child: Text(
              _initial(s.profile.displayName),
              style: const TextStyle(color: green),
            ),
          ),
          title: Text(
            s.profile.displayName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text('Người quản lý', style: TextStyle(fontSize: 10)),
          trailing: IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 18),
          ),
        ),
      ],
    ),
  );

  Widget _topbar(bool wide) => Container(
    height: 77,
    padding: EdgeInsets.symmetric(horizontal: wide ? 30 : 18),
    color: Colors.white,
    child: Row(
      children: [
        if (!wide)
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.school_rounded, color: green),
          ),
        Expanded(
          child: Text(
            _labels[_page],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (wide)
          const Text(
            'Năm học 2026 – 2027',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        const SizedBox(width: 14),
        const Pill('Học kỳ 1', color: Color(0xFF608DC5)),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Hoạt động trong phiên',
          onPressed: _activityDialog,
          icon: Badge(
            isLabelVisible: s.activities.isNotEmpty,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    ),
  );

  Widget _heading(String title, String description, {Widget? action}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
            ?action,
          ],
        ),
      );

  Widget _dashboard(double width) {
    final narrow = width < 720;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Xin chào, ${s.profile.displayName.split(' ').last} 👋',
          'Chào mừng đến với không gian quản lý học tập của bạn.',
        ),
        LayoutBuilder(
          builder: (context, b) => Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _quick(
                'Sinh viên',
                'Hồ sơ & thông tin',
                Icons.school_rounded,
                const Color(0xFF31C96B),
                b.maxWidth,
                () => _go(1),
              ),
              _quick(
                'Lớp học',
                'Kết nối & quản lý',
                Icons.groups_rounded,
                const Color(0xFFFFC339),
                b.maxWidth,
                () => _go(2),
              ),
              _quick(
                'Môn & điểm',
                'Theo dõi học tập',
                Icons.auto_stories_rounded,
                const Color(0xFF39B6ED),
                b.maxWidth,
                () => _go(3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 22,
          runSpacing: 12,
          children: [
            _shortcut(
              Icons.person_add_alt_1_rounded,
              'Thêm sinh viên',
              const Color(0xFF33AFDE),
              () => _studentForm(),
            ),
            _shortcut(
              Icons.add_home_work_outlined,
              'Tạo lớp học',
              const Color(0xFFED8D6C),
              () => _classForm(),
            ),
            _shortcut(
              Icons.grid_view_rounded,
              'Mẫu Câu 5',
              const Color(0xFFDCAF1F),
              () => _open(const LearningSampleScreen()),
            ),
            _shortcut(
              Icons.menu_book_outlined,
              'Môn học',
              const Color(0xFF74BC5E),
              () => setState(() {
                _page = 3;
                _moduleTab = 0;
              }),
            ),
            _shortcut(
              Icons.assessment_outlined,
              'Bảng điểm',
              const Color(0xFFB889CD),
              () => setState(() {
                _page = 3;
                _moduleTab = 1;
              }),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(narrow ? 24 : 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: const LinearGradient(
              colors: [Color(0xFFE4DEFF), Color(0xFFFFE3EE)],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Pill('HỌC TẬP CÙNG NHAU', color: Color(0xFF5A4BC2)),
                    const SizedBox(height: 15),
                    Text(
                      'Mỗi dữ liệu nhỏ,\nmột hành trình lớn.',
                      style: TextStyle(
                        fontSize: narrow ? 25 : 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2E2478),
                        height: 1.2,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sắp xếp thông tin hôm nay để quản lý tốt hơn ngày mai.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7C70C8)),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _go(1),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Khám phá sinh viên'),
                    ),
                  ],
                ),
              ),
              if (!narrow)
                SizedBox(
                  width: 220,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFCFC7FF),
                        ),
                      ),
                      Transform.rotate(
                        angle: -.13,
                        child: Container(
                          width: 128,
                          height: 145,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD16A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 84,
                            color: Color(0xFFBB812B),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 3,
                        right: 9,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 42,
                          color: Color(0xFFE9B63D),
                        ),
                      ),
                      const Positioned(
                        bottom: 4,
                        left: 9,
                        child: CircleAvatar(
                          radius: 23,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.check_rounded, color: green),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, b) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _stat(
                'Sinh viên',
                '${s.students.length}',
                Icons.people_outline,
                green,
                b.maxWidth,
              ),
              _stat(
                'Lớp học',
                '${s.classes.length}',
                Icons.meeting_room_outlined,
                const Color(0xFF6199DB),
                b.maxWidth,
              ),
              _stat(
                'Môn học',
                '${s.subjects.length}',
                Icons.menu_book_outlined,
                const Color(0xFFCC9B28),
                b.maxWidth,
              ),
              _stat(
                'Bản ghi điểm',
                '${s.grades.length}',
                Icons.insights_rounded,
                const Color(0xFFAA82C7),
                b.maxWidth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 27),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Danh sách sinh viên',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _go(1),
                    child: const Text('Xem tất cả →'),
                  ),
                ],
              ),
              const Text(
                'Một góc thông tin trong không gian học tập của bạn.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 18),
              if (s.students.isEmpty)
                const EmptyState(
                  title: 'Chưa có sinh viên',
                  message: 'Thêm hồ sơ đầu tiên để bắt đầu.',
                )
              else
                for (final v in s.students.take(4))
                  _studentRow(v, compact: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quick(
    String title,
    String sub,
    IconData icon,
    Color color,
    double available,
    VoidCallback tap,
  ) {
    final w = (available - 28) / 3;
    return SizedBox(
      width: w,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 10),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 39),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (available > 500) ...[
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: .85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shortcut(
    IconData icon,
    String label,
    Color color,
    VoidCallback tap,
  ) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
  Widget _stat(
    String label,
    String value,
    IconData icon,
    Color color,
    double available,
  ) => SizedBox(
    width: available < 550 ? (available - 12) / 2 : (available - 36) / 4,
    child: Panel(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 10, color: muted)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _students() {
    final rows = s.students
        .where(
          (v) =>
              (_classFilter == null || v.classId == _classFilter) &&
              '${v.studentId} ${v.name} ${v.major}'.toLowerCase().contains(
                _search.toLowerCase(),
              ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Quản lý sinh viên',
          '${s.students.length} hồ sơ · Thông tin học tập trong tầm tay',
          action: FilledButton.icon(
            onPressed: () => _studentForm(),
            icon: const Icon(Icons.add, size: 19),
            label: const Text('Thêm sinh viên'),
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchInput,
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Tìm tên, mã sinh viên hoặc ngành…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả lớp'),
                    selected: _classFilter == null,
                    onSelected: (_) => setState(() => _classFilter = null),
                  ),
                  for (final c in s.classes)
                    ChoiceChip(
                      label: Text(c.id),
                      selected: _classFilter == c.id,
                      onSelected: (_) => setState(() => _classFilter = c.id),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              if (rows.isEmpty)
                const EmptyState(
                  title: 'Không có sinh viên phù hợp',
                  message: 'Thử từ khóa khác hoặc thêm hồ sơ mới.',
                )
              else
                for (final v in rows) _studentRow(v),
              const SizedBox(height: 10),
              Text(
                'Hiển thị ${rows.length} hồ sơ',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _studentRow(Student v, {bool compact = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFEDF2F5))),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: const Color(0xFFE6F4ED),
          child: Text(
            _initial(v.name),
            style: const TextStyle(color: green, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: InkWell(
            onTap: () => _studentDetail(v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${v.studentId} · ${v.classId ?? 'Chưa xếp lớp'}',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ),
        if (MediaQuery.sizeOf(context).width > 800)
          Expanded(
            child: Text(
              v.major,
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ),
        if (compact)
          const Icon(Icons.chevron_right_rounded, color: muted)
        else
          PopupMenuButton<String>(
            tooltip: 'Thao tác ${v.studentId}',
            onSelected: (value) {
              if (value == 'edit') {
                _studentForm(v);
              } else if (value == 'delete') {
                _delete(v);
              } else {
                _studentDetail(v);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('Xem hồ sơ')),
              const PopupMenuItem(value: 'edit', child: Text('Sửa thông tin')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Xóa sinh viên'),
              ),
            ],
          ),
      ],
    ),
  );

  void _studentDetail(Student v) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(v.name),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detail('Mã sinh viên', v.studentId),
              _detail('Ngành', v.major),
              _detail('Tuổi', '${v.age}'),
              _detail('Email', v.email.isEmpty ? 'Chưa cập nhật' : v.email),
              _detail('Lớp', s.className(v.classId)),
              _detail(
                'Trung bình có trọng số (mọi kỳ)',
                s.averageFor(v.studentId)?.toStringAsFixed(2) ?? 'Chưa có điểm',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              _studentForm(v);
            },
            child: const Text('Sửa hồ sơ'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: muted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _classes() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        'Không gian lớp học',
        '${s.classes.length} lớp · Kết nối sinh viên cùng ngành và khóa',
        action: FilledButton.icon(
          onPressed: () => _classForm(),
          icon: const Icon(Icons.add, size: 19),
          label: const Text('Thêm lớp học'),
        ),
      ),
      if (s.classes.isEmpty)
        const Panel(
          child: EmptyState(
            title: 'Chưa có lớp học',
            message: 'Tạo lớp học đầu tiên cho nhóm sinh viên.',
          ),
        ),
      LayoutBuilder(
        builder: (context, box) => Wrap(
          spacing: 18,
          runSpacing: 18,
          children: s.classes.map((c) {
            final count = s.students.where((v) => v.classId == c.id).length;
            return SizedBox(
              width: box.maxWidth < 650
                  ? box.maxWidth
                  : (box.maxWidth - 18) / 2,
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4D8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.meeting_room_rounded,
                            color: Color(0xFFD8A42B),
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        Pill(c.cohort, color: const Color(0xFF6A8DBC)),
                        IconButton(
                          tooltip: 'Sửa ${c.id}',
                          onPressed: () => _classForm(c),
                          icon: const Icon(Icons.more_horiz, color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${c.id} · ${c.major}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 17,
                          color: muted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$count sinh viên',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            _page = 1;
                            _classFilter = c.id;
                            _search = '';
                            _searchInput.clear();
                          }),
                          child: const Text('Xem lớp →'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );

  Widget _modules() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(
            value: 0,
            icon: Icon(Icons.menu_book_outlined),
            label: Text('Môn học'),
          ),
          ButtonSegment(
            value: 1,
            icon: Icon(Icons.assessment_outlined),
            label: Text('Bảng điểm'),
          ),
        ],
        selected: {_moduleTab},
        onSelectionChanged: (values) =>
            setState(() => _moduleTab = values.first),
      ),
      const SizedBox(height: 24),
      if (_moduleTab == 0)
        SubjectsScreen(subjects: s.subjects, onCreate: s.saveSubject)
      else
        GradesScreen(
          students: s.students,
          subjects: s.subjects,
          grades: s.grades,
          onSave: s.saveGrade,
        ),
    ],
  );

  Widget _profile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading('Hồ sơ của bạn', 'Thông tin tài khoản và không gian làm việc.'),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 33,
                  backgroundColor: Color(0xFFE4F5EB),
                  child: Icon(Icons.person_rounded, color: green, size: 39),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.profile.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Pill('Người quản lý'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detail('Email', s.profile.email),
            _detail(
              'Nguồn dữ liệu',
              s.isDemo
                  ? 'Dữ liệu mẫu · Lưu trên trình duyệt/thiết bị này'
                  : 'Firebase · Dữ liệu nhóm dùng chung',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => recordForm(
                    context,
                    title: 'Cập nhật họ tên',
                    subtitle: 'Chỉ sửa tên hiển thị. Email và quyền được quản lý riêng.',
                    fields: [
                      FieldSpec(
                        'name',
                        'Họ và tên',
                        value: s.profile.displayName,
                      ),
                    ],
                    onSave: (v) async {
                      await s.updateName(v['name']!);
                      _notice('Đã cập nhật hồ sơ.');
                    },
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Chỉnh sửa tên'),
                ),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giao diện mẫu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            // The Panel behind has a background color; ListTile needs its own
            // Material to paint ink, otherwise debug builds show an assertion.
            Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: () => _open(const LearningSampleScreen()),
                leading: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: green,
                ),
                title: const Text('Mẫu giao diện học tập · Câu 5'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _logout() async {
    try {
      await s.signOut();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _notice('Chưa đăng xuất được. Kiểm tra mạng rồi thử lại.');
    }
  }

  void _activityDialog() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Hoạt động trong phiên'),
      content: SizedBox(
        width: 390,
        child: s.activities.isEmpty
            ? const Text('Chưa có thay đổi nào trong phiên làm việc này.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: s.activities
                      .take(12)
                      .map(
                        (v) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Text('• $v'),
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
