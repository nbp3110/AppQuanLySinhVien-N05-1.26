import 'package:flutter/material.dart';

import 'project_theme.dart';

/// Mô tả một ô nhập của form: nhãn, giá trị đầu và hàm kiểm tra.
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.value = '',
    this.options,
    this.number = false,
    this.locked = false,
    this.optional = false,
  });
  final String key, label, value;
  final Map<String, String>? options;
  final bool number, locked, optional;
}

/// Mở hộp thoại form dùng chung; chỉ lưu khi mọi ô hợp lệ, lỗi giữ nguyên dữ liệu đã nhập.
Future<void> recordForm(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<FieldSpec> fields,
  required Future<void> Function(Map<String, String>) onSave,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _RecordForm(
    title: title,
    subtitle: subtitle,
    fields: fields,
    onSave: onSave,
  ),
);

class _RecordForm extends StatefulWidget {
  const _RecordForm({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.onSave,
  });
  final String title, subtitle;
  final List<FieldSpec> fields;
  final Future<void> Function(Map<String, String>) onSave;
  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _inputs = {
    for (final f in widget.fields) f.key: TextEditingController(text: f.value),
  };
  bool _busy = false;
  String? _error;
  Future<void> _save() async {
    if (_busy || !_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave({
        for (final entry in _inputs.entries) entry.key: entry.value.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is FormatException
              ? e.message
              : e is StateError
              ? e.message.toString()
              : 'Không lưu được dữ liệu. Kiểm tra mạng/quyền truy cập rồi thử lại.';
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 24),
                for (final f in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: f.options == null
                        ? TextFormField(
                            controller: _inputs[f.key],
                            enabled: !_busy && !f.locked,
                            keyboardType: f.number
                                ? const TextInputType.numberWithOptions(
                                    decimal: true,
                                  )
                                : TextInputType.text,
                            decoration: InputDecoration(
                              labelText: f.label,
                              suffixIcon: f.locked
                                  ? const Icon(Icons.lock_outline, size: 17)
                                  : null,
                            ),
                            validator: (v) =>
                                !f.optional && (v == null || v.trim().isEmpty)
                                ? 'Vui lòng nhập ${f.label.toLowerCase()}'
                                : null,
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: f.value,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: f.label),
                            items: f.options!.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _busy
                                ? null
                                : (v) => _inputs[f.key]!.text = v ?? '',
                            validator: (v) =>
                                !f.optional && (v == null || v.isEmpty)
                                ? 'Vui lòng chọn ${f.label.toLowerCase()}'
                                : null,
                          ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFCD4439)),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _save,
                        child: Text(_busy ? 'Đang lưu…' : 'Lưu thông tin'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
