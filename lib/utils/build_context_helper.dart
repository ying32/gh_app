import 'package:flutter/material.dart';

extension BuildContextHelper on BuildContext {
  /// 主题
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  /// 是否为暗黑模式
  bool get isDark => colorScheme.brightness == Brightness.dark;

  /// 是否为明亮模式
  bool get isLight => colorScheme.brightness == Brightness.light;

  /// 主题主色
  Color? get primaryColor => colorScheme.primary;

  /// 当前主题平台定义
  TargetPlatform get platform => theme.platform;
}
