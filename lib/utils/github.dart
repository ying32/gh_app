import 'dart:convert';
import 'dart:io';

import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// GraphQL查询
class GitHubGraphQL {
  GitHubGraphQL({
    this.auth = const Authentication.anonymous(),
    this.endpoint = 'https://api.github.com/graphql',
  }) : _github = GitHub(auth: auth, endpoint: endpoint, version: '');

  /// Authentication Information
  Authentication auth;

  /// API Endpoint
  final String endpoint;

  /// github实例
  final GitHub _github;

  Future<T> query<S, T>(
    String body, {
    int? statusCode,
    void Function(http.Response response)? fail,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    JSONConverter<S, T?>? convert,
  }) async {
    //convert ??= (input) => input as T?;
    headers ??= {};
    //headers.putIfAbsent('Accept', () => v3ApiMimeType);
    final response = await _query(body,
        headers: headers, params: params, statusCode: statusCode, fail: fail);
    final json = jsonDecode(response.body);
    // 有错误，这个错误在定义了[statusCode]时会解析
    // {"message":"Problems parsing JSON","documentation_url":"https://docs.github.com/graphql","status":"400"}
    // 实际为422错误，但没有哈
    // {"errors":[{"path":["query","DSD"],"extensions":{"code":"undefinedField","typeName":"Query","fieldName":"DSD"},"locations":[{"line":11,"column":4}],"message":"Field 'DSD' doesn't exist on type 'Query'"}]}
    // 这个错误貌似依然返回200？
    if (json['errors'] != null && statusCode == 200) {
      // 按理说应该状态码返回422，但没返回的原因是啥？？？？
      //response = response.o = 422;
      // 有错误了，这里他错误了也会返回个200，造成原来的解析不了
      _github.handleStatusCode(response);
    }
    // 实际数据节点
    final data = json['data']; // ?? json
    if (data == null) {
      // ???
    }
    if (convert == null) {
      return data;
    }
    final returnValue = convert(data) as T;
    return returnValue;
  }

  //  "Content-Type: application/json",
  //   "Accept: application/vnd.github.v4.idl"
  /// 查询方法，先不公开，嗯，也许另有打算吧
  Future<http.Response> _query(
    String body, {
    int? statusCode,
    void Function(http.Response response)? fail,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
  }) async =>
      _request(
          '{ "query": "${body.replaceAll('"', r'\"').replaceAll(RegExp(r'\r|\n'), r"\n")}" }',
          statusCode: statusCode,
          fail: fail,
          headers: headers,
          params: params);

  /// 忽略path字段，强制为[endpoint]，本可不这样做的，但是他内部的[request]方法在判断[path]时
  /// 附加了一个”/“符号，造成服务端识为这是一个rest API。
  /// 暂时不公开，之后再看吧
  Future<http.Response> _request(
    String body, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    int? statusCode,
    void Function(http.Response response)? fail,
  }) async {
    //print("body: $body");
    return _github.request("POST", endpoint,
        headers: headers,
        params: params,
        body: body,
        statusCode: statusCode,
        fail: fail,
        preview: null);
  }
}

class GitHubAPI {
  GitHubAPI({
    this.auth = const Authentication.anonymous(),
  })  : restful = GitHub(auth: auth),
        graphql = GitHubGraphQL(auth: auth);

  /// Authentication Information
  final Authentication auth;

  /// V3版本API，使用Restful操作的
  final GitHub restful;

  /// V4版本API，使用GraphQL操作的
  final GitHubGraphQL graphql;
}

/// 默认的API
GitHubAPI gitHubAPI = GitHubAPI();

/// 认证类型
enum AuthType {
  anonymous,
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
            AuthType.values, json['auth_type'], AuthType.anonymous),
        tokenOrUserName = json['token_or_username'] ?? '',
        password = json['password'];
}

/// 创建github实例，根据配置的类型
bool createGithub(AuthField value) {
  // 其实不判断也没事，反正那啥一样
  if (value.tokenOrUserName.isEmpty) return false;
  switch (value.authType) {
    case AuthType.accessToken:
      gitHubAPI =
          GitHubAPI(auth: Authentication.bearerToken(value.tokenOrUserName));
    case AuthType.oauth2:
      gitHubAPI =
          GitHubAPI(auth: Authentication.withToken(value.tokenOrUserName));
    case AuthType.userPassword:
      gitHubAPI = GitHubAPI(
          auth: Authentication.basic(value.tokenOrUserName, value.password));
    default:
      gitHubAPI = GitHubAPI();
  }
  return true;
}

void clearGithubInstance() {
  gitHubAPI = GitHubAPI();
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
      _currentUser ??= (gitHubAPI.auth.isAnonymous
          ? null
          : await gitHubAPI.restful.users.getCurrentUser());

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

  /// 缓存
  bool hasCache(String key) => _responsesCache.containsKey(md5String(key));

  /// 从缓存中加载
  Future<T?> loadCache<S, T2, T>(String key,
      [JSONConverter<S, T2>? converter]) async {
    key = md5String(key);
    final value = _responsesCache[key];
    // if (value == null) {
    //   // 缓存文件
    //   final file = File(p.join(await restfulApiCacheRoot, key));
    //   if (file.existsSync()) {
    //     //
    //   }
    // }

    if (value == null || value is! T) return null;
    return value;
  }

  ///
  Future<List<User>?> userFollowers([String owner = '']) async {
    final key = "userFollowers:$owner";
    if (hasCache(key)) {
      return loadCache(key, User.fromJson);
    }
    try {
      return storeToCache(
          key,
          await (owner.isEmpty
                  ? gitHubAPI.restful.users.listCurrentUserFollowers()
                  : gitHubAPI.restful.users.listUserFollowers(owner))
              .toList());
    } catch (e) {
      //
    }
    return null;
  }

  Future<List<User>?> userFollowing([String owner = '']) async {
    final key = "userFollowing:$owner";
    if (hasCache(key)) {
      return loadCache(key, User.fromJson);
    }
    try {
      return storeToCache(
        key,
        await gitHubAPI.restful.users.listCurrentUserFollowing().toList(),
        // await (owner.isEmpty
        //     ? githubV3.users.listCurrentUserFollowing()
        //     : )
        //     .toList(),
      );
    } catch (e) {
      //
    }
    return null;
  }

  /// 存到缓存中
  Future<T?> storeToCache<T>(String key, T? value) async {
    if (value == null) return value;
    key = md5String(key);
    _responsesCache[key] = value;
    // final dir = Directory(await restfulApiCacheRoot)
    //   ..createSync(recursive: true);
    // try {
    //   final file = File(p.join(dir.path, key));
    //   final body = value is String ? value : jsonEncode(value);
    //   if (body.isNotEmpty) {
    //     file.writeAsString(body, flush: true);
    //   }
    // } catch (e) {
    //   // 保存失败
    // }
    return value;
  }

  /// 获取仓库列表信息
  Future<List<Repository>?> userRepos(String owner) async {
    final key = "repos:$owner";
    if (hasCache(key)) {
      return loadCache(key, Repository.fromJson);
    }
    try {
      return storeToCache(
          key,
          await (owner.isEmpty
                  ? gitHubAPI.restful.repositories.listRepositories()
                  : gitHubAPI.restful.repositories.listUserRepositories(owner))
              .toList());
    } catch (e) {
      print("====================userRepos=$owner, error=$e");
    }
    return null;
  }

  Future<Repository?> userRepo(String owner, String name) async {
    final slug = RepositorySlug(owner, name);
    final key = "repo:${slug.fullName}";
    if (hasCache(key)) {
      return loadCache(key, Repository.fromJson);
    }
    try {
      return storeToCache(
          key, await gitHubAPI.restful.repositories.getRepository(slug));
    } catch (e) {
      //
    }
    return null;
  }

  Future<List<Branch>?> repoBranches(Repository repo) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);
    final key = "branches:${slug.fullName}";
    if (hasCache(key)) {
      return loadCache(key, Branch.fromJson);
    }
    try {
      return storeToCache(key,
          await gitHubAPI.restful.repositories.listBranches(slug).toList());
    } catch (e) {
      //
    }
    return null;
  }

  Future<List<Release>?> repoReleases(Repository repo) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);
    final key = "release:${slug.fullName}";
    if (hasCache(key)) {
      return loadCache(key, Release.fromJson);
    }
    try {
      return storeToCache(key,
          await gitHubAPI.restful.repositories.listReleases(slug).toList());
    } catch (e) {
      //
    }
    return null;
  }

  Future<List<Issue>?> repoIssues(Repository repo, {bool isOpen = true}) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);
    //final state = isOpen ? 'OPEN' : 'CLOSED';
    final state = isOpen ? 'open' : 'closed'; //open, closed, all
    final key = "issues:${slug.fullName}/$state";
    if (hasCache(key)) {
      return loadCache(key, Issue.fromJson);
    }
    try {
      return storeToCache(
          key,
          await gitHubAPI.restful.issues
              .listByRepo(slug, state: state)
              .toList());
    } catch (e) {
      //
    }
    return null;
  }

  Future<List<PullRequest>?> repoPullRequests(Repository repo,
      {bool isOpen = true}) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);
    final state = isOpen ? 'open' : 'closed'; //open, closed, all
    final key = "pullRequests:${slug.fullName}/$state";
    if (hasCache(key)) {
      return loadCache(key, PullRequest.fromJson);
    }
    try {
      return storeToCache(
          key,
          await gitHubAPI.restful.pullRequests
              .list(slug, state: state)
              .toList());
    } catch (e) {
      //
    }
    return null;
  }

  /// README缓存
  Future<String?> repoReadMe(Repository repo, {String? ref}) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);
    final key = "readme:${slug.fullName}/${ref ?? ''}";
    if (hasCache(key)) {
      return loadCache(key);
    }
    try {
      return storeToCache(
          key,
          (await gitHubAPI.restful.repositories.getReadme(slug, ref: ref))
              .text);
    } catch (e) {
      storeToCache(key, "");
    }
    return null;
  }

  /// 目录内容缓存
  Future<RepositoryContents?> repoContents(Repository repo, String path,
      {String? ref}) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);
    final key = "contents:${slug.fullName}/$path/${ref ?? ''}";
    if (hasCache(key)) {
      return loadCache(key, RepositoryContents.fromJson);
    }
    final content =
        await gitHubAPI.restful.repositories.getContents(slug, path, ref: ref);
    // 如果是文件，则不保存在内存缓存中，直接写入磁盘
    if (content.isFile) {
      // 先放这吧
      // _writeCacheFile(slug, content.file);
    }
    return storeToCache(key, content);
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
