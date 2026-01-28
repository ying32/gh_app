import 'dart:convert';
import 'dart:io';

import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 全局的github实例
GitHub? github;

/// 认证类型
enum AuthType {
  accessToken,
  oauth2,
  userPassword,
}

class AuthField {
  const AuthField(this.authType, this.tokenOrUserName, [this.password]);
  final AuthType authType;
  final String tokenOrUserName;
  final String? password;

  Map<String, dynamic> toJson() => {
        "auth_type": authType.name,
        "token_or_username": tokenOrUserName,
        if (password != null) "password": password,
      };

  AuthField.fromJson(Map<String, dynamic> json)
      : authType = enumFromStringValue(
            AuthType.values, json['auth_type'], AuthType.accessToken),
        tokenOrUserName = json['token_or_username'] ?? '',
        password = json['password'];
}

/// 创建github实例，根据配置的类型
bool createGithub(AuthField value) {
  // 其实不判断也没事，反正那啥一样
  if (value.tokenOrUserName.isEmpty) return false;
  github = switch (value.authType) {
    AuthType.accessToken =>
      GitHub(auth: Authentication.bearerToken(value.tokenOrUserName)),
    AuthType.oauth2 =>
      GitHub(auth: Authentication.withToken(value.tokenOrUserName)),
    AuthType.userPassword =>
      GitHub(auth: Authentication.basic(value.tokenOrUserName, value.password)),
  };
  return true;
}

void clearGithubInstance() {
  github = null;
}

class GithubCache {
  GithubCache._();

  static GithubCache? _instance;
  static GithubCache get instance => _instance ??= GithubCache._();

  CurrentUser? _currentUser;

  /// 缓存
  final _responsesCache = <String, dynamic>{};

  /// 当前user信息
  Future<CurrentUser?> get currentUser async =>
      _currentUser ??= await github?.users.getCurrentUser();

  /// 缓存根目录
  Future<String> get cacheRoot async =>
      p.join((await getApplicationSupportDirectory()).path, "RepoCaches");

  /// 缓存
  bool hasCache(String key) => _responsesCache.containsKey(key);

  /// 从缓存中加载
  T? loadCache<T>(String key) {
    final value = _responsesCache[key];
    if (value == null || value is! T) return null;
    return value;
  }

  /// 存到缓存中
  T? storeToCache<T>(String key, T? value) {
    if (value == null) return value;
    _responsesCache[key] = value;
    return value;
  }

  /// 获取仓库列表信息
  Future<List<Repository>?> userRepos(String owner) async {
    final key = "$owner/repos";
    if (hasCache(key)) {
      return loadCache(key);
    }
    try {
      return storeToCache(
          key,
          await (owner.isEmpty
                  ? github?.repositories.listRepositories()
                  : github?.repositories.listUserRepositories(owner))
              ?.toList());
    } catch (e) {
      //
    }
    return null;
  }

  Future<List<Branch>?> repoBranches(Repository repo) async {
    final slug = RepositorySlug(repo.owner!.login, repo.name);
    final key = slug.fullName;
    if (hasCache(key)) {
      return loadCache(key);
    }
    try {
      return storeToCache(
          key, await github?.repositories.listBranches(slug).toList());
    } catch (e) {
      //
    }
    return null;
  }

  Future<List<Release>?> repoReleases(Repository repo) async {
    final slug = RepositorySlug(repo.owner!.login, repo.name);
    final key = slug.fullName;
    if (hasCache(key)) {
      return loadCache(key);
    }
    try {
      return storeToCache(
          key, await github?.repositories.listReleases(slug).toList());
    } catch (e) {
      //
    }
    return null;
  }

  /// README缓存
  Future<String?> repoReadMe(Repository repo, {String? ref}) async {
    final slug = RepositorySlug(repo.owner!.login, repo.name);
    final key = "${slug.fullName}${ref ?? ''}";
    if (hasCache(key)) {
      return loadCache(key);
    }
    try {
      return storeToCache(
          key, (await github?.repositories.getReadme(slug, ref: ref))?.text);
    } catch (e) {
      storeToCache(key, "");
    }
    return null;
  }

  /// 目录内容缓存
  Future<RepositoryContents?> repoContents(Repository repo, String path,
      {String? ref}) async {
    final slug = RepositorySlug(repo.owner!.login, repo.name);
    final key = "${slug.fullName}$path/${ref ?? ''}";
    if (hasCache(key)) {
      return loadCache(key);
    }

    final content =
        await github?.repositories.getContents(slug, path, ref: ref);
    if (content != null) {
      // 如果是文件，则不保存在内存缓存中，直接写入磁盘
      if (content.isFile) {
        // 先放这吧
        // _writeCacheFile(slug, content.file);
      }
      return storeToCache(key, content);
    }
    return null;
  }

  Future _writeCacheFile(RepositorySlug slug, GitHubFile? file) async {
    if (file == null || file.path == null) return;
    final cacheFile = File(p.join(await cacheRoot, slug.owner, slug.name,
        file.path?.replaceAll('/', Platform.pathSeparator)));
    if (await cacheFile.exists()) return;
    await cacheFile.create(recursive: true);
    // file.encoding 要判断编码，目前只知道base64
    return cacheFile.writeAsBytesSync(
        base64Decode(file.content!.replaceAll("\n", "")),
        flush: true);
  }
}

/// 登录
// Future<bool> login(AuthField value) async {
//   return false;
// }
