import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../ui/project_theme.dart';

/// Danh sách môn học (US13, US14): tìm kiếm, thêm môn, kiểm tra mã trùng và tín chỉ hợp lệ.
class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({
    super.key,
    required this.subjects,
    required this.onCreate,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<Subject> subjects;
  final Future<void> Function(Subject) onCreate;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.subjects.where((subject) {
      final q = _query.toLowerCase();
      return subject.id.toLowerCase().contains(q) ||
          subject.name.toLowerCase().contains(q);
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách môn học',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${widget.subjects.length} môn học',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: widget.loading ? null : _addSubject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm môn'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: const InputDecoration(
            hintText: 'Tìm theo mã hoặc tên môn học',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.error != null)
          _ErrorBanner(message: widget.error!, onRetry: widget.onRetry),
        if (widget.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (rows.isEmpty)
          Panel(
            child: EmptyState(
              title: _query.isEmpty
                  ? 'Chưa có môn học'
                  : 'Không tìm thấy môn học',
              message: _query.isEmpty
                  ? 'Thêm môn học để bắt đầu quản lý.'
                  : 'Thử tìm bằng mã hoặc tên khác.',
              icon: Icons.menu_book_outlined,
            ),
          )
        else
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE3F5EE),
                      child: Text(
                        '${rows[i].credits}',
                        style: const TextStyle(
                          color: green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      rows[i].name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(rows[i].id),
                    trailing: const Text(
                      'tín chỉ',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                  if (i < rows.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _addSubject() async {
    final key = GlobalKey<FormState>();
    var idValue = '';
    var nameValue = '';
    var creditsValue = '3';
    var saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm môn học'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Mã môn học'),
                    onChanged: (value) => idValue = value,
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Vui lòng nhập mã môn học.';
                      if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(v)) {
                        return 'Mã chỉ gồm chữ không dấu, số, _ hoặc -.';
                      }
                      if (widget.subjects.any(
                        (s) => s.id.toLowerCase() == v.toLowerCase(),
                      )) {
                        return 'Mã môn học đã tồn tại.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Tên môn học'),
                    onChanged: (value) => nameValue = value,
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Vui lòng nhập tên môn học.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '3',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số tín chỉ'),
                    onChanged: (value) => creditsValue = value,
                    validator: (value) {
                      final n = int.tryParse(value?.trim() ?? '');
                      if (n == null || n < 1 || n > 10) {
                        return 'Tín chỉ phải là số nguyên từ 1 đến 10.';
                      }
                      return null;
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
                        await widget.onCreate(
                          Subject(
                            id: idValue.trim(),
                            name: nameValue.trim(),
                            credits: int.parse(creditsValue.trim()),
                          ),
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        setDialogState(() {
                          saving = false;
                          error = e is StateError
                              ? e.message.toString()
                              : e is FormatException
                              ? e.message
                              : 'Không lưu được môn học. Vui lòng thử lại.';
                        });
                      }
                    },
              child: Text(saving ? 'Đang lưu…' : 'Lưu môn'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Panel(
      padding: const EdgeInsets.all(14),
      color: const Color(0xFFFFF1F0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
