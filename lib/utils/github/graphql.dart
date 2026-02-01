import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;

import 'cache_github.dart';

/// 分页信息，按规则传递。比如：
/// 每页10个
/// 从前往后选择的
/// first: 10, after: "$endCursor"
///
/// 从后往前选择
/// last: 10, before: "$startCursor "
class QLPageInfo {
  QLPageInfo({
    required this.startCursor,
    required this.endCursor,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
  final String startCursor;
  final String endCursor;
  final bool hasNextPage;
  final bool hasPreviousPage;

  QLPageInfo.fromJson(Map<String, dynamic> input)
      : startCursor = input['startCursor'] ?? '',
        endCursor = input['endCursor'] ?? '',
        hasNextPage = input['hasNextPage'] ?? false,
        hasPreviousPage = input['hasPreviousPage'] ?? false;
}

/// 仓库的主语言
class QLLanguage {
  const QLLanguage({
    this.color = '',
    this.name = '',
  });
  final String color;
  final String name;

  QLLanguage.fromJson(Map<String, dynamic> input)
      : color = input['color'] ?? '',
        name = input['name'] ?? '';
}

/// 用户信息基础类，包含用户和组织
class QLUserBase {
  const QLUserBase({
    required this.login,
    this.avatarUrl = '',
  });

  /// 所有者用户名
  final String login;

  /// 头像
  final String avatarUrl;
}

/// 仓库所有者
class QLRepositoryOwner extends QLUserBase {
  const QLRepositoryOwner({
    required super.login,
    super.avatarUrl,
    this.url = '',
  });

  /// 链接
  final String url;

  QLRepositoryOwner.fromJson(Map<String, dynamic> input)
      : url = input['url'] ?? '',
        super(
          login: input['login'] ?? '',
          avatarUrl: input['avatarUrl'] ?? '',
        );
}

/// 许可协议
class QLLicenseKind {
  const QLLicenseKind({this.name = ''});

  final String name;

  QLLicenseKind.fromJson(Map<String, dynamic> json) : name = json['name'] ?? '';
}

DateTime? _parseDateTime(String? value) =>
    value == null ? null : DateTime.parse(value);

/// Release文件
class QLReleaseAsset {
  const QLReleaseAsset({
    this.name = '',
    this.contentType = '',
    this.size = 0,
    this.downloadCount = 0,
    this.downloadUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  final String name;
  final String contentType;
  final int size;
  final int downloadCount;
  final String downloadUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory QLReleaseAsset.fromJson(Map<String, dynamic> input) {
    input = input['nodes'] ?? input;
    return QLReleaseAsset(
      name: input['name'] ?? '',
      contentType: input['contentType'] ?? '',
      downloadCount: input['downloadCount'] ?? 0,
      downloadUrl: input['downloadUrl'] ?? '',
      size: input['size'] ?? 0,
      createdAt: _parseDateTime(input['createdAt']),
      updatedAt: _parseDateTime(input['updatedAt']),
    );
  }
}

/// Release项目
class QLRelease {
  const QLRelease({
    this.name = '',
    this.author,
    this.tagName = '',
    this.url = '',
    this.isDraft = false,
    this.isPrerelease = false,
    this.isLatest = false,
    this.description = '',
    this.abbreviatedOid = '',
    this.assets,
    this.createdAt,
    this.publishedAt,
  });

  final String name;
  final QLUser? author;
  final String tagName;
  final String url;

  final bool isDraft;
  final bool isPrerelease;
  final bool isLatest;

  final String description;

  /// tagCommit.abbreviatedOid
  final String abbreviatedOid;
  final List<QLReleaseAsset>? assets;

  final DateTime? createdAt;
  final DateTime? publishedAt;

  factory QLRelease.fromJson(Map<String, dynamic> input) {
    return QLRelease(
      name: input['name'] ?? '',
      author: QLUser.fromJson(input['author']),
      tagName: input['tagName'] ?? '',
      url: input['url'] ?? '',
      isDraft: input['isDraft'] ?? false,
      isPrerelease: input['isPrerelease'] ?? false,
      isLatest: input['isLatest'] ?? false,
      description: input['description'] ?? '',
      abbreviatedOid: input['tagCommit']?['abbreviatedOid'] ?? '',
      publishedAt: _parseDateTime(input['updatedAt']),
      createdAt: _parseDateTime(input['createdAt']),
      assets: input['releaseAssets']?['nodes'] == null
          ? null
          : List.from(input['releaseAssets']?['nodes'])
              .map((e) => QLReleaseAsset.fromJson(e))
              .toList(),
    );
  }
}

/// 分支
class QLRef {
  const QLRef({this.name = 'main'});

  final String name;

  QLRef.fromJson(Map<String, dynamic> json) : name = json['name'] ?? 'main';
}

/// 仓库信息
class QLRepository {
  QLRepository({
    this.name = '',
    this.owner,
    this.forksCount = 0,
    this.stargazersCount = 0,
    this.isPrivate = false,
    this.description = '',
    this.isArchived = false,
    this.updatedAt,
    this.pushedAt,
    this.url = '',
    this.openIssuesCount = 0,
    this.license = const QLLicenseKind(),
    this.topics,
    this.isDisabled = false,
    this.forkingAllowed = false,
    this.hasIssuesEnabled = false,
    this.hasProjectsEnabled = false,
    this.hasWikiEnabled = false,
    this.homepageUrl = '',
    this.isFork = false,
    this.isTemplate = false,
    this.mirrorUrl = '',
    this.defaultBranchRef = const QLRef(),
    this.watchersCount = 0,
    this.primaryLanguage = const QLLanguage(),
    this.isInOrganization = false,
    this.openPullRequestsCount = 0,
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
  });

  final String name;
  final QLRepositoryOwner? owner;
  final int forksCount;
  final int stargazersCount;
  final bool isPrivate;
  final String description;
  final bool isArchived;
  final DateTime? updatedAt;
  final DateTime? pushedAt;
  final String url;
  final int openIssuesCount;
  final QLLicenseKind license;
  final List<String>? topics;
  final bool isDisabled;
  final bool forkingAllowed;
  final bool hasIssuesEnabled;
  final bool hasProjectsEnabled;
  final bool hasWikiEnabled;
  final String homepageUrl;
  final bool isFork;
  final bool isTemplate;
  final String mirrorUrl;
  final QLRef defaultBranchRef;
  final int watchersCount;

  final QLLanguage primaryLanguage;
  final bool isInOrganization;
  final int openPullRequestsCount;
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

  String get fullName => "${owner?.login}/$name";

  factory QLRepository.fromJson(Map<String, dynamic> input) {
    input = input['repository'] ?? input;
    return QLRepository(
      name: input['name'] ?? '',
      forksCount: input['forkCount'] ?? 0,
      stargazersCount: input['stargazerCount'] ?? 0,
      isPrivate: input['isPrivate'] ?? false,
      description: input['description'] ?? '',
      isArchived: input['isArchived'] ?? false,
      url: input['url'] ?? '',
      openIssuesCount: input['issues']?['totalCount'] ?? 0,
      isInOrganization: input['isInOrganization'] ?? false,
      diskUsage: input['diskUsage'] ?? 0,
      forkingAllowed: input['forkingAllowed'] ?? false,
      hasIssuesEnabled: input['hasIssuesEnabled'] ?? false,
      hasProjectsEnabled: input['hasProjectsEnabled'] ?? false,
      isDisabled: input['isDisabled'] ?? false,
      hasSponsorshipsEnabled: input['hasSponsorshipsEnabled'] ?? false,
      hasWikiEnabled: input['hasWikiEnabled'] ?? false,
      homepageUrl: input['homepageUrl'] ?? '',
      isBlankIssuesEnabled: input['isBlankIssuesEnabled'] ?? false,
      isEmpty: input['isEmpty'] ?? false,
      isFork: input['isFork'] ?? false,
      isLocked: input['isLocked'] ?? false,
      isMirror: input['isMirror'] ?? false,
      isTemplate: input['isTemplate'] ?? false,
      viewerCanSubscribe: input['viewerCanSubscribe'] ?? false,
      viewerHasStarred: input['viewerHasStarred'] ?? false,
      openPullRequestsCount: input['pullRequests']?['totalCount'] ?? 0,
      watchersCount: input['watchers']?['totalCount'] ?? 0,
      mirrorUrl: input['mirrorUrl'] ?? '',
      defaultBranchRef: input['defaultBranchRef'] == null
          ? const QLRef()
          : QLRef.fromJson(input['defaultBranchRef']),
      releasesCount: input['releases']?['totalCount'] ?? 0,
      refsCount: input['refs']?['totalCount'] ?? 0,
      latestRelease: input['latestRelease'] == null
          ? null
          : QLRelease.fromJson(input['latestRelease']),
      updatedAt: _parseDateTime(input['updatedAt']),
      archivedAt: _parseDateTime(input['archivedAt']),
      pushedAt: _parseDateTime(input['pushedAt']),
      primaryLanguage: input['primaryLanguage'] != null
          ? QLLanguage.fromJson(input['primaryLanguage'])
          : const QLLanguage(),
      owner: input['owner'] != null
          ? QLRepositoryOwner.fromJson(input['owner'])
          : null,
      license: input['licenseInfo'] != null
          ? QLLicenseKind.fromJson(input['licenseInfo'])
          : const QLLicenseKind(),
      topics: input['repositoryTopics']?['nodes'] == null
          ? null
          : List.of(input['repositoryTopics']?['nodes'])
              .map((e) => "${e['topic']?['name'] ?? ''}")
              .toList(),
    );
  }
}

/// 列表
class QLList<T> {
  const QLList({
    required this.data,
    this.pageInfo,
  });
  final List<T> data;
  final QLPageInfo? pageInfo;

  QLList.fromJson(
    Map<String, dynamic> input,
    T Function(Map<String, dynamic>) convert,
  )   : data = input['nodes'] == null
            ? []
            : List.from(input['nodes'] as List)
                .map((e) => convert(e))
                .toList(),
        pageInfo = input['pageInfo'] == null
            ? null
            : QLPageInfo.fromJson(input['pageInfo']);
}

/// 组织用户
class QLOrganization extends QLUserBase {
  const QLOrganization({
    required super.login,
  });
}

/// 个人用户
class QLUser extends QLUserBase {
  const QLUser({
    required super.login,
    super.avatarUrl,
    this.url = '',
    this.name = '',
    this.company = '',
    this.websiteUrl = '',
    this.location = '',
    this.email = '',
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.twitterUsername = '',
    this.pinnedItems,
  });

  final String url;
  final String name;
  final String company;
  final String websiteUrl;
  final String location;
  final String email;
  final String bio;
  final int followersCount;
  final int followingCount;
  final String twitterUsername;

  /// 置顶项目
  final List<QLRepository>? pinnedItems;

  factory QLUser.fromJson(Map<String, dynamic> input) {
    input = input['viewer'] ?? input['user'] ?? input;
    return QLUser(
      login: input['login'] ?? '',
      name: input['name'] ?? '',
      avatarUrl: input['avatarUrl'] ?? '',
      company: input['company'] ?? '',
      bio: input['bio'] ?? '',
      email: input['email'] ?? '',
      location: input['location'] ?? '',
      twitterUsername: input['twitterUsername'] ?? '',
      url: input['url'] ?? '',
      websiteUrl: input['websiteUrl'] ?? '',
      followersCount: input['followers']?['totalCount'] ?? 0,
      followingCount: input['following']?['totalCount'] ?? 0,
      pinnedItems: input['pinnedItems']?['nodes'] != null
          ? List.of(input['pinnedItems']?['nodes'])
              .map((e) => QLRepository.fromJson(e))
              .toList()
          : null,
    );
  }
}

/// Issue
class QLIssue extends Issue {
  QLIssue();
  factory QLIssue.fromJson(Map<String, dynamic> input) {
    return QLIssue();
  }
  @override
  Map<String, dynamic> toJson() => {};
}

/// GraphQL查询
class QLQuery {
  const QLQuery(
    this.body, {
    this.variables,
    this.operationName,
    this.isQuery = true,
  });
  final String body;
  final Map<String, String>? variables;
  final String? operationName;
  final bool isQuery;

  /// 编码后的graphql
  String get jsonText => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        //TODO: mutation 是不是这样操作呢？还没测试过，到时候测试了再说吧
        "query": isQuery ? "query {\n $body \n}" : "mutation {\rn $body \n}",
        if (variables != null) "variables": variables,
        if (operationName != null) "operationName": operationName,
      };
}

/// GraphQL查询
/// https://docs.github.com/zh/graphql/reference/queries
///
/// gh命令行
/// https://cli.github.com/manual/gh_api
///
/// GitHub GraphQL API 文档
/// https://docs.github.com/zh/graphql
///

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
    QLQuery query, {
    void Function(http.Response response)? fail,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    JSONConverter<S, T?>? convert,
  }) =>
      _request(query,
          fail: fail, headers: headers, params: params, convert: convert);

  //  "Content-Type: application/json",
  //   "Accept: application/vnd.github.v4.idl"

  /// 修改操作
  Future<T> mutation<S, T>(
    QLQuery query, {
    void Function(http.Response response)? fail,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    JSONConverter<S, T?>? convert,
  }) async =>
      _request(query,
          fail: fail, headers: headers, params: params, convert: convert);

  /// 忽略path字段，强制为[endpoint]，本可不这样做的，但是他内部的[request]方法在判断[path]时
  /// 附加了一个”/“符号，造成服务端识为这是一个rest API。
  /// 暂时不公开，之后再看吧
  /// Accept: application/vnd.github+json.
  Future<T> _request<S, T>(
    QLQuery query, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    void Function(http.Response response)? fail,
    JSONConverter<S, T?>? convert,
  }) async {
    if (kDebugMode) {
      //print("body: ${query.jsonText}");
    }

    //convert ??= (input) => input as T?;
    headers ??= {};
    final response = await _github.request("POST", endpoint,
        headers: headers,
        params: params,
        body: query.jsonText,
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
