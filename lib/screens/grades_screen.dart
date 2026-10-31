import 'package:flutter/material.dart';

import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../ui/project_theme.dart';

/// Bảng điểm (US15, US16): chọn sinh viên, xem điểm theo môn và học kỳ, nhập hoặc cập nhật điểm.
class GradesScreen extends StatefulWidget {
  const GradesScreen({
    super.key,
    required this.students,
    required this.subjects,
    required this.grades,
    required this.onSave,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<Student> students;
  final List<Subject> subjects;
  final List<Grade> grades;
  final Future<void> Function(Grade) onSave;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  String? _studentId;

  @override
  void didUpdateWidget(covariant GradesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_studentId != null &&
        !widget.students.any((s) => s.studentId == _studentId)) {
      _studentId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.students.any((s) => s.studentId == _studentId)
        ? _studentId
        : widget.students.firstOrNull?.studentId;
    final selectedStudent = widget.students
        .where((s) => s.studentId == selectedId)
        .firstOrNull;
    final rows =
        selectedId == null
              ? <Grade>[]
              : widget.grades.where((g) => g.studentId == selectedId).toList()
          ..sort((a, b) {
            final semester = b.semester.compareTo(a.semester);
            return semester != 0
                ? semester
                : a.subjectId.compareTo(b.subjectId);
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bảng điểm', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        const Text(
          'Nhập và tra cứu kết quả theo từng sinh viên.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 18),
        if (widget.error != null)
          Panel(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFFFF1F0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ),
                if (widget.onRetry != null)
                  TextButton(
                    onPressed: widget.onRetry,
                    child: const Text('Thử lại'),
                  ),
              ],
            ),
          ),
        Panel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sinh viên đang xem',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey(selectedId),
                initialValue: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Chọn sinh viên',
                ),
                items: widget.students
                    .map(
                      (student) => DropdownMenuItem(
                        value: student.studentId,
                        child: Text(
                          '${student.name} · ${student.studentId}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.students.isEmpty
                    ? null
                    : (value) => setState(() => _studentId = value),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      widget.loading ||
                          widget.students.isEmpty ||
                          widget.subjects.isEmpty
                      ? null
                      : _addGrade,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nhập / cập nhật điểm'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (widget.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (selectedStudent == null)
          const Panel(child: Text('Thêm sinh viên trước khi nhập điểm.'))
        else if (rows.isEmpty)
          Panel(
            child: Center(
              child: Text(
                '${selectedStudent.name} chưa có điểm.',
                style: const TextStyle(color: muted),
              ),
            ),
          )
        else
          Panel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kết quả của ${selectedStudent.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                for (final grade in rows)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFEBF0F3))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _subjectName(grade.subjectId),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${grade.subjectId} · ${grade.semester}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F5EE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            grade.score.toStringAsFixed(
                              grade.score == grade.score.roundToDouble()
                                  ? 0
                                  : 1,
                            ),
                            style: const TextStyle(
                              color: green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _subjectName(String id) =>
      widget.subjects.where((s) => s.id == id).firstOrNull?.name ?? id;

  Future<void> _addGrade() async {
    final key = GlobalKey<FormState>();
    var semesterValue = '${DateTime.now().year}-1';
    var scoreValue = '';
    String? studentId = widget.students.any((s) => s.studentId == _studentId)
        ? _studentId
        : widget.students.first.studentId;
    String? subjectId = widget.subjects.first.id;
    var saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nhập điểm sinh viên'),
          content: SizedBox(
            width: 430,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: studentId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sinh viên'),
                    items: widget.students
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.studentId,
                            child: Text(
                              '${s.name} · ${s.studentId}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) => setDialogState(() => studentId = value),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn sinh viên.' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: subjectId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Môn học'),
                    items: widget.subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '${s.name} · ${s.id}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) => setDialogState(() => subjectId = value),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn môn học.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: semesterValue,
                    decoration: const InputDecoration(
                      labelText: 'Học kỳ',
                      hintText: '2026-1',
                    ),
                    onChanged: (value) => semesterValue = value,
                    validator: (value) =>
                        RegExp(r'^\d{4}-[12]$').hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Học kỳ có dạng YYYY-1 hoặc YYYY-2.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Điểm',
                      hintText: '0–10',
                    ),
                    onChanged: (value) => scoreValue = value,
                    validator: (value) {
                      final n = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      return n != null && n >= 0 && n <= 10
                          ? null
                          : 'Điểm phải là số từ 0 đến 10.';
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error!,
                        style: const TextStyle(color: Color(0xFFB42318)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await widget.onSave(
                          Grade(
                            studentId: studentId!,
                            subjectId: subjectId!,
                            semester: semesterValue.trim(),
                            score: double.parse(
                              scoreValue.trim().replaceAll(',', '.'),
                            ),
                          ),
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) setState(() => _studentId = studentId);
                      } catch (e) {
                        setDialogState(() {
                          saving = false;
                          error = e is StateError
                              ? e.message.toString()
                              : e is FormatException
                              ? e.message
                              : 'Không lưu được điểm. Vui lòng thử lại.';
                        });
                      }
                    },
              child: Text(saving ? 'Đang lưu…' : 'Lưu điểm'),
            ),
          ],
        ),
      ),
    );
  }
}
