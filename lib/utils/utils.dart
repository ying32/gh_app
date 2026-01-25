import 'package:flutter/foundation.dart';

/// Checks if the current environment is a desktop environment.
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

/// 整型转枚举
E enumFromIntValue<E extends Enum>(Iterable<E> values, int value, E defValue) =>
    values.firstWhere((e) => e.index == value, orElse: () => defValue);

/// String转枚举
E enumFromStringValue<E extends Enum>(
        Iterable<E> values, String? value, E defValue) =>
    values.firstWhere((e) => e.name == value, orElse: () => defValue);

/// 皮肤对应的颜色
const themeModeStrings = ['跟随系统', '浅色模式', '深色模式'];
