import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App的配置，先弄个简单的测试下
class AppConfig {
  AppConfig._();

  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();

  SharedPreferences? _prefs;

  /// 认证的
  AuthField get auth =>
      AuthField.fromJson(jsonDecode(_prefs?.getString("auth") ?? '{}'));
  set auth(AuthField value) =>
      _prefs?.setString('auth', jsonEncode(value.toJson()));

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      if (kDebugMode) {
        print("加载配置失败=$e");
      }
    }
  }

  Future<void> load() async {}
}
