import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
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

  static const _encryptKey = [
    0xBC,
    0x59,
    0x55,
    0x33,
    0x26,
    0x97,
    0x6A,
    0xF6,
    0x79,
    0x96,
    0x79,
    0x96,
    0xEC,
    0xC7,
    0x64,
    0x7D,
    0x95,
    0x6B,
    0x7A,
    0x5F,
    0xDF,
    0xC6,
    0xD4,
    0x16,
    0x8F,
    0xB5,
    0x12,
    0xF0,
    0xBF,
    0xE6,
    0xEC,
    0x3B
  ];
  static const _encryptIV = [
    0xC1,
    0xC7,
    0x2F,
    0x68,
    0xCC,
    0x5B,
    0xCF,
    0x72,
    0x21,
    0x3F,
    0xF4,
    0xE0,
    0xA1,
    0xA5,
    0x1E,
    0x8B
  ];

  final _key = encrypt.Key(Uint8List.fromList(_encryptKey));
  final _iv = encrypt.IV(Uint8List.fromList(_encryptIV));

  String _encryptText(String text) =>
      encrypt.Encrypter(encrypt.AES(_key)).encrypt(text, iv: _iv).base64;

  String _decryptText(String base64Text) => encrypt.Encrypter(encrypt.AES(_key))
      .decrypt(encrypt.Encrypted.fromBase64(base64Text), iv: _iv);

  String _getEncryptedAuthData(AuthField value) {
    try {
      return _encryptText(jsonEncode(value.toJson()));
    } catch (e) {
      //
    }
    return '';
  }

  Map<String, dynamic> _getDecryptedAuthData(String? text) {
    if (text?.isEmpty ?? true) {
      return {};
    }
    try {
      return jsonDecode(_decryptText(text!));
    } catch (e) {
      //
    }
    return {};
  }

  /// 认证的
  AuthField _auth = const AuthField(AuthType.anonymous, '');
  AuthField get auth => _auth;
  set auth(AuthField value) {
    if (value.authType == _auth.authType && value.token == _auth.token) {
      return;
    }
    _auth = value;
    _prefs?.setString('auth', _getEncryptedAuthData(value));
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
      _auth =
          AuthField.fromJson(_getDecryptedAuthData(_prefs!.getString("auth")));

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
