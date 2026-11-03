import 'package:flutter/material.dart';

/// โทนสีของร้าน "Sweet Crumb Bakery"
/// โทนอบอุ่น: ครีม • คาราเมล • ช็อกโกแลต • ชมพูสตรอว์เบอร์รี
class AppColors {
  static const Color cream = Color(0xFFFFF8EE); // พื้นหลัง
  static const Color butter = Color(0xFFFCEBD3); // พื้นการ์ด/ชิป
  static const Color caramel = Color(0xFFC8763A); // สีหลัก
  static const Color cocoa = Color(0xFF4E342E); // ตัวอักษร/หัวข้อ
  static const Color mocha = Color(0xFF8D6E63); // ตัวอักษรรอง
  static const Color strawberry = Color(0xFFE5737F); // สีเน้น/ราคา
  static const Color mint = Color(0xFF7FB77E); // สถานะสำเร็จ
  static const Color white = Colors.white;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.caramel,
    primary: AppColors.caramel,
    secondary: AppColors.strawberry,
    surface: AppColors.cream,
    onSurface: AppColors.cocoa,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.cocoa,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.cocoa,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.cocoa),
      bodyLarge: TextStyle(color: AppColors.cocoa),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shadowColor: AppColors.cocoa.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.butter, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.caramel, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.caramel,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.strawberry,
      foregroundColor: AppColors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.butter,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.white,
      selectedColor: AppColors.caramel,
      side: const BorderSide(color: AppColors.butter),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

/// แปลงตัวเลขเป็นราคา เช่น 1250 -> ฿1,250
String formatPrice(num value) {
  final fixed = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final buf = StringBuffer();
  final digits = parts[0];
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '฿$buf${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// แปลงวันที่ ISO เป็นรูปแบบ dd/MM/yyyy HH:mm
String formatDate(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

