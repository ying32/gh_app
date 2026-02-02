import 'package:gh_app/utils/utils.dart';

import 'graphql.dart';
import 'graphql_querys.dart';

/// 默认的API
var gitHubAPI = GitHubGraphQL();

class AuthField {
  const AuthField(this.authType, this.token);
  final AuthType authType;
  final String token;

  Map<String, dynamic> toJson() => {
        "auth_type": authType.name,
        "token": token,
      };

  AuthField.fromJson(Map<String, dynamic> json)
      : authType = enumFromStringValue(
            AuthType.values, json['auth_type'], AuthType.anonymous),
        token = json['token'] ?? '';
}

/// 创建github实例，根据配置的类型
bool createGithub(AuthField value) {
  // 其实不判断也没事，反正那啥一样
  if (value.token.isEmpty) return false;
  switch (value.authType) {
    case AuthType.accessToken:
      gitHubAPI =
          GitHubGraphQL(auth: Authorization.withBearerToken(value.token));
    case AuthType.oauth2:
      gitHubAPI =
          GitHubGraphQL(auth: Authorization.withOAuth2Token(value.token));

    default:
      gitHubAPI = GitHubGraphQL();
  }
  return true;
}

void clearGithubInstance() {
  gitHubAPI = GitHubGraphQL();
}

class QLIssueWrap {
  const QLIssueWrap(this.issue, this.repo);
  final QLIssue issue;
  final QLRepository repo;

  QLIssueWrap copyWith({QLIssue? issue}) =>
      QLIssueWrap(issue ?? this.issue, repo);
}

class QLPullRequestWrap {
  const QLPullRequestWrap(this.pull, this.repo);
  final QLPullRequest pull;
  final QLRepository repo;

  QLPullRequestWrap copyWith({QLPullRequest? pull}) =>
      QLPullRequestWrap(pull ?? this.pull, repo);
}

class QLReleaseWrap {
  const QLReleaseWrap(this.repo);
  final QLRepository repo;
}

/// Github的API包装
class APIWrap {
  APIWrap._();

  static APIWrap? _instance;
  static APIWrap get instance => _instance ??= APIWrap._();

  QLUser? _currentUser;

  ///================================== GRAPHQL API ===============================

  /// 当前user信息
  Future<QLUser?> get currentUser async =>
      _currentUser ??= (gitHubAPI.isAnonymous
          ? null
          : await gitHubAPI.query(QLQuery(QLQueries.queryUser()),
              convert: QLUser.fromJson));

  /// 指定用户信息
  Future<QLUser?> userInfo(String name) => gitHubAPI
      .query(QLQuery(QLQueries.queryUser(name)), convert: QLUser.fromJson);

  /// 指定组织信息
  Future<QLOrganization?> organizationInfo(String name) =>
      gitHubAPI.query(QLQuery(QLQueries.queryOrganization(name)),
          convert: QLOrganization.fromJson);

  /// 获取仓库列表信息
  /// TODO: 这里还要传个东西，判断是否为组织的
  Future<QLList<QLRepository>> userRepos(String owner,
      {bool isStarred = false}) async {
    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryRepos(owner: owner, isStarred: isStarred)));
    if (res == null) return const QLList.empty();
    return QLList.fromJson(
        (res['viewer'] ?? res['user'] ?? res['organization'])?[
            isStarred ? 'starredRepositories' : 'repositories'],
        QLRepository.fromJson);
  }

  /// 用户信息
  Future<QLRepository?> userRepo(QLRepository repo) async {
    return gitHubAPI.query(
        QLQuery(QLQueries.queryRepo(repo.owner!.login, repo.name)),
        convert: QLRepository.fromJson);
  }

  /// 当前仓库releases
  Future<QLList<QLRelease>> repoReleases(QLRepository repo) async {
    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryRepoReleases(repo.owner!.login, repo.name)));
    if (res == null) return const QLList.empty();
    return QLList.fromJson(res['repository']?['releases'], QLRelease.fromJson);
  }

  /// 指定release的Assets文件列表
  Future<QLList<QLReleaseAsset>> repoReleaseAssets(
      QLRepository repo, QLRelease release) async {
    final res = await gitHubAPI.query(QLQuery(QLQueries.queryRepoReleaseAssets(
        repo.owner!.login, repo.name,
        tagName: release.tagName)));
    if (res == null) return const QLList.empty();
    final obj = res['repository']?['release']?['releaseAssets'];
    if (obj == null) return const QLList.empty();
    return QLList.fromJson(obj, QLReleaseAsset.fromJson);
  }

  /// 搜索
  Future<QLList<QLRepository>> searchRepo(String query) async {
    final res = await gitHubAPI.query(QLQuery(QLQueries.search(query)));
    if (res == null) return const QLList.empty();
    return QLList.fromJson(res['search'], QLRepository.fromJson);
  }

  /// 分支列表
  Future<QLList<QLRef>> repoRefs(QLRepository repo,
      {int count = 10, String refPrefix = 'refs/heads/'}) async {
    final res = await gitHubAPI.query(QLQuery(QLQueries.queryRepoRefs(
        repo.owner!.login, repo.name,
        count: count, refPrefix: refPrefix)));
    if (res == null) return const QLList.empty();
    final refs = res['repository']?['refs'];
    if (refs == null) return const QLList.empty();
    return QLList.fromJson(refs, QLRef.fromJson);
  }

  /// 目录内容缓存
  Future<QLObject?> repoContents(QLRepository repo, String path,
      {String? ref}) async {
    final res = await gitHubAPI.query(QLQuery(QLQueries.queryObject(
        repo.owner!.login, repo.name,
        path: path, ref: ref)));
    if (res == null) return null;
    final object = res['repository']?['object'];
    if (object == null) return null;
    return QLObject.fromJson(object);
  }

  /// README文件内容
  Future<String> repoReadMe(QLRepository repo, String filename,
      {String? ref}) async {
    final res = await repoContents(repo, filename, ref: ref);
    if (res == null || res.blob == null || res.blob!.isBinary) return '';
    return res.blob?.text ?? '';
  }

  Future<QLList<QLUser>> _userFollower(
      {required String name,
      required bool isFollowers,
      required int count}) async {
    final res = await gitHubAPI.query(QLQuery(QLQueries.queryFollowerUsers(
        name: name, isFollowers: true, count: count)));
    if (res == null) return const QLList.empty();
    final input =
        (res['viewer'] ?? res['user'] ?? res['organization'])?['followers'];
    if (input == null) return const QLList.empty();
    return QLList.fromJson(input, QLUser.fromJson);
  }

  /// 关注“我”的人
  Future<QLList<QLUser>> userFollowers([String name = '']) =>
      _userFollower(name: name, isFollowers: true, count: 20);

  /// “我”关注的人
  Future<QLList<QLUser>> userFollowing([String name = '']) =>
      _userFollower(name: name, isFollowers: false, count: 20);

  /// 后面再根据需求去弄
  Future<QLList<T>> _repoIssuesOrPullRequests<T>(
    QLRepository repo, {
    required bool isOpen,
    required bool isIssues,
    bool isMerged = false,
    required JSONConverter<T> convert,
  }) async {
    //open, closed, all
    final res = await gitHubAPI.query(QLQuery(
        QLQueries.queryRepoIssuesOrPullRequests(repo.owner!.login, repo.name,
            states: isMerged
                ? 'MERGED'
                : isOpen
                    ? 'OPEN'
                    : 'CLOSED',
            isIssues: isIssues)));

    if (res == null) return const QLList.empty();
    final input = res['repository']?[isIssues ? 'issues' : 'pullRequests'];
    if (input == null) return const QLList.empty();
    return QLList<T>.fromJson(input, convert);
  }

  /// 仓库issues
  Future<QLList<QLIssue>> repoIssues(QLRepository repo, {bool isOpen = true}) =>
      _repoIssuesOrPullRequests(repo,
          isOpen: isOpen,
          isIssues: true,
          isMerged: false,
          convert: QLIssue.fromJson);

  /// 仓库pullRequests
  Future<QLList<QLPullRequest>> repoPullRequests(QLRepository repo,
          {bool isOpen = true, bool isMerged = false}) =>
      _repoIssuesOrPullRequests(repo,
          isOpen: isOpen,
          isIssues: false,
          isMerged: isMerged,
          convert: QLPullRequest.fromJson);

  /// 查询issue或者pull的评论
  Future<QLList<QLComment>> repoIssueOrPullRequestComments<T>(
    QLRepository repo, {
    required int number,
    bool isIssues = true,
  }) async {
    final res = await gitHubAPI.query(QLQuery(QLQueries.queryIssueComments(
        repo.owner!.login, repo.name, number,
        isIssues: isIssues)));
    if (res == null) return const QLList.empty();
    final input =
        res['repository']?[isIssues ? 'issue' : 'pullRequest']?['comments'];
    if (input == null) return const QLList.empty();
    return QLList.fromJson(input, QLComment.fromJson);
  }

  /// 查询指定issue或者pull Request
  Future<T?> _repoIssueOrPullRequest<T>(
    QLRepository repo, {
    required int number,
    bool isIssues = true,
    required JSONConverter<T> convert,
  }) async {
    final res = await gitHubAPI.query(QLQuery(QLQueries.queryIssueOrPullRequest(
        repo.owner!.login, repo.name, number,
        isIssues: isIssues)));
    if (res == null) return null;
    final input = res['repository']?[isIssues ? 'issue' : 'pullRequest'];
    if (input == null) return null;
    return convert(input);
  }

  /// 指定issue
  Future<QLIssue?> repoIssue<T>(
    QLRepository repo, {
    required int number,
  }) =>
      _repoIssueOrPullRequest(repo,
          number: number, isIssues: true, convert: QLIssue.fromJson);

  /// 指定pullRequest
  Future<QLPullRequest?> repoPullRequest<T>(
    QLRepository repo, {
    required int number,
  }) =>
      _repoIssueOrPullRequest(repo,
          number: number, isIssues: false, convert: QLPullRequest.fromJson);

  /// 尝试解析github链接，并返回相应的类
  dynamic tryParseGithubUrl(Uri? uri) {
    if (uri == null) return null;
    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    if (segments.length < 2) return null;
    // 最少2个
    final repo = QLRepository(
        name: segments[1], owner: QLRepositoryOwner(login: segments[0]));
    if (segments.length == 2) {
      return repo;
    } else if (segments.length > 2) {
      final val = segments[2];
      switch (val) {
        case "issues" || "pull":
          if (segments.length >= 4) {
            final number = int.tryParse(segments[3], radix: 10) ?? -1;
            if (number > 0) {
              if (val == "issues") {
                return QLIssueWrap(QLIssue(number: number), repo);
              } else if (val == "pull") {
                return QLPullRequestWrap(QLPullRequest(number: number), repo);
              }
            }
          }
        case "releases":
          return QLReleaseWrap(repo);
      }
    }
    return null;
  }

  ///================================== REST API ===============================
}
