import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fluent_ui/fluent_ui.dart' as fui;
import 'package:fluent_ui/fluent_ui.dart';
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

bool snapshotIsOk<T>(
  fui.AsyncSnapshot<T> snapshot, [
  bool checkData = true,
  bool checkError = true,
]) {
  return snapshot.connectionState == fui.ConnectionState.done &&
      (checkData ? snapshot.hasData : true) &&
      (checkError ? !snapshot.hasError : true);
}

/// 转换十六进制颜色
Color hexColorTo(String text) {
  if (text.startsWith("#")) text = text.substring(1);
  if (text.length == 3) {
    text = "${text[0] * 2}, ${text[1] * 2}, ${text[2] * 2}";
  }
  return Color(int.tryParse("ff$text", radix: 16) ?? 0);
}

/// md5
String md5String(String text) =>
    md5.convert(utf8.encode(text)).toString().toLowerCase();
