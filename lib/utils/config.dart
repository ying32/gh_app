import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App的配置，先弄个简单的测试下
class AppConfig {
  AppConfig._();

  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();

  SharedPreferences? _prefs;

  /// 认证的
  AuthField _auth = const AuthField(AuthType.anonymous, '');
  AuthField get auth => _auth;
  set auth(AuthField value) {
    if (value.authType == _auth.authType && value.token == _auth.token) {
      return;
    }
    _auth = value;
    _prefs?.setString('auth', jsonEncode(value.toJson()));
  }

  /// 镜像地址
  String _releaseFileAssetsMirrorUrl = '';
  String get releaseFileAssetsMirrorUrl => _releaseFileAssetsMirrorUrl;
  set releaseFileAssetsMirrorUrl(String value) {
    if (value == _releaseFileAssetsMirrorUrl) return;
    _releaseFileAssetsMirrorUrl = value;
    _prefs?.setString(
        'release_file_assets_mirror_url', _releaseFileAssetsMirrorUrl);
  }

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _auth = AuthField.fromJson(jsonDecode(_prefs!.getString("auth") ?? '{}'));
      _releaseFileAssetsMirrorUrl =
          _prefs!.getString('release_file_assets_mirror_url') ?? '';
    } catch (e) {
      if (kDebugMode) {
        print("加载配置失败=$e");
      }
    }
  }

  Future<void> load() async {}
}
