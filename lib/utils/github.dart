import 'dart:convert';
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

/// GraphQL查询
/// https://docs.github.com/zh/graphql/reference/queries
class GitHubGraphQL {
  GitHubGraphQL({
    this.auth = const Authentication.anonymous(),
    this.endpoint = 'https://api.github.com/graphql',
  }) : _github = CacheGitHub(
            auth: auth, endpoint: endpoint, version: '', isGraphQL: true);

  /// Authentication Information
  Authentication auth;

  /// API Endpoint
  final String endpoint;

  /// github实例
  final CacheGitHub _github;

  /// 一个查询
  /// ```json
  /// {
  ///   "query": "query MyQuery($id: string) { thing(id: $id) { id name created } }",
  ///   "variables": {
  ///     "id": "thing_123"
  ///   },
  ///   "operationName": "MyQuery"
  /// }
  ///
  /// ```
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
  })  : restful = CacheGitHub(auth: auth),
        graphql = GitHubGraphQL(auth: auth);

  /// Authentication Information
  final Authentication auth;

  /// V3版本API，使用Restful操作的
  final CacheGitHub restful;

  /// V4版本API，使用GraphQL操作的
  final GitHubGraphQL graphql;

  /// 是否使用匿名方式
  bool get isAnonymous => auth.isAnonymous;
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

  /// 当前user信息
  Future<CurrentUser?> get currentUser async =>
      _currentUser ??= (gitHubAPI.auth.isAnonymous
          ? null
          : await gitHubAPI.restful.users.getCurrentUser());

  Future<List<Notification>?> get currentUserNotifications async {
    return gitHubAPI.restful.activity.listNotifications().toList();
  }

  ///
  Future<List<User>?> userFollowers([String owner = '']) async {
    return (owner.isEmpty
            ? gitHubAPI.restful.users.listCurrentUserFollowers()
            : gitHubAPI.restful.users.listUserFollowers(owner))
        .toList();
  }

  Future<List<User>?> userFollowing([String owner = '']) async {
    return gitHubAPI.restful.users.listCurrentUserFollowing().toList();
  }

  Future<User?> userInfo(String name) => gitHubAPI.restful.users.getUser(name);

  /// 获取仓库列表信息
  Future<List<Repository>?> userRepos(String owner) async {
    return (owner.isEmpty
            ? gitHubAPI.restful.repositories.listRepositories()
            : gitHubAPI.restful.repositories.listUserRepositories(owner))
        .toList();
  }

  Future<Repository?> userRepo(String owner, String name) async {
    final slug = RepositorySlug(owner, name);

    return gitHubAPI.restful.repositories.getRepository(slug);
  }

  Future<List<Branch>?> repoBranches(Repository repo) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);

    return gitHubAPI.restful.repositories.listBranches(slug).toList();
  }

  Future<List<Release>?> repoReleases(Repository repo) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);

    return gitHubAPI.restful.repositories.listReleases(slug).toList();
  }

  Future<List<Issue>?> repoIssues(Repository repo, {bool isOpen = true}) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);
    //final state = isOpen ? 'OPEN' : 'CLOSED';
    final state = isOpen ? 'open' : 'closed'; //open, closed, all

    return gitHubAPI.restful.issues.listByRepo(slug, state: state).toList();
  }

  Future<List<PullRequest>?> repoPullRequests(Repository repo,
      {bool isOpen = true}) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);
    final state = isOpen ? 'open' : 'closed'; //open, closed, all

    return gitHubAPI.restful.pullRequests.list(slug, state: state).toList();
  }

  /// README缓存
  Future<String?> repoReadMe(Repository repo, {String? ref}) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);

    return (await gitHubAPI.restful.repositories.getReadme(slug, ref: ref))
        .text;
  }

  /// 目录内容缓存
  Future<RepositoryContents?> repoContents(Repository repo, String path,
      {String? ref}) async {
    final slug = repo.slug(); //RepositorySlug(repo.owner!.login, repo.name);

    return gitHubAPI.restful.repositories.getContents(slug, path, ref: ref);
  }
}
