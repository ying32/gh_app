import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';

import 'cache_github.dart';
import 'graphql.dart';
import 'graphql_querys.dart';

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

/// Github的API包装
class APIWrap {
  APIWrap._();

  static APIWrap? _instance;
  static APIWrap get instance => _instance ??= APIWrap._();

  QLUser? _currentUser;

  RepositorySlug _getSlug(QLRepository repo) =>
      RepositorySlug(repo.owner?.login ?? '', repo.name);

  /// 当前user信息
  Future<QLUser?> get currentUser async =>
      _currentUser ??= (gitHubAPI.auth.isAnonymous
          ? null
          : await gitHubAPI.graphql
              .query(QLQuery(QLQueries.queryUser()), convert: QLUser.fromJson));

  /// 指定用户信息
  Future<QLUser?> userInfo(String name) => gitHubAPI.graphql
      .query(QLQuery(QLQueries.queryUser(name)), convert: QLUser.fromJson);

  /// 指定组织信息
  Future<QLOrganization?> organizationInfo(String name) =>
      gitHubAPI.graphql.query(QLQuery(QLQueries.queryOrganization(name)),
          convert: QLOrganization.fromJson);

  /// 获取仓库列表信息
  /// TODO: 这里还要传个东西，判断是否为组织的
  Future<QLList<QLRepository>> userRepos(String owner) async {
    final res = await gitHubAPI.graphql
        .query(QLQuery(QLQueries.queryRepos(owner: owner)));
    if (res == null) return const QLList.empty();
    return QLList.fromJson(
        (res['viewer'] ?? res['user'] ?? res['organization'])?['repositories'],
        QLRepository.fromJson);
  }

  /// 用户信息
  Future<QLRepository?> userRepo(QLRepository repo) async {
    return gitHubAPI.graphql.query(
        QLQuery(QLQueries.queryRepo(repo.owner!.login, repo.name)),
        convert: QLRepository.fromJson);
  }

  /// 当前仓库releases
  Future<QLList<QLRelease>> repoReleases(QLRepository repo) async {
    final res = await gitHubAPI.graphql.query(
        QLQuery(QLQueries.queryRepoRelease(repo.owner!.login, repo.name)));
    if (res == null) return const QLList.empty();
    return QLList.fromJson(res['repository']?['releases'], QLRelease.fromJson);
  }

  /// 搜索
  Future<QLList<QLRepository>> searchRepo(String query) async {
    final res = await gitHubAPI.graphql.query(QLQuery(QLQueries.search(query)));
    if (res == null) return const QLList.empty();
    return QLList.fromJson(res['search'], QLRepository.fromJson);
  }

  ///================================== REST API ===============================

  /// 仓库分支列表
  Future<List<Branch>?> repoBranches(QLRepository repo) async {
    return gitHubAPI.restful.repositories.listBranches(_getSlug(repo)).toList();
  }

  /// 仓库issues
  Future<List<Issue>?> repoIssues(QLRepository repo,
      {bool isOpen = true}) async {
    //open, closed, all
    return gitHubAPI.restful.issues
        .listByRepo(_getSlug(repo),
            state: isOpen ? 'open' : 'closed', perPage: 1)
        .toList();
  }

  /// 仓库pullRequests
  Future<List<PullRequest>?> repoPullRequests(QLRepository repo,
      {bool isOpen = true}) async {
    //open, closed, all
    return gitHubAPI.restful.pullRequests
        .list(_getSlug(repo), state: isOpen ? 'open' : 'closed')
        .toList();
  }

  /// README缓存
  Future<String?> repoReadMe(QLRepository repo, {String? ref}) async {
    return (await gitHubAPI.restful.repositories
            .getReadme(_getSlug(repo), ref: ref))
        .text;
  }

  /// 目录内容缓存
  Future<RepositoryContents?> repoContents(QLRepository repo, String path,
      {String? ref}) async {
    return gitHubAPI.restful.repositories
        .getContents(_getSlug(repo), path, ref: ref);
  }

  /// 关注“我”的人
  Future<List<User>?> userFollowers([String owner = '']) async {
    return (owner.isEmpty
            ? gitHubAPI.restful.users.listCurrentUserFollowers()
            : gitHubAPI.restful.users.listUserFollowers(owner))
        .toList();
  }

  /// “我”关注的人
  Future<List<User>?> userFollowing([String owner = '']) async {
    return gitHubAPI.restful.users.listCurrentUserFollowing().toList();
  }

// Future<List<Notification>?> get currentUserNotifications async {
//   return gitHubAPI.restful.activity.listNotifications().toList();
// }
}
