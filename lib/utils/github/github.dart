import 'package:flutter/foundation.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/defines.dart';
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

/// 一些包装，用于处理链接跳转的

class QLRepositoryWrap {
  const QLRepositoryWrap(
    this.repo, {
    this.ref,
    this.path,
    this.subPage,
  });
  final QLRepository repo;
  final String? ref;
  final String? path;
  final RepoSubPage? subPage;

  QLRepositoryWrap copyWith({QLRepository? repo}) =>
      QLRepositoryWrap(repo ?? this.repo, ref: ref, path: path);
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

  ///================================== GRAPHQL API ===============================

  /// 当前user信息
  Future<QLUser?> currentUser(
      {bool? force, ValueChanged<QLUser?>? onSecondUpdate}) async {
    if (gitHubAPI.isAnonymous) {
      return null;
    }
    return gitHubAPI.query(QLQuery(QLQueries.queryUser()),
        convert: QLUser.fromJson,
        force: force,
        secondUpdateCallback: onSecondUpdate == null
            ? null
            : (json) => onSecondUpdate.call(QLUser.fromJson(json)));
  }

  /// 指定用户信息
  Future<QLUser?> userInfo(String name, {bool? force}) =>
      gitHubAPI.query(QLQuery(QLQueries.queryUser(name)),
          convert: QLUser.fromJson, force: force);

  /// 指定组织信息
  Future<QLOrganization?> organizationInfo(String name, {bool? force}) =>
      gitHubAPI.query(QLQuery(QLQueries.queryOrganization(name)),
          convert: QLOrganization.fromJson, force: force);

  /// 获取仓库列表信息
  /// TODO: 这里还要传个东西，判断是否为组织的
  Future<QLList<QLRepository>> userRepos(
    String owner, {
    bool isStarred = false,
    int? count,
    String? nextCursor,
    bool? force,
    ValueChanged<QLList<QLRepository>>? onSecondUpdate,
  }) async {
    //print("===============================userRepos");

    // 内部解析
    QLList<QLRepository> parse(Map<String, dynamic>? json) {
      if (json == null) return const QLList.empty();
      return QLList.fromJson(
          (json['viewer'] ?? json['user'] ?? json['organization'])?[
              isStarred ? 'starredRepositories' : 'repositories'],
          QLRepository.fromJson,
          pageSize: count ?? defaultPageSize);
    }

    // 请求
    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryRepos(
            owner: owner,
            isStarred: isStarred,
            count: count,
            nextCursor: nextCursor)),
        force: force,
        secondUpdateCallback: onSecondUpdate == null
            ? null
            : (json) => onSecondUpdate.call(parse(json)));

    return parse(res);
  }

  /// 用户信息
  Future<QLRepository?> userRepo(QLRepository repo, {bool? force}) async {
    return gitHubAPI.query(
        QLQuery(QLQueries.queryRepo(repo.owner.login, repo.name)),
        convert: QLRepository.fromJson,
        force: force);
  }

  /// 当前仓库releases
  Future<QLList<QLRelease>> repoReleases(
    QLRepository repo, {
    int? count,
    String? nextCursor,
    bool? force,
    ValueChanged<QLList<QLRelease>>? onSecondUpdate,
  }) async {
    // 解析
    QLList<QLRelease> parse(Map<String, dynamic>? json) {
      if (json == null) return const QLList.empty();
      return QLList.fromJson(
          json['repository']?['releases'], QLRelease.fromJson,
          pageSize: count ?? defaultPageSize);
    }

    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryRepoReleases(repo.owner.login, repo.name,
            count: count, nextCursor: nextCursor)),
        force: force,
        secondUpdateCallback: onSecondUpdate == null
            ? null
            : (json) => onSecondUpdate.call(parse(json)));

    return parse(res);
  }

  /// 指定release的Assets文件列表
  Future<QLList<QLReleaseAsset>> repoReleaseAssets(
    QLRepository repo,
    QLRelease release, {
    int? count,
    String? nextCursor,
    bool? force,
    ValueChanged<QLList<QLReleaseAsset>>? onSecondUpdate,
  }) async {
    QLList<QLReleaseAsset> parse(Map<String, dynamic>? json) {
      if (json == null) return const QLList.empty();
      final obj = json['repository']?['release']?['releaseAssets'];
      if (obj == null) return const QLList.empty();
      return QLList.fromJson(obj, QLReleaseAsset.fromJson,
          pageSize: count ?? defaultPageSize);
    }

    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryRepoReleaseAssets(repo.owner.login, repo.name,
            tagName: release.tagName, count: count, nextCursor: nextCursor)),
        force: force,
        secondUpdateCallback: onSecondUpdate == null
            ? null
            : (json) => onSecondUpdate.call(parse(json)));

    return parse(res);
  }

  /// 搜索，不使用缓存功能
  Future<QLList<QLRepository>> searchRepo(
    String query, {
    int? count,
    String? nextCursor,
    bool? force,
    ValueChanged<QLList<QLRepository>>? onSecondUpdate,
  }) async {
    //
    QLList<QLRepository> parse(Map<String, dynamic>? json) {
      if (json == null) return const QLList.empty();
      return QLList.fromJson(json['search'], QLRepository.fromJson,
          totalCountAlias: 'repositoryCount',
          pageSize: count ?? defaultPageSize);
    }

    final res = await gitHubAPI.query(
        QLQuery(QLQueries.search(query, count: count, nextCursor: nextCursor)),
        force: force,
        secondUpdateCallback: onSecondUpdate == null
            ? null
            : (json) => onSecondUpdate.call(parse(json)));

    return parse(res);
  }

  /// 分支列表
  Future<QLList<QLRef>> repoRefs(
    QLRepository repo, {
    int? count,
    String? nextCursor,
    String refPrefix = 'refs/heads/',
    bool? force,
  }) async {
    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryRepoRefs(repo.owner.login, repo.name,
            count: count, nextCursor: nextCursor, refPrefix: refPrefix)),
        force: force);
    if (res == null) return const QLList.empty();
    final refs = res['repository']?['refs'];
    if (refs == null) return const QLList.empty();
    return QLList.fromJson(refs, QLRef.fromJson,
        pageSize: count ?? defaultPageSize);
  }

  /// 目录内容缓存
  Future<QLObject?> repoContents(
    QLRepository repo,
    String path, {
    String? ref,
    bool? force,
    ValueChanged<QLObject?>? onSecondUpdate,
  }) async {
    QLObject? parse(Map<String, dynamic>? json) {
      if (json == null) return null;
      final object = json['repository']?['object'];
      if (object == null) return null;
      return QLObject.fromJson(object);
    }

    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryObject(repo.owner.login, repo.name,
            path: path, ref: ref)),
        force: force,
        secondUpdateCallback: onSecondUpdate == null
            ? null
            : (json) => onSecondUpdate.call(parse(json)));

    return parse(res);
  }

  /// README文件内容
  Future<String> repoReadMe(
    QLRepository repo,
    String filename, {
    String? ref,
    bool? force,
    ValueChanged<String>? onSecondUpdate,
  }) async {
    String parse(QLObject? res) {
      if (res == null || res.blob == null || res.blob!.isBinary) return '';
      return res.blob?.text ?? '';
    }

    final res = await repoContents(repo, filename,
        ref: ref, force: force, onSecondUpdate: (object) => parse(object));

    return parse(res);
  }

  Future<QLList<QLUser>> _userFollower({
    required String name,
    required bool isFollowers,
    int? count,
    String? nextCursor,
    bool? force,
  }) async {
    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryFollowerUsers(
            name: name,
            isFollowers: true,
            count: count,
            nextCursor: nextCursor)),
        force: force);
    if (res == null) return const QLList.empty();
    final input = (res['viewer'] ??
        res['user'] ??
        res['organization'])?[isFollowers ? 'followers' : 'following'];
    if (input == null) return const QLList.empty();
    return QLList.fromJson(input, QLUser.fromJson,
        pageSize: count ?? defaultPageSize);
  }

  /// 关注“我”的人
  Future<QLList<QLUser>> userFollowers(
          {String name = '', String? nextCursor, bool? force}) =>
      _userFollower(
          name: name, isFollowers: true, nextCursor: nextCursor, force: force);

  /// “我”关注的人
  Future<QLList<QLUser>> userFollowing(
          {String name = '', String? nextCursor, bool? force}) =>
      _userFollower(
          name: name, isFollowers: false, nextCursor: nextCursor, force: force);

  /// 后面再根据需求去弄
  Future<QLList<T>> _repoIssuesOrPullRequests<T>(
    QLRepository repo, {
    required bool isOpen,
    required bool isIssues,
    bool isMerged = false,
    int? count,
    String? nextCursor,
    required JSONConverter<T> convert,
    bool? force,
    ValueChanged<QLList<T>>? onSecondUpdate,
  }) async {
    // 内部解析
    QLList<T> parse(Map<String, dynamic>? json) {
      if (json == null) return const QLList.empty();
      final input = json['repository']?[isIssues ? 'issues' : 'pullRequests'];
      if (input == null) return const QLList.empty();
      return QLList<T>.fromJson(input, convert,
          pageSize: count ?? defaultPageSize);
    }

    //open, closed, all
    final res = await gitHubAPI.query(
        QLQuery(
            QLQueries.queryRepoIssuesOrPullRequests(repo.owner.login, repo.name,
                states: isMerged
                    ? 'MERGED'
                    : isOpen
                        ? 'OPEN'
                        : 'CLOSED',
                isIssues: isIssues,
                count: count,
                nextCursor: nextCursor)),
        force: force,
        secondUpdateCallback: onSecondUpdate == null
            ? null
            : (json) => onSecondUpdate.call(parse(json)));

    return parse(res);
  }

  /// 仓库issues
  Future<QLList<QLIssue>> repoIssues(
    QLRepository repo, {
    bool isOpen = true,
    int? count,
    String? nextCursor,
    bool? force,
    ValueChanged<QLList<QLIssue>>? onSecondUpdate,
  }) =>
      _repoIssuesOrPullRequests(repo,
          isOpen: isOpen,
          isIssues: true,
          isMerged: false,
          count: count,
          nextCursor: nextCursor,
          convert: QLIssue.fromJson,
          force: force,
          onSecondUpdate: onSecondUpdate);

  /// 仓库pullRequests
  Future<QLList<QLPullRequest>> repoPullRequests(
    QLRepository repo, {
    bool isOpen = true,
    bool isMerged = false,
    int? count,
    String? nextCursor,
    bool? force,
    ValueChanged<QLList<QLPullRequest>>? onSecondUpdate,
  }) =>
      _repoIssuesOrPullRequests(repo,
          isOpen: isOpen,
          isIssues: false,
          isMerged: isMerged,
          count: count,
          nextCursor: nextCursor,
          convert: QLPullRequest.fromJson,
          force: force,
          onSecondUpdate: onSecondUpdate);

  /// 查询issue或者pull的评论
  Future<QLList<QLComment>> repoIssueOrPullRequestComments<T>(
    QLRepository repo, {
    required int number,
    bool isIssues = true,
    int? count,
    String? nextCursor,
    bool? force,
    ValueChanged<QLList<QLComment>>? onSecondUpdate,
  }) async {
    QLList<QLComment> parse(Map<String, dynamic>? json) {
      if (json == null) return const QLList.empty();
      final input =
          json['repository']?[isIssues ? 'issue' : 'pullRequest']?['comments'];
      if (input == null) return const QLList.empty();
      return QLList.fromJson(input, QLComment.fromJson,
          pageSize: count ?? defaultPageSize);
    }

    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryIssueComments(
            repo.owner.login, repo.name, number,
            count: count, nextCursor: nextCursor, isIssues: isIssues)),
        force: force,
        secondUpdateCallback: onSecondUpdate == null
            ? null
            : (json) => onSecondUpdate.call(parse(json)));

    return parse(res);
  }

  /// 查询指定issue或者pull Request
  Future<T?> _repoIssueOrPullRequest<T>(
    QLRepository repo, {
    required int number,
    bool isIssues = true,
    required JSONConverter<T> convert,
    bool? force,
    // ValueChanged<QLList<QLComment>>? onSecondUpdate,
  }) async {
    final res = await gitHubAPI.query(
        QLQuery(QLQueries.queryIssueOrPullRequest(
            repo.owner.login, repo.name, number,
            isIssues: isIssues)),
        force: force);
    if (res == null) return null;
    final input = res['repository']?['issueOrPullRequest'] ??
        res['repository']?[isIssues ? 'issue' : 'pullRequest'];
    if (input == null) return null;
    return convert(input);
  }

  /// 指定issue
  Future<QLIssue?> repoIssue<T>(QLRepository repo,
          {required int number, bool? force}) =>
      _repoIssueOrPullRequest(repo,
          number: number,
          isIssues: true,
          convert: QLIssue.fromJson,
          force: force);

  /// 指定pullRequest
  Future<QLPullRequest?> repoPullRequest<T>(QLRepository repo,
          {required int number, bool? force}) =>
      _repoIssueOrPullRequest(repo,
          number: number,
          isIssues: false,
          convert: QLPullRequest.fromJson,
          force: force);

  /// 尝试解析github链接，并返回相应的类
  dynamic tryParseGithubUrl(Uri? uri) {
    if (uri == null) return null;
    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    if (segments.length < 2) return null;
    // 最少2个
    final login = segments[0].trim();
    var repoName = segments[1].trim();
    if (repoName.endsWith(".git")) {
      repoName = repoName.substring(0, repoName.length - 4);
    }
    final repo =
        QLRepository(name: repoName, owner: QLRepositoryOwner(login: login));
    if (segments.length == 2) {
      return QLRepositoryWrap(repo);
    } else if (segments.length > 2) {
      final func = segments[2].trim();
      switch (func) {
        case "issues" || "pull":
          // 编号
          final number = (segments.length >= 4
                  ? int.tryParse(segments[3], radix: 10)
                  : null) ??
              0;
          if (number > 0) {
            if (func == "issues") {
              return QLIssueWrap(QLIssue(number: number), repo);
            } else if (func == "pull") {
              return QLPullRequestWrap(QLPullRequest(number: number), repo);
            }
          } else {
            return QLRepositoryWrap(repo,
                subPage: func == "issues"
                    ? RepoSubPage.issues
                    : RepoSubPage.pullRequests);
          }
        case "releases":
          return QLReleaseWrap(repo);
        case "blob":
          //TODO 只实现跳转仓库
          final ref = segments.length >= 4 ? segments[3].trim() : null;
          final path = segments.length >= 5 ? segments.skip(4).join("/") : null;
          return QLRepositoryWrap(repo,
              ref: ref, path: path, subPage: RepoSubPage.code);
        case "tree":
          //TODO 只实现跳转仓库
          final ref = segments.length >= 4 ? segments[3].trim() : null;
          const path =
              null; //segments.length >= 5 ? segments.skip(4).join("/") : null;
          return QLRepositoryWrap(repo,
              ref: ref, path: path, subPage: RepoSubPage.code);
        // case "actions":
        //   final runs = segments.length >= 4 ? segments[3].trim() : null;
        //   final id = segments.length >= 5 ? segments[4].trim() : null;
        //   return QLRepositoryWrap(repo, subPage: RepoSubPage.actions);
        // case "commit":
        //   final hash = segments.length >= 4 ? segments[3].trim() : null;
      }
    }
    return null;
  }

  ///================================== REST API ===============================
}
