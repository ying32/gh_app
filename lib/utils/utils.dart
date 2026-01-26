import 'package:fluent_ui/fluent_ui.dart' as fui;
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

/// 时间转易读的标签
String timeToLabel(DateTime? dateTime) {
  if (dateTime == null) return '';

  const minute = 60;
  const hour = 60 * minute;
  const day = 24 * hour;
  // const week = 7 * day;
  const month = 30 * day;
  const year = 12 * month;

  final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000 -
      dateTime.millisecondsSinceEpoch ~/ 1000;

  return switch (seconds) {
    0 => '刚刚',
    < minute => '$seconds秒前',
    < hour => '${seconds ~/ minute}分钟前',
    < day => '${seconds ~/ hour}小时前',
    // < week => '${seconds ~/ week}周前',
    < month => '${seconds ~/ day}天前',
    < year => '${seconds ~/ month}个月前',
    >= year => '${seconds ~/ year}年前',
    _ => "",
  };
}

bool snapshotIsOk<T>(fui.AsyncSnapshot<T> snapshot, [bool checkData = true]) {
  return snapshot.connectionState == fui.ConnectionState.done &&
      (checkData ? snapshot.hasData : true) &&
      !snapshot.hasError;
}
