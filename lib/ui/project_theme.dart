import 'package:flutter/material.dart';

const ink = Color(0xFF172D3B);
const muted = Color(0xFF75858E);
const green = Color(0xFF149A72);
const canvas = Color(0xFFF3F7FA);

ThemeData projectTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: green, surface: Colors.white),
  scaffoldBackgroundColor: canvas,
  fontFamily: 'Arial',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: ink,
      letterSpacing: -1,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: ink,
      letterSpacing: -.5,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.45),
    bodySmall: TextStyle(fontSize: 12, color: muted, height: 1.4),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF6F8FA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E8EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E8EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: green, width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      side: const BorderSide(color: Color(0xFFDCE6EA)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  dividerColor: const Color(0xFFEBF0F3),
);

/// Khung nội dung bo góc dùng chung cho các màn hình.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE8EEF1)),
    ),
    child: child,
  );
}

/// Nhãn nhỏ bo tròn (học kỳ, trạng thái).
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = green});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
    ),
  );
}

/// Trạng thái rỗng: biểu tượng và lời nhắn khi chưa có dữ liệu.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_rounded,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: muted.withValues(alpha: .5)),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    ),
  );
}
