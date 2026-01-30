import 'dart:io';
import 'dart:typed_data';

import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 带缓存功能的
class CacheGitHub extends GitHub {
  CacheGitHub({
    super.auth,
    super.endpoint,
    super.version,
    super.client,
    this.isGraphQL = false,
  });

  final bool isGraphQL;

  /// 缓存
  final _caches = <String, dynamic>{};

  /// 缓存根目录
  Future<String> get cacheRoot async =>
      p.join((await getApplicationSupportDirectory()).path, "Caches");

  /// 仓库缓存根目录
  Future<String> get repoCacheRoot async => p.join(await cacheRoot, "Repos");

  /// REST API缓存根目录
  Future<String> get restfulApiCacheRoot async =>
      p.join(await cacheRoot, "restful");

  /// GraphQl API缓存目录
  Future<String> get graphqlApiCacheRoot async =>
      p.join(await cacheRoot, "graphql");

  /// 从缓存中加载
  Future<Uint8List?> _readCachedFile(String key) async {
    final file = File(p.join(
        await (isGraphQL ? graphqlApiCacheRoot : restfulApiCacheRoot), key));
    if (await file.exists()) {
      try {
        return file.readAsBytes();
      } catch (e) {
        //
      }
    }
    return null;
  }

  /// 写到缓存中
  Future<File?> _writeFileCache(String key, Uint8List data) async {
    final dir =
        Directory(await (isGraphQL ? graphqlApiCacheRoot : restfulApiCacheRoot))
          ..createSync(recursive: true);
    try {
      final file = File(p.join(dir.path, key));
      // 打上标记
      _caches[key] = null;
      return file.writeAsBytes(data, flush: true);
    } catch (e) {
      // 保存失败
    }
    return null;
  }

  String _paramsToString(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    final buff = StringBuffer();
    final keys = params.keys.toList()..sort();
    for (final key in keys) {
      buff.write("$key=${params[key]},");
    }
    return buff.toString();
  }

  @override
  Future<http.Response> request(
    String method,
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    dynamic body,
    int? statusCode,
    void Function(http.Response response)? fail,
    String? preview,
  }) async {
    final key =
        md5String("$method:$endpoint:$path:${_paramsToString(params)}:$body");

    /// 一个简易的
    Future<http.Response> doRequest() async {
      final res = await super.request(method, path,
          headers: headers,
          params: params,
          body: body,
          statusCode: statusCode,
          fail: fail,
          preview: preview);
      // 200的时候才写数据
      if (res.statusCode == 200) {
        _writeFileCache(key, res.bodyBytes);
      }
      return res;
    }

    // 已经缓存了，直接返回缓存
    final data = await _readCachedFile(key);
    if (data != null && data.isNotEmpty) {
      // 本次是否已经更新过缓存了
      if (!_caches.containsKey(key)) {
        // 这个更新了怎么通知呢？
        doRequest();
      }
      return http.Response.bytes(data, 200,
          headers: {"content-type": "application/json; charset=utf-8"});
    }

    return doRequest();
  }
}
