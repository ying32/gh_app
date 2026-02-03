import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gh_app/utils/utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class HTTPCache {
  HTTPCache();

  /// 缓存
  final _caches = <String, dynamic>{};

  /// 缓存根目录
  Future<String> get cacheRoot async =>
      p.join((await getApplicationSupportDirectory()).path, "Caches");

  /// 仓库缓存根目录
  Future<String> get repoCacheRoot async => p.join(await cacheRoot, "Repos");

  /// GraphQl API缓存目录
  Future<String> get apiCacheRoot async => p.join(await cacheRoot, "graphql");

  /// 生成key
  String genKey(String text) => md5String(text);

  /// 指定key是否已经缓存过了
  bool isCached(String key) => _caches.containsKey(key);

  /// 从缓存中加载
  Future<Map<String, dynamic>?> readCachedFile(String key) async {
    final file = File(p.join(await apiCacheRoot, key));
    if (await file.exists()) {
      try {
        return jsonDecode(
            utf8.decode(gzip.decoder.convert(await file.readAsBytes())));
      } catch (e) {
        //
      }
    }
    return null;
  }

  /// 写到缓存中
  Future<File?> writeFileCache(String key, Uint8List data) async {
    final dir = Directory((await apiCacheRoot))..createSync(recursive: true);
    try {
      final file = File(p.join(dir.path, key));
      // 打上标记
      _caches[key] = null;

      return file.writeAsBytes(gzip.encoder.convert(data), flush: true);
    } catch (e) {
      // 保存失败
    }
    return null;
  }
}
