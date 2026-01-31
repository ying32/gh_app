import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;

import 'cache_github.dart';

/// 仓库的主语言
class QLPrimaryLanguage {
  const QLPrimaryLanguage({
    this.color = '',
    this.name = '',
  });
  final String color;
  final String name;

  QLPrimaryLanguage.fromJson(Map<String, dynamic> input)
      : color = input['color'] ?? '',
        name = input['name'] ?? '';
}

/// 仓库所有者
class QLRepositoryOwner extends UserInformation {
  QLRepositoryOwner({
    required String login,
    String avatarUrl = '',
  }) : super(login, 0, avatarUrl, '');

  factory QLRepositoryOwner.fromJson(Map<String, dynamic> input) =>
      QLRepositoryOwner(login: input['login'], avatarUrl: input['avatarUrl']);

  @override
  Map<String, dynamic> toJson() => {};
}

/// 许可协议
class QLLicenseKind extends LicenseKind {
  QLLicenseKind({super.name}) : super();

  QLLicenseKind.fromJson(Map<String, dynamic> json) : super(name: json['name']);

  @override
  Map<String, dynamic> toJson() => {};
}

class QLReleaseAsset extends ReleaseAsset {
  QLReleaseAsset({
    super.name,
    super.contentType,
    super.size,
    super.downloadCount,
    super.browserDownloadUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory QLReleaseAsset.fromJson(Map<String, dynamic> input) {
    input = input['nodes'] ?? input;
    return QLReleaseAsset(
      name: input['name'],
      contentType: input['contentType'],
      downloadCount: input['downloadCount'],
      browserDownloadUrl: input['downloadUrl'],
      size: input['size'],
      createdAt: input['createdAt'] == null
          ? null
          : DateTime.parse(input['createdAt'] as String),
      updatedAt: input['updatedAt'] == null
          ? null
          : DateTime.parse(input['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {};
}

class QLRelease extends Release {
  QLRelease({
    super.name,
    super.author,
    super.tagName,
    super.url,
    super.createdAt,
    super.isDraft,
    super.isPrerelease,
    super.publishedAt,
    super.description,
    super.assets,
    this.isLatest = false,
    this.abbreviatedOid = '',
  }) : super(
          // 发现这个graphql的将release note放在description里面了？
          body: description,
        );
  //latestRelease

  final bool isLatest;

  /// tagCommit.abbreviatedOid
  final String abbreviatedOid;

  factory QLRelease.fromJson(Map<String, dynamic> input) {
    return QLRelease(
      name: input['name'],
      tagName: input['tagName'],
      url: input['url'],
      publishedAt: input['updatedAt'] == null
          ? null
          : DateTime.parse(input['updatedAt']),
      createdAt: input['createdAt'] == null
          ? null
          : DateTime.parse(input['createdAt']),
      isDraft: input['isDraft'],
      isPrerelease: input['isPrerelease'],
      description: input['description'],
      isLatest: input['isLatest'] ?? false,
      abbreviatedOid: input['tagCommit']?['abbreviatedOid'] ?? '',
      author: QLUser.fromJson(input['author']),
      assets: input['releaseAssets']?['nodes'] == null
          ? null
          : List.from(input['releaseAssets']?['nodes'])
              .map((e) => QLReleaseAsset.fromJson(e))
              .toList(),
    );
  }
  @override
  Map<String, dynamic> toJson() => {};
}

// class QLBranch extends Branch {
//   QLBranch(super.name, super.commit);
//
//   @override
//   Map<String, dynamic> toJson() => {};
// }

/// 仓库信息
class QLRepository extends Repository {
  QLRepository({
    super.name,
    super.forksCount,
    super.forks,
    super.stargazersCount,
    super.isPrivate,
    super.description,
    super.owner,
    super.archived,
    super.updatedAt,
    super.pushedAt,
    super.htmlUrl,
    super.openIssues,
    super.license,
    super.topics,
    super.disabled,
    super.allowForking,
    super.hasIssues,
    super.hasProjects,
    super.hasWiki,
    super.homepage,
    super.isFork,
    super.isTemplate,
    super.mirrorUrl,
    super.defaultBranch,
    super.watchers,
    this.primaryLanguage = const QLPrimaryLanguage(),
    this.isInOrganization = false,
    this.openPullRequests = 0,
    this.archivedAt,
    this.diskUsage = 0,
    this.hasSponsorshipsEnabled = false,
    this.isBlankIssuesEnabled = false,
    this.isEmpty = false,
    this.isLocked = false,
    this.isMirror = false,
    this.viewerCanSubscribe = false,
    this.viewerHasStarred = false,
    this.releasesCount = 0,
    this.latestRelease,
    this.refsCount = 0,
  }) : super(
          language: primaryLanguage.name,
          openIssuesCount: openIssues ?? 0,
          fullName: "${owner?.login}/$name",
          watchersCount: watchers ?? 0,
        );

  final QLPrimaryLanguage primaryLanguage;
  final bool isInOrganization;
  final int openPullRequests;
  final DateTime? archivedAt;
  final int diskUsage;
  final bool hasSponsorshipsEnabled;
  final bool isBlankIssuesEnabled;
  final bool isEmpty;
  final bool isLocked;
  final bool isMirror;
  final bool viewerCanSubscribe;
  final bool viewerHasStarred;
  final int releasesCount;
  final QLRelease? latestRelease;
  final int refsCount;

  factory QLRepository.fromJson(Map<String, dynamic> input) {
    input = input['repository'] ?? input;
    //print("===========解析仓库=$input");
    return QLRepository(
      name: input['name'] ?? '',
      forksCount: input['forkCount'] ?? 0,
      forks: input['forkCount'],
      stargazersCount: input['stargazerCount'] ?? 0,
      isPrivate: input['isPrivate'] ?? false,
      description: input['description'] ?? '',
      archived: input['isArchived'] ?? false,
      htmlUrl: input['url'] ?? '',
      openIssues: input['issues']?['totalCount'],
      isInOrganization: input['isInOrganization'] ?? false,
      diskUsage: input['diskUsage'] ?? 0,
      allowForking: input['forkingAllowed'] ?? false,
      hasIssues: input['hasIssuesEnabled'] ?? false,
      hasProjects: input['hasProjectsEnabled'] ?? false,
      disabled: input['isDisabled'] ?? false,
      hasSponsorshipsEnabled: input['hasSponsorshipsEnabled'] ?? false,
      hasWiki: input['hasWikiEnabled'] ?? false,
      homepage: input['homepageUrl'] ?? '',
      isBlankIssuesEnabled: input['isBlankIssuesEnabled'] ?? false,
      isEmpty: input['isEmpty'] ?? false,
      isFork: input['isFork'] ?? false,
      isLocked: input['isLocked'] ?? false,
      isMirror: input['isMirror'] ?? false,
      isTemplate: input['isTemplate'],
      viewerCanSubscribe: input['viewerCanSubscribe'] ?? false,
      viewerHasStarred: input['viewerHasStarred'] ?? false,
      openPullRequests: input['pullRequests']?['totalCount'] ?? 0,
      watchers: input['watchers']?['totalCount'],
      mirrorUrl: input['mirrorUrl'],
      // languages 字段，暂时不要了哈
      defaultBranch: input['defaultBranchRef']?['name'] ?? '',
      releasesCount: input['releases']?['totalCount'] ?? 0,
      refsCount: input['refs']?['totalCount'] ?? 0,

      latestRelease: input['latestRelease'] == null
          ? null
          : QLRelease.fromJson(input['latestRelease']),

      updatedAt: input['updatedAt'] == null
          ? null
          : DateTime.parse(input['updatedAt']),
      archivedAt: input['archivedAt'] == null
          ? null
          : DateTime.parse(input['updatedAt']),
      pushedAt:
          input['pushedAt'] == null ? null : DateTime.parse(input['pushedAt']),
      primaryLanguage: input['primaryLanguage'] != null
          ? QLPrimaryLanguage.fromJson(input['primaryLanguage'])
          : const QLPrimaryLanguage(),
      owner: input['owner'] != null
          ? QLRepositoryOwner.fromJson(input['owner'])
          : null,
      license: input['licenseInfo'] == null
          ? null
          : QLLicenseKind.fromJson(input['licenseInfo']),
      topics: input['repositoryTopics']?['nodes'] == null
          ? null
          : List.of(input['repositoryTopics']?['nodes'])
              .map((e) => "${e['topic']?['name'] ?? ''}")
              .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {};
}

/// GraphQL查询的user
class QLUser extends User {
  QLUser({
    super.login,
    super.avatarUrl,
    super.htmlUrl,
    super.name,
    super.company,
    super.blog,
    super.location,
    super.email,
    super.bio,
    super.followersCount,
    super.followingCount,
    this.pinnedItems,
    String? twitterUsername,
  }) {
    super.twitterUsername = twitterUsername;
  }

  /// 置顶项目
  final List<QLRepository>? pinnedItems;

  factory QLUser.fromJson(Map<String, dynamic> input) {
    input = input['viewer'] ?? input['user'] ?? input;
    return QLUser(
      login: input['login'],
      name: input['name'],
      avatarUrl: input['avatarUrl'],
      company: input['company'],
      bio: input['bio'],
      email: input['email'],
      location: input['location'],
      twitterUsername: input['twitterUsername'],
      htmlUrl: input['url'],
      blog: input['websiteUrl'],
      followersCount: input['followers']?['totalCount'],
      followingCount: input['following']?['totalCount'],
      pinnedItems: input['pinnedItems']?['nodes'] != null
          ? List.of(input['pinnedItems']?['nodes'])
              .map((e) => QLRepository.fromJson(e))
              .toList()
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {};
}

/// GraphQL查询
/// https://docs.github.com/zh/graphql/reference/queries
///
/// gh命令行
/// https://cli.github.com/manual/gh_api
///
/// GitHub GraphQL API 文档
/// https://docs.github.com/zh/graphql
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
  /// viewer { login name }
  /// ```
  Future<T> query<S, T>(
    String body, {
    Map<String, String>? variables,
    String? operationName,
    void Function(http.Response response)? fail,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    JSONConverter<S, T?>? convert,
  }) =>
      _request("query {\n $body \n}",
          variables: variables,
          operationName: operationName,
          fail: fail,
          headers: headers,
          params: params,
          convert: convert);

  //  "Content-Type: application/json",
  //   "Accept: application/vnd.github.v4.idl"

  /// 修改操作
  Future<T> mutation<S, T>(
    String body, {
    Map<String, String>? variables,
    String? operationName,
    void Function(http.Response response)? fail,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    JSONConverter<S, T?>? convert,
  }) async =>
      _request("mutation {\rn $body \n}",
          variables: variables,
          operationName: operationName,
          fail: fail,
          headers: headers,
          params: params,
          convert: convert);

  /// 忽略path字段，强制为[endpoint]，本可不这样做的，但是他内部的[request]方法在判断[path]时
  /// 附加了一个”/“符号，造成服务端识为这是一个rest API。
  /// 暂时不公开，之后再看吧
  Future<T> _request<S, T>(
    String body, {
    Map<String, String>? variables,
    String? operationName,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    void Function(http.Response response)? fail,
    JSONConverter<S, T?>? convert,
  }) async {
    // 对于[mutation]也不知道是不是这样使用query?????
    final qlQuery = {
      "query": body,
      if (variables != null) "variables": variables,
      if (operationName != null) "operationName": operationName,
    };
    if (kDebugMode) {
      //print("body: ${jsonEncode(qlQuery)}");
    }

    //convert ??= (input) => input as T?;
    headers ??= {};
    final response = await _github.request("POST", endpoint,
        headers: headers,
        params: params,
        body: jsonEncode(qlQuery),
        statusCode: 200,
        fail: fail,
        preview: null);
    final json = jsonDecode(response.body);

    // 有错误，这个错误在定义了[statusCode]时会解析
    // {"message":"Problems parsing JSON","documentation_url":"https://docs.github.com/graphql","status":"400"}
    // 实际为422错误，但没有哈
    // {"errors":[{"path":["query","DSD"],"extensions":{"code":"undefinedField","typeName":"Query","fieldName":"DSD"},"locations":[{"line":11,"column":4}],"message":"Field 'DSD' doesn't exist on type 'Query'"}]}
    // 这个错误貌似依然返回200？
    if (json['errors'] != null && response.statusCode == 200) {
      // 按理说应该状态码返回422，但没返回的原因是啥？？？？
      //response = response.o = 422;
      // 有错误了，这里他错误了也会返回个200，造成原来的解析不了
      _github.handleStatusCode(http.Response.bytes(response.bodyBytes, 422,
          headers: response.headers, isRedirect: response.isRedirect));
    }
    // 实际数据节点
    final data = json['data']; // ?? json
    if (convert == null) {
      return data;
    }
    return convert(data) as T;
  }
}
