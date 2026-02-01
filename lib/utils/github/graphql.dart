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

  /// 起始游标
  final String startCursor;

  /// 结束位置游标
  final String endCursor;

  /// 是否有下一页
  final bool hasNextPage;

  /// 是否有上一页
  final bool hasPreviousPage;

  QLPageInfo.fromJson(Map<String, dynamic> input)
      : startCursor = input['startCursor'] ?? '',
        endCursor = input['endCursor'] ?? '',
        hasNextPage = input['hasNextPage'] ?? false,
        hasPreviousPage = input['hasPreviousPage'] ?? false;
}

/// 列表
class QLList<T> {
  const QLList({
    this.totalCount = 0,
    this.pageInfo,
  }) : _data = const [];
  final List<T> _data;
  final int totalCount;
  final QLPageInfo? pageInfo;

  /// 内部数据
  List<T> get data => _data;
  operator [](index) => _data[index];
  //operator []=(index, value) => data[index] = value;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;
  int get length => _data.length;
  //void clear() => _data.clear();

  QLList.fromJson(
    Map<String, dynamic> input,
    T Function(Map<String, dynamic>) convert,
  )   : _data = input['nodes'] == null
            ? []
            : List.from(input['nodes'] as List).map((e) => convert(e)).toList(),
        totalCount = input['totalCount'] ?? 0,
        pageInfo = input['pageInfo'] == null
            ? null
            : QLPageInfo.fromJson(input['pageInfo']);

  /// 空数据
  const QLList.empty()
      : _data = const [],
        totalCount = 0,
        pageInfo = null;
}

/// 仓库的主语言
class QLLanguage {
  const QLLanguage({
    this.color = '',
    this.name = '',
  });

  /// 语言所使用的颜色
  final String color;

  /// 语言名
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

  /// 用户名
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

  /// 用户或者组织的html url
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

  /// 许可协议名
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

  /// 文件名
  final String name;

  /// 文件内容类型
  final String contentType;

  /// 文件大小
  final int size;

  /// 下载次数
  final int downloadCount;

  /// HTTP的下载地址
  final String downloadUrl;

  /// 创建时间
  final DateTime? createdAt;

  /// 更新时间
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

  /// Release名
  final String name;

  /// 发布者信息
  final QLUser? author;

  /// 标记名
  final String tagName;

  /// HTTP的链接
  final String url;

  /// 是否为草稿，这个一般只有自己的而且登录了能看到吧
  final bool isDraft;

  /// 是否为预览版
  final bool isPrerelease;

  /// 是否为最后一次发布的版本
  final bool isLatest;

  /// 描述，一般为 Release Notes
  final String description;

  /// tagCommit.abbreviatedOid
  /// 使用哪个commit为准发布的
  final String abbreviatedOid;

  /// 文件附件
  final List<QLReleaseAsset>? assets;

  /// 创建时间
  final DateTime? createdAt;

  /// 推送时间
  final DateTime? publishedAt;

  QLRelease.fromJson(Map<String, dynamic> input)
      : name = input['name'] ?? '',
        author = QLUser.fromJson(input['author']),
        tagName = input['tagName'] ?? '',
        url = input['url'] ?? '',
        isDraft = input['isDraft'] ?? false,
        isPrerelease = input['isPrerelease'] ?? false,
        isLatest = input['isLatest'] ?? false,
        description = input['description'] ?? '',
        abbreviatedOid = input['tagCommit']?['abbreviatedOid'] ?? '',
        publishedAt = _parseDateTime(input['updatedAt']),
        createdAt = _parseDateTime(input['createdAt']),
        assets = input['releaseAssets']?['nodes'] == null
            ? null
            : List.from(input['releaseAssets']?['nodes'])
                .map((e) => QLReleaseAsset.fromJson(e))
                .toList();
}

/// 分支
///
/// TODO: 这默认是用啥呢main?或者master？这个HEAD应该能用吧？
class QLRef {
  const QLRef({this.name = 'HEAD'});

  /// 分支或者tag名
  final String name;

  QLRef.fromJson(Map<String, dynamic> json) : name = json['name'] ?? 'HEAD';
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

  /// 仓库名
  final String name;

  /// 仓库所有者
  final QLRepositoryOwner? owner;

  /// 被fork的总数
  final int forksCount;

  /// 被点赞的总数
  final int stargazersCount;

  /// 是否为私有项目
  final bool isPrivate;

  /// 仓库描述
  final String description;

  /// 是否已归档
  final bool isArchived;

  /// 更新时间
  final DateTime? updatedAt;

  /// 最后推送时间
  final DateTime? pushedAt;

  /// 仓库HTTP链接
  final String url;

  /// 仓库牌打开的issues总数
  final int openIssuesCount;

  /// 仓库许可协议信息
  final QLLicenseKind license;

  /// 仓库标签列表，可被搜索的tag
  final List<String>? topics;

  /// 是否被禁用
  final bool isDisabled;

  ///  是否允许被fork？？？
  final bool forkingAllowed;

  /// 是否启用了issues
  final bool hasIssuesEnabled;

  /// 是否启用了Projects
  final bool hasProjectsEnabled;

  /// 是否启用了WIKI页
  final bool hasWikiEnabled;

  /// 自定义的一个主页
  final String homepageUrl;

  /// 是否fork？这个值是自己当前？
  final bool isFork;

  /// 是否为一个模板
  final bool isTemplate;

  /// 镜像地址
  final String mirrorUrl;

  /// 默认分支信息
  final QLRef defaultBranchRef;

  /// 仓库关注数
  final int watchersCount;

  /// 仓库主要使用的编程语言
  final QLLanguage primaryLanguage;

  /// 是否为一个组织的项目
  final bool isInOrganization;

  /// 当前处于打开状态的合并请求
  final int openPullRequestsCount;

  /// 归档时间
  final DateTime? archivedAt;

  /// 使用磁盘空间大小
  final int diskUsage;

  /// 是否有赞助按钮？
  final bool hasSponsorshipsEnabled;
  final bool isBlankIssuesEnabled;

  /// 是否为空仓库
  final bool isEmpty;

  /// 是否被锁定
  final bool isLocked;

  /// 是否为一个镜像
  final bool isMirror;

  /// 当前用户能定阅，应该要登录吧
  final bool viewerCanSubscribe;

  /// 当前用户能点赞，应该要登录吧
  final bool viewerHasStarred;

  /// Release总数量
  final int releasesCount;

  /// 最后一次发布的信息
  final QLRelease? latestRelease;

  /// 分支或者tag总数
  final int refsCount;

  /// 仓库全名：${owner.login}/$name
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

/// 组织用户
class QLOrganization extends QLUserBase {
  const QLOrganization({
    required super.login,
  });

  factory QLOrganization.fromJson(Map<String, dynamic> input) {
    input = input['viewer'] ?? input['organization'] ?? input;
    return QLOrganization(
      login: input['login'] ?? '',
      // name: input['name'] ?? '',
      // avatarUrl: input['avatarUrl'] ?? '',
      // company: input['company'] ?? '',
      // bio: input['bio'] ?? '',
      // email: input['email'] ?? '',
      // location: input['location'] ?? '',
      // twitterUsername: input['twitterUsername'] ?? '',
      // url: input['url'] ?? '',
      // websiteUrl: input['websiteUrl'] ?? '',
      // followersCount: input['followers']?['totalCount'] ?? 0,
      // followingCount: input['following']?['totalCount'] ?? 0,
      // pinnedItems: input['pinnedItems']?['nodes'] != null
      //     ? List.of(input['pinnedItems']?['nodes'])
      //     .map((e) => QLRepository.fromJson(e))
      //     .toList()
      //     : null,
    );
  }
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

  /// 链接地址，比如 https://github.com/{user-name}
  final String url;

  /// 用户昵称
  final String name;

  /// 公司信息
  final String company;

  /// 个人网站
  final String websiteUrl;

  /// 位置
  final String location;

  /// 邮箱
  final String email;

  /// 签名信息
  final String bio;

  /// 关注“我”的人
  final int followersCount;

  /// “我”关注的人
  final int followingCount;

  /// twitter用户名，现在为x的用户名
  final String twitterUsername;

  /// 置顶项目
  final List<QLRepository>? pinnedItems;

  factory QLUser.fromJson(Map<String, dynamic> input) {
    input = input['viewer'] ?? input['user'] ?? input['organization'] ?? input;
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

/// 内容树，包含目录和文件列表
///
/// https://docs.github.com/zh/graphql/reference/objects#tree
class QLTree {
  const QLTree({
    this.extension = '',
    this.language = const QLLanguage(),
    this.isGenerated = false,
    this.lineCount = 0,
    this.name = '',
    this.path = '',
    this.size = 0,
    this.type = '',
  });

  /// 文件扩展名
  final String extension;

  /// 本文件所用的编程语言
  final QLLanguage language;

  /// 是否生成此树状条目
  final bool isGenerated;

  /// 文件行数
  final int lineCount;

  /// 文件名
  final String name;

  /// Entry file name. (Base64-encoded).
  /// nameRaw

  /// 文件路径
  final String path;

  /// The full path of the file. (Base64-encoded).
  /// pathRaw

  /// 文件size
  final int size;

  /// 类型： `blob`=文件、`tree`=目录
  final String type;

  /// submodule (Submodule)
  ///
  /// If the TreeEntry is for a directory occupied by a submodule project, this returns the corresponding submodule.
}

/// 文件数据
///
/// https://docs.github.com/zh/graphql/reference/objects#blob
class QLBlob {
  const QLBlob({
    this.oid = '',
    this.byteSize = 0,
    this.isBinary = false,
    this.isTruncated = false,
    this.text = '',
  });

  /// Git 对象 ID
  final String oid;

  /// Blob 对象的字节大小
  final int byteSize;

  /// 指示 Blob 是二进制数据还是文本数据。如果无法确定编码方式，则返回 null
  final bool isBinary;

  /// 指示内容是否被截断
  final bool isTruncated;

  /// 如果`binary=true`则为`null`，否则为一个UTF8文本数据
  final String text;
}

///=============================================================================

/// GraphQL查询
class QLQuery {
  const QLQuery(
    this.body, {
    this.variables,
    this.operationName,
    this.isQuery = true,
  });

  /// ql语句，不包含query{}或者mutation {}的主体
  final String body;

  /// [body]中使用的变量
  final Map<String, String>? variables;

  /// 这个我也不知道干啥的（难道是有多个ql语句指定操作哪个的？？？，没研究过）
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

  /// 认证信息
  Authentication auth;

  /// API挂截点
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
