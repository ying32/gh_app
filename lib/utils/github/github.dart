import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';

import 'cache_github.dart';
import 'graphql.dart';

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
            ? gitHubAPI.restful.repositories
                .listRepositories(sort: 'updated_at', direction: 'desc')
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
