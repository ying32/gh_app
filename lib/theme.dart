import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';

final appTheme = AppTheme();

class AppTheme extends ChangeNotifier {
  AccentColor? _color;
  AccentColor get color => _color ?? Colors.red; //?? systemAccentColor;
  set color(AccentColor color) {
    _color = color;
    notifyListeners();
  }

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  set mode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  bool get isDark => _mode == ThemeMode.dark;

  String? _fontFamily = Platform.isWindows ? '微软雅黑' : null;
  String? get fontFamily => _fontFamily;
  set fontFamily(String? value) {
    _fontFamily = value;
    notifyListeners();
  }

  Locale? _locale;
  Locale? get locale => _locale;
  set locale(Locale? locale) {
    _locale = locale;
    notifyListeners();
  }
}
