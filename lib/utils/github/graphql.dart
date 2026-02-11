import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:gh_app/utils/utils.dart';
import 'package:http/http.dart' as http;

import 'graphql_querys.dart';
import 'http_cache.dart';

/// 分页信息，按规则传递。比如：
/// 每页10个
/// 从前往后选择的
/// first: 10, after: "$endCursor"
///
/// 从后往前选择
/// last: 10, before: "$startCursor "
///
/// https://docs.github.com/zh/graphql/reference/objects#pageinfo
class QLPageInfo {
  QLPageInfo({
    this.startCursor,
    this.endCursor,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  /// `String` 起始游标
  final String? startCursor;

  /// `String` 结束位置游标
  final String? endCursor;

  /// `Boolean!` 是否有下一页
  final bool hasNextPage;

  /// `Boolean!` 是否有上一页
  final bool hasPreviousPage;

  QLPageInfo.fromJson(Map<String, dynamic> input)
      : startCursor = input['startCursor'],
        endCursor = input['endCursor'],
        hasNextPage = input['hasNextPage'] ?? false,
        hasPreviousPage = input['hasPreviousPage'] ?? false;
}

/// 列表
class QLList<T> {
  const QLList({
    this.totalCount = 0,
    this.pageInfo,
    this.pageSize = 0,
  }) : _data = const [];
  final List<T> _data;
  final int totalCount;
  final QLPageInfo? pageInfo;
  final int pageSize;

  /// 内部数据
  List<T> get data => _data;
  T operator [](index) => _data[index];
  operator []=(index, T value) => data[index] = value;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;
  int get length => _data.length;
  T get first => _data.first;
  T? get firstOrNull => _data.firstOrNull;
  T get last => _data.last;
  T? get lastOrNull => _data.lastOrNull;
  Iterable<E> map<E>(E Function(T e) toElement) => _data.map(toElement);

  //void clear() => _data.clear();

  QLList.fromJson(
      Map<String, dynamic> input, T Function(Map<String, dynamic>) convert,
      {this.pageSize = 0, String? totalCountAlias, String? fieldName})
      : _data = input['nodes'] == null
            ? []
            : List.from(input['nodes'] as List)
                .map((e) => convert(fieldName != null ? e[fieldName] : e))
                .toList(),
        totalCount = input[totalCountAlias ?? 'totalCount'] ?? 0,
        pageInfo = input['pageInfo'] == null
            ? null
            : QLPageInfo.fromJson(input['pageInfo']);

  /// 一个允许为null的类
  static QLList<T>? maybeFromJson<T>(
          Map<String, dynamic>? input, T Function(Map<String, dynamic>) convert,
          {int pageSize = 0, String? totalCountAlias, String? fieldName}) =>
      input == null
          ? null
          : QLList<T>.fromJson(input, convert,
              pageSize: pageSize,
              totalCountAlias: totalCountAlias,
              fieldName: fieldName);

  /// 空数据
  // const QLList.empty()
  //     : _data = const [],
  //       totalCount = 0,
  //       pageSize = 0,
  //       pageInfo = null;
}

/// 仓库的主语言
///
/// https://docs.github.com/zh/graphql/reference/objects#language
class QLLanguage {
  const QLLanguage({
    this.color = '',
    this.name = '',
  });

  /// `String` 语言所使用的颜色
  final String color;

  /// `String!` 语言名
  final String name;

  QLLanguage.fromJson(Map<String, dynamic> input)
      : color = input['color'] ?? '',
        name = input['name'] ?? '';

  static QLLanguage? maybeFromJson(Map<String, dynamic>? input) =>
      input == null ? null : QLLanguage.fromJson(input);
}

/// 用户信息基础类，包含用户和组织等
///
/// https://docs.github.com/zh/graphql/reference/interfaces#actor
class QLActor {
  const QLActor({
    required this.login,
    this.avatarUrl = '',
    this.url = '',
  });

  /// `String!` The username of the actor.
  final String login;

  /// `String!` A URL pointing to the actor's public avatar.
  final String avatarUrl;

  /// `URI!` 用户或者组织的html url
  /// 链接地址，比如 https://github.com/{user-name}
  final String url;

  QLActor.fromJson(Map<String, dynamic> input)
      : url = input['url'] ?? '',
        login = input['login'] ?? '',
        avatarUrl = input['avatarUrl'] ?? '';

  static QLActor? maybeFromJson(Map<String, dynamic>? input) =>
      input == null ? null : QLActor.fromJson(input);
}

/// 仓库所有者
///
/// https://docs.github.com/zh/graphql/reference/interfaces#repositoryowner
class QLRepositoryOwner extends QLActor {
  const QLRepositoryOwner({
    required super.login,
    super.avatarUrl,
    super.url,
  });

  QLRepositoryOwner.fromJson(Map<String, dynamic> input)
      : super(
          url: input['url'] ?? '',
          login: input['login'] ?? '',
          avatarUrl: input['avatarUrl'] ?? '',
        );

  factory QLRepositoryOwner.fromJsonAndDefault(Map<String, dynamic>? input) =>
      input == null
          ? const QLRepositoryOwner(login: '')
          : QLRepositoryOwner.fromJson(input);
}

/// 许可协议
///
/// https://docs.github.com/zh/graphql/reference/objects#license
class QLLicense {
  const QLLicense({this.name = ''});

  /// `String!` 许可协议名
  final String name;

  QLLicense.fromJson(Map<String, dynamic> json) : name = json['name'] ?? '';

  static QLLicense? maybeFromJson(Map<String, dynamic>? json) =>
      json == null ? null : QLLicense.fromJson(json);
}

/// 解析时间
DateTime? _parseDateTime(String? value) =>
    value == null ? null : DateTime.parse(value);

/// 解析 ['tags']?['totalCount'] 这类的，并返回
int _getTotalCount(Map<String, dynamic>? json) => json?['totalCount'] ?? 0;

/// Release文件
///
/// https://docs.github.com/zh/graphql/reference/objects#releaseasset
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

  /// `String!` 文件名
  final String name;

  /// `String!` 文件内容类型
  final String contentType;

  /// `Int!` 文件大小
  final int size;

  /// `Int!` 下载次数
  final int downloadCount;

  /// `URI!` HTTP的下载地址
  final String downloadUrl;

  /// `DateTime!` 创建时间
  final DateTime? createdAt;

  /// `DateTime!` 更新时间
  final DateTime? updatedAt;

  QLReleaseAsset.fromJson(Map<String, dynamic> input)
      : name = input['name'] ?? '',
        contentType = input['contentType'] ?? '',
        downloadCount = input['downloadCount'] ?? 0,
        downloadUrl = input['downloadUrl'] ?? '',
        size = input['size'] ?? 0,
        createdAt = _parseDateTime(input['createdAt']),
        updatedAt = _parseDateTime(input['updatedAt']);
}

/// Release项目
///
/// https://docs.github.com/zh/graphql/reference/objects#release
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
    //this.assets,
    this.assetsCount = 0,
    this.createdAt,
    this.publishedAt,
  });

  /// `String` Release名
  final String name;

  /// `User` 发布者信息
  final QLUser? author;

  /// `String!` 标记名
  final String tagName;

  /// `URI!` HTTP的链接
  final String url;

  /// `Boolean!` 是否为草稿，这个一般只有自己的而且登录了能看到吧
  final bool isDraft;

  /// `Boolean!` 是否为预览版
  final bool isPrerelease;

  /// `Boolean!` 是否为最后一次发布的版本
  final bool isLatest;

  /// `String` 描述，一般为 Release Notes
  final String description;

  /// `Commit.String!` tagCommit.abbreviatedOid
  /// 使用哪个commit为准发布的
  final String abbreviatedOid;

  /// 文件附件
  ///final List<QLReleaseAsset>? assets;

  /// `ReleaseAssetConnection!.Int!`附件总数，这里不再查询全部的了
  final int assetsCount;

  /// `DateTime!` 创建时间
  final DateTime? createdAt;

  /// `DateTime` 推送时间
  final DateTime? publishedAt;

  QLRelease.fromJson(Map<String, dynamic> input)
      : name = input['name'] ?? '',
        author = QLUser.maybeFromJson(input['author']),
        tagName = input['tagName'] ?? '',
        url = input['url'] ?? '',
        isDraft = input['isDraft'] ?? false,
        isPrerelease = input['isPrerelease'] ?? false,
        isLatest = input['isLatest'] ?? false,
        description = input['description'] ?? '',
        abbreviatedOid = input['tagCommit']?['abbreviatedOid'] ?? '',
        publishedAt = _parseDateTime(input['updatedAt']),
        createdAt = _parseDateTime(input['createdAt']),
        assetsCount = _getTotalCount(input['releaseAssets']);
// assets = input['releaseAssets']?['nodes'] == null
//     ? null
//     : List.from(input['releaseAssets']?['nodes'])
//         .map((e) => QLReleaseAsset.fromJson(e))
//         .toList();

  static QLRelease? maybeFromJson(Map<String, dynamic>? input) =>
      input == null ? null : QLRelease.fromJson(input);
}

/// 分支
///
/// TODO: 这默认是用啥呢main?或者master？这个HEAD应该能用吧？
///
/// https://docs.github.com/zh/graphql/reference/objects#ref
class QLRef {
  const QLRef({
    this.name = 'HEAD',
    this.prefix = 'refs/heads/',
    this.target,
  });

  /// `String!` 分支或者tag名
  final String name;

  /// `String!` The ref's prefix, such as refs/heads/ or refs/tags/.
  final String prefix;

  /// `GitObject` The object the ref points to. Returns null when object does not exist.
  final QLGitObject? target;

  QLRef.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? 'HEAD',
        prefix = json['prefix'] ?? 'refs/heads/',
        target = QLGitObject.maybeFromJson(json['target']);

  static QLRef? maybeFromJson(Map<String, dynamic>? json) =>
      json == null ? null : QLRef.fromJson(json);
}

/// https://docs.github.com/zh/graphql/reference/enums#repositorypermission
///// ignore: constant_identifier_names
enum QLRepositoryPermission {
  /// Can read, clone, and push to this repository. Can also manage issues, pull requests, and repository settings, including adding collaborators.
  admin,

  /// Can read, clone, and push to this repository. They can also manage issues, pull requests, and some repository settings.
  maintain,

  /// Can read and clone this repository. Can also open and comment on issues and pull requests.
  read,

  /// Can read and clone this repository. Can also manage issues and pull requests.
  triage,

  /// Can read, clone, and push to this repository. Can also manage issues and pull requests.
  write,
}

/// https://docs.github.com/zh/graphql/reference/enums#subscriptionstate
enum QLSubscriptionState {
  /// The User is never notified.
  ignored,

  /// The User is notified of all conversations.
  subscribed,

  /// The User is only notified when participating or @mentioned.
  unsubscribed,
}

/// 仓库信息
///
/// https://docs.github.com/zh/graphql/reference/objects#repository
class QLRepository {
  QLRepository({
    this.name = '',
    this.owner = const QLRepositoryOwner(login: ''),
    this.parent,
    this.forksCount = 0,
    this.stargazersCount = 0,
    this.isPrivate = false,
    this.description = '',
    this.isArchived = false,
    this.updatedAt,
    this.pushedAt,
    this.createdAt,
    this.url = '',
    this.openIssuesCount = 0,
    this.licenseInfo,
    this.repositoryTopics,
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
    this.primaryLanguage,
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
    this.permission,
    this.viewerSubscription,
    this.releasesCount = 0,
    this.latestRelease,
    this.refsCount = 0,
    this.tagsCount = 0,
    this.languages,
  });

  /// `String!` 仓库名
  final String name;

  /// `RepositoryOwner!` 仓库所有者
  final QLRepositoryOwner owner;

  /// `Repository` 父仓库，一般为fork来的
  final QLRepository? parent;

  /// `GistConnection!.Int!` 被fork的总数
  final int forksCount;

  /// `Int!` 被点赞的总数
  final int stargazersCount;

  /// `Boolean` 是否为私有项目
  final bool isPrivate;

  /// `String` 仓库描述
  final String description;

  /// `Boolean!` 是否已归档
  final bool isArchived;

  /// `DateTime!` 更新时间
  final DateTime? updatedAt;

  /// `DateTime!` 创建时间
  /// TODO: 字段没在查询中，只是放在，以后再弄
  final DateTime? createdAt;

  /// `DateTime` 最后推送时间
  final DateTime? pushedAt;

  /// `URI!` 仓库HTTP链接
  final String url;

  /// `IssueConnection!.Int!` 仓库牌打开的issues总数
  final int openIssuesCount;

  /// `License` 仓库许可协议信息
  final QLLicense? licenseInfo;

  /// `RepositoryTopicConnection!` 仓库标签列表，可被搜索的tag  实际字段 `repositoryTopics`
  final QLList<QLTopic>? repositoryTopics;

  /// `Boolean!` 是否被禁用
  final bool isDisabled;

  /// `Boolean!` 是否允许被fork？？？
  final bool forkingAllowed;

  /// `Boolean!` 是否启用了issues
  final bool hasIssuesEnabled;

  /// `Boolean!` 是否启用了Projects
  final bool hasProjectsEnabled;

  /// `Boolean!` 是否启用了WIKI页
  final bool hasWikiEnabled;

  /// `URI` 自定义的一个主页
  final String homepageUrl;

  /// `Boolean!` 是否fork？这个值是自己当前？
  final bool isFork;

  /// `Boolean!` 是否为一个模板
  final bool isTemplate;

  /// `URI` 镜像地址
  final String mirrorUrl;

  /// `Ref` 默认分支信息
  final QLRef defaultBranchRef;

  /// `UserConnection!.Int!` 仓库关注数
  final int watchersCount;

  /// `Language` 仓库主要使用的编程语言
  final QLLanguage? primaryLanguage;

  /// `Boolean!` 是否为一个组织的项目
  final bool isInOrganization;

  /// `PullRequestConnection!.Int!` 当前处于打开状态的合并请求
  final int openPullRequestsCount;

  /// `DateTime` 归档时间
  final DateTime? archivedAt;

  /// `Int` 使用磁盘空间大小
  final int diskUsage;

  /// `Boolean!` 是否有赞助按钮？
  final bool hasSponsorshipsEnabled;

  /// `Boolean!`
  final bool isBlankIssuesEnabled;

  /// `Boolean!` 是否为空仓库
  final bool isEmpty;

  /// `Boolean!` 是否被锁定
  final bool isLocked;

  /// `Boolean!` 是否为一个镜像
  final bool isMirror;

  /// `Boolean!` 当前用户能定阅，应该要登录吧
  final bool viewerCanSubscribe;

  /// `Boolean!` 当前用户能点赞，应该要登录吧
  final bool viewerHasStarred;

  /// `RepositoryPermission` 当前查看者权限
  final QLRepositoryPermission? permission;

  /// `SubscriptionState` 当前查看者定阅状态
  final QLSubscriptionState? viewerSubscription;

  /// `ReleaseConnection!.Int!`Release总数量
  final int releasesCount;

  /// `Release` 最后一次发布的信息
  final QLRelease? latestRelease;

  /// `RefConnection.Int!` 分支总数
  final int refsCount;

  /// `RefConnection.Int!` tags总数
  final int tagsCount;

  /// 语言列表
  final QLList<QLLanguage>? languages;

  /// 仓库全名：${owner.login}/$name
  /// 其实也可以使用`nameWithOwner`来读取
  String get fullName => "${owner.login}/$name";

  /// 当前查看用户是否已订阅，也就是watch
  bool get viewerHasSubscribed =>
      viewerSubscription == QLSubscriptionState.subscribed;

  static QLRepository? maybeFromJson(Map<String, dynamic>? input) =>
      input == null ? null : QLRepository.fromJson(input);

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
      openIssuesCount: _getTotalCount(input['issues']),
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
      permission: input['viewerPermission'] == null
          ? null
          : enumFromStringValue(
              QLRepositoryPermission.values,
              (input['viewerPermission'] as String).toLowerCase(),
              QLRepositoryPermission.read),
      viewerSubscription: input['viewerSubscription'] == null
          ? null
          : enumFromStringValue(
              QLSubscriptionState.values,
              (input['viewerSubscription'] as String).toLowerCase(),
              QLSubscriptionState.ignored),
      openPullRequestsCount: _getTotalCount(input['pullRequests']),
      watchersCount: _getTotalCount(input['watchers']),
      mirrorUrl: input['mirrorUrl'] ?? '',
      defaultBranchRef:
          QLRef.maybeFromJson(input['defaultBranchRef']) ?? const QLRef(),
      releasesCount: _getTotalCount(input['releases']),
      refsCount: _getTotalCount(input['refs']),
      tagsCount: _getTotalCount(input['tags']),
      latestRelease: QLRelease.maybeFromJson(input['latestRelease']),
      updatedAt: _parseDateTime(input['updatedAt']),
      archivedAt: _parseDateTime(input['archivedAt']),
      pushedAt: _parseDateTime(input['pushedAt']),
      primaryLanguage: QLLanguage.maybeFromJson(input['primaryLanguage']),
      owner: QLRepositoryOwner.fromJsonAndDefault(input['owner']),
      licenseInfo: QLLicense.maybeFromJson(input['licenseInfo']),
      repositoryTopics: QLList.maybeFromJson(
          input['repositoryTopics'], QLTopic.fromJson,
          fieldName: 'topic'),
      parent: QLRepository.maybeFromJson(input['parent']),
      languages: QLList.maybeFromJson(input['languages'], QLLanguage.fromJson),
    );
  }
}

/// 用户状态
///
/// https://docs.github.com/zh/graphql/reference/objects#userstatus
class QLUserStatus {
  const QLUserStatus({this.emoji = '', this.emojiHTML = '', this.message = ''});

  final String emoji;
  final String emojiHTML;
  final String message;

  QLUserStatus.fromJson(Map<String, dynamic> input)
      : emoji = input['emoji']?.replaceAll(":", "") ?? '',
        emojiHTML = input['emojiHTML'] ?? '',
        message = input['message'] ?? '';
}

/// 用户和组织公用的
class QLUserOrOrganizationCommon extends QLActor {
  const QLUserOrOrganizationCommon({
    required super.login,
    super.avatarUrl,
    super.url,
    this.createdAt,
    this.name = '',
    this.email = '',
    this.location = '',
    this.twitterUsername = '',
    this.websiteUrl = '',
    this.pinnedItems = const QLList(),
    required this.isOrganization,
    this.repositoryCount = 0,
  });

  /// createdAt (DateTime!)
  final DateTime? createdAt;

  /// `String` 用户昵称
  final String name;

  /// `String!` 邮箱
  final String email;

  /// `String` 位置
  final String location;

  /// `String` twitter用户名，现在为x的用户名
  final String twitterUsername;

  /// `URI` 个人网站
  final String websiteUrl;

  /// `PinnableItemConnection!` 置顶项目
  final QLList<QLRepository> pinnedItems;

  /// 这个字段是用于公用时判断的
  final bool isOrganization;

  /// 仓库总数，
  /// repositories (RepositoryConnection!)  A list of repositories that the user owns.
  final int repositoryCount;

  /// name或者login，有一个不为空的，优先name
  String get nonEmptyName => name.isEmpty ? login : name;
}

/// 个人用户
///
/// https://docs.github.com/zh/graphql/reference/objects#user
class QLUser extends QLUserOrOrganizationCommon {
  const QLUser({
    required super.login,
    super.avatarUrl,
    super.url,
    super.createdAt,
    super.name,
    super.email,
    super.location,
    super.twitterUsername,
    super.websiteUrl,
    super.pinnedItems,
    super.isOrganization = false,
    super.repositoryCount,
    this.isViewer = false,
    this.company = '',
    this.bio = '',
    this.status,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  /// `Boolean!` 是否登录的用户
  final bool isViewer;

  /// `String` 公司信息
  final String company;

  /// `String` 签名信息
  final String bio;

  /// `UserStatus` 用户状态
  final QLUserStatus? status;

  /// `FollowingConnection!.Int!` 关注“我”的人
  final int followersCount;

  /// `FollowerConnection!.Int!` “我”关注的人
  final int followingCount;

  //createdAt (DateTime!)
  //isFollowingViewer (Boolean!)
  //userViewType (UserViewType!)

  factory QLUser.fromJson(Map<String, dynamic> input) {
    input = input['viewer'] ?? input['user'] ?? input['organization'] ?? input;
    return QLUser(
      isOrganization: false,
      login: input['login'] ?? '',
      name: input['name'] ?? '',
      avatarUrl: input['avatarUrl'] ?? '',
      company: input['company'] ?? '',
      bio: input['bio'] ?? '',
      status: input['status'] == null
          ? const QLUserStatus()
          : QLUserStatus.fromJson(input['status']),
      email: input['email'] ?? '',
      location: input['location'] ?? '',
      twitterUsername: input['twitterUsername'] ?? '',
      url: input['url'] ?? '',
      isViewer: input['isViewer'] ?? false,
      websiteUrl: input['websiteUrl'] ?? '',
      followersCount: _getTotalCount(input['followers']),
      followingCount: _getTotalCount(input['following']),
      repositoryCount: _getTotalCount(input['repositories']),
      pinnedItems:
          QLList.maybeFromJson(input['pinnedItems'], QLRepository.fromJson) ??
              const QLList(),
    );
  }

  static QLUser? maybeFromJson(Map<String, dynamic>? input) =>
      input == null ? null : QLUser.fromJson(input);
}

/// 组织用户
///
/// 不要那么多东西，所以合并到QLUser上面
///
/// https://docs.github.com/zh/graphql/reference/objects#organization
///
class QLOrganization extends QLUserOrOrganizationCommon {
  const QLOrganization({
    required super.login,
    super.avatarUrl,
    super.url,
    super.createdAt,
    super.name,
    super.email,
    super.location,
    super.twitterUsername,
    super.websiteUrl,
    super.pinnedItems,
    super.isOrganization = true,
    super.repositoryCount,
    this.description = '',
  });

  /// description (String)
  final String description;
  // isVerified (Boolean!)
  // organizationBillingEmail (String)
  // teams (TeamConnection!)
  //viewerCanCreateRepositories (Boolean!)
  //
  // Viewer can create repositories on this organization.
  //
  // viewerCanCreateTeams (Boolean!)
  //
  // Viewer can create teams on this organization.
  //
  // viewerCanSponsor (Boolean!)
  //
  // Whether or not the viewer is able to sponsor this user/organization.
  //
  // viewerIsAMember (Boolean!)
  //
  // Viewer is an active member of this organization.
  //
  // viewerIsFollowing (Boolean!)
  //
  // Whether or not this Organization is followed by the viewer.
  //
  // viewerIsSponsoring (Boolean!)
  //
  // True if the viewer is sponsoring this user/organization.
  //
  // webCommitSignoffRequired (Boolean!)

  factory QLOrganization.fromJson(Map<String, dynamic> input) {
    input = input['viewer'] ?? input['organization'] ?? input;
    return QLOrganization(
      isOrganization: true,
      login: input['login'] ?? '',
      avatarUrl: input['avatarUrl'] ?? '',
      url: input['url'] ?? '',
      name: input['name'] ?? '',
      email: input['email'] ?? '',
      location: input['location'] ?? '',
      twitterUsername: input['twitterUsername'] ?? '',
      websiteUrl: input['websiteUrl'] ?? '',
      // followersCount: _getTotalCount(input['followers']),
      // followingCount: _getTotalCount(input['following']),
      repositoryCount: _getTotalCount(input['repositories']),
      pinnedItems:
          QLList.maybeFromJson(input['pinnedItems'], QLRepository.fromJson) ??
              const QLList(),
    );
  }
}

/// 标签
///
/// https://docs.github.com/zh/graphql/reference/objects#label
class QLLabel {
  const QLLabel({
    this.name = '',
    this.color = '',
    this.description = '',
    this.isDefault = false,
  });

  /// `String!`
  final String name;

  /// `String!`
  final String color;

  /// `String`
  final String description;

  /// `Boolean!`
  final bool isDefault;

  QLLabel.fromJson(Map<String, dynamic> input)
      : name = input['name'] ?? '',
        color = input['color'] ?? '',
        description = input['description'] ?? '',
        isDefault = input['isDefault'] ?? false;
}

/// Issues pullRequest Comment 基类
///
/// https://docs.github.com/zh/graphql/reference/objects#pullrequest
///
/// https://docs.github.com/zh/graphql/reference/objects#issue
///
/// https://docs.github.com/zh/graphql/reference/interfaces#comment
class QLIssueOrPullRequestOrCommentBase {
  const QLIssueOrPullRequestOrCommentBase({
    this.author,
    this.body = '',
    //this.bodyHTML,
    this.isMinimized = false,
    this.createdAt,
    this.editor,
    this.lastEditedAt,
    this.updatedAt,
  });

  /// `Actor` 创建的作者信息
  final QLActor? author;

  /// `String!` 内容
  final String body;

  //final String? bodyHTML;

  /// `Boolean!` Returns whether or not a comment has been minimized.
  final bool isMinimized;

  //Returns why the comment was minimized. One of abuse, off-topic, outdated, resolved, duplicate and spam. Note that the case and formatting of these values differs from the inputs to the MinimizeComment mutation.
  //final String minimizedReason

  /// `DateTime!` 创建时间
  final DateTime? createdAt;

  /// 编辑人的信息
  final QLActor? editor;

  /// 最后一次编辑时间
  final DateTime? lastEditedAt;

  /// `DateTime!` 更新的时间
  final DateTime? updatedAt;
}

/// Issues or PullRequest
///
/// https://docs.github.com/zh/graphql/reference/objects#pullrequest
///
/// https://docs.github.com/zh/graphql/reference/objects#issue
class QLIssueOrPullRequest extends QLIssueOrPullRequestOrCommentBase {
  const QLIssueOrPullRequest({
    super.author,
    super.body,
    //super.bodyHTML,
    super.isMinimized,
    super.createdAt,
    super.editor,
    super.lastEditedAt,
    super.updatedAt,
    this.number = -1,
    this.title = '',
    this.closedAt,
    this.labels = const QLList(),
    this.commentsCount = 0,
    this.locked = false,
    this.state = 'OPEN',
    this.viewerCanClose = false,
    this.viewerCanReopen = true,
  });

  /// `Int!` issue或者pullRequest的编号
  final int number;

  /// `String!` 标题
  final String title;

  /// 关闭时间
  final DateTime? closedAt;

  /// `LabelConnection` 标签列表
  final QLList<QLLabel> labels;

  // isAnswered (Boolean)

  /// `IssueCommentConnection!.Int!` 评论总数
  final int commentsCount;

  /// `Boolean!` 是否已锁定
  final bool locked;

  // final milestone;
  /// `IssueState!` or `PullRequestState!` 状态 取值 `OPEN` 和 `CLOSED`，如果QLPullRequest时可多取值`MERGED`
  final String state;

  /// 当前用户是否能关闭
  final bool viewerCanClose;

  /// 当前用户是否能重新打开
  final bool viewerCanReopen;

  /// 是否打开状态
  bool get isOpen => state == "OPEN";

  /// 是否已关闭
  bool get isClosed => state == "CLOSED";
}

/// issues颜色，实际是一个枚举值，这里使用类来包装
///
/// https://docs.github.com/zh/graphql/reference/enums#issuetypecolor
class QLIssueTypeColor {
  const QLIssueTypeColor([this.colorText = '']);

  static const qlIssueTypeColor = {
    'BLUE': mat.Colors.blue,
    'GRAY': mat.Colors.grey,
    'GREEN': mat.Colors.green,
    'ORANGE': mat.Colors.orange,
    'PINK': mat.Colors.pink,
    'PURPLE': mat.Colors.purple,
    'RED': mat.Colors.red,
    'YELLOW': mat.Colors.yellow,
  };

  final String colorText;

  /// 颜色
  mat.Color get color =>
      qlIssueTypeColor[colorText] ?? const mat.Color(0x00000000);
}

/// Issue类型
///
/// https://docs.github.com/zh/graphql/reference/objects#issuetype
class QLIssueType {
  const QLIssueType({
    this.color = const QLIssueTypeColor(),
    this.description = '',
    this.isEnabled = false,
    this.name = '',
  });

  /// `IssueTypeColor!` https://docs.github.com/zh/graphql/reference/enums#issuetypecolor
  final QLIssueTypeColor color;

  /// `String`
  final String description;

  /// `Boolean!`
  final bool isEnabled;

  //isPrivate is deprecated.
  // final bool isPrivate;
  /// `String!`
  final String name;

  QLIssueType.fromJson(Map<String, dynamic> input)
      : color = QLIssueTypeColor(input['color'] ?? ''),
        description = input['description'] ?? '',
        isEnabled = input['isEnabled'] ?? false,
        name = input['name'] ?? '';

  static QLIssueType? maybeFromJson(Map<String, dynamic>? input) =>
      input == null ? null : QLIssueType.fromJson(input);
}

/// issue
///
/// https://docs.github.com/zh/graphql/reference/objects#issue
class QLIssue extends QLIssueOrPullRequest {
  const QLIssue({
    super.number,
    super.author,
    super.title,
    super.body,
    //super.bodyHTML,
    super.isMinimized,
    super.closedAt,
    super.createdAt,
    super.editor,
    super.labels,
    super.lastEditedAt,
    super.commentsCount,
    super.locked,
    super.state,
    super.updatedAt,
    super.viewerCanClose,
    super.viewerCanReopen,
    this.issueType,
  });

  /// `IssueType
  final QLIssueType? issueType;

  QLIssue.fromJson(Map<String, dynamic> input)
      : issueType = QLIssueType.maybeFromJson(input['issueType']),
        super(
          number: input['number'] ?? 0,
          author: QLActor.maybeFromJson(input['author']),
          title: input['title'] ?? '',
          body: input['body'] ?? '',
          //bodyHTML: input['bodyHTML'],
          isMinimized: input['isMinimized'] ?? false,
          closedAt: _parseDateTime(input['closedAt']),
          createdAt: _parseDateTime(input['createdAt']),
          editor: QLActor.maybeFromJson(input['editor']),
          labels: QLList.maybeFromJson(input['labels'], QLLabel.fromJson) ??
              const QLList(),
          // labels: input['labels']?['nodes'] == null
          //     ? const []
          //     : List.from(input['labels']?['nodes'])
          //         .map((e) => QLLabel.fromJson(e))
          //         .toList(),
          lastEditedAt: _parseDateTime(input['lastEditedAt']),
          locked: input['locked'] ?? false,
          commentsCount: _getTotalCount(input['comments']),
          state: input['state'] ?? 'OPEN',
          updatedAt: _parseDateTime(input['updatedAt']),
          viewerCanClose: input['viewerCanClose'] ?? false,
          viewerCanReopen: input['viewerCanReopen'] ?? false,
        );
}

/// pullRequest
///
/// https://docs.github.com/zh/graphql/reference/objects#pullrequest
class QLPullRequest extends QLIssueOrPullRequest {
  const QLPullRequest({
    super.number,
    super.author,
    super.title,
    super.body,
    //super.bodyHTML,
    super.isMinimized,
    super.closedAt,
    super.createdAt,
    super.editor,
    super.labels,
    super.lastEditedAt,
    super.commentsCount,
    super.locked,
    super.state,
    super.updatedAt,
    super.viewerCanClose,
    super.viewerCanReopen,
    this.isDraft = false,
  });

  /// 是否已经合并
  bool get isMerged => state == 'MERGED';

  /// `Boolean!`
  final bool isDraft;

  // /// `Boolean!`
  // final bool isInMergeQueue;
  //
  // /// `Boolean!`
  // final bool isReadByViewer;
  //mergeStateStatus (MergeStateStatus!)
  //
  // Detailed information about the current pull request merge state status.
  //
  // mergeable (MergeableState!)
  //
  // Whether or not the pull request can be merged based on the existence of merge conflicts.
  //merged (Boolean!)
  //
  // Whether or not the pull request was merged.
  //
  // mergedAt (DateTime)
  //
  // The date and time that the pull request was merged.
  //
  // mergedBy (Actor)

  QLPullRequest.fromJson(Map<String, dynamic> input)
      : isDraft = input['isDraft'] ?? false,
        super(
          number: input['number'] ?? 0,
          author: QLActor.maybeFromJson(input['author']),
          title: input['title'] ?? '',
          body: input['body'] ?? '',
          //bodyHTML: input['bodyHTML'],
          isMinimized: input['isMinimized'] ?? false,
          closedAt: _parseDateTime(input['closedAt']),
          createdAt: _parseDateTime(input['createdAt']),
          editor: QLActor.maybeFromJson(input['editor']),
          labels: QLList.maybeFromJson(input['labels'], QLLabel.fromJson) ??
              const QLList(),
          // labels: input['labels']?['nodes'] == null
          //     ? const []
          //     : List.from(input['labels']?['nodes'])
          //         .map((e) => QLLabel.fromJson(e))
          //         .toList(),
          lastEditedAt: _parseDateTime(input['lastEditedAt']),
          locked: input['locked'] ?? false,
          state: input['state'],
          updatedAt: _parseDateTime(input['updatedAt']),
          viewerCanClose: input['viewerCanClose'] ?? false,
          viewerCanReopen: input['viewerCanReopen'] ?? false,
        );
}

/// 评论
///
/// https://docs.github.com/zh/graphql/reference/interfaces#comment
class QLComment extends QLIssueOrPullRequestOrCommentBase {
  const QLComment({
    super.author,
    super.body,
    //super.bodyHTML,
    super.createdAt,
    super.editor,
    super.lastEditedAt,
    this.publishedAt,
    super.updatedAt,
    this.url = '',
    this.viewerCanDelete = false,
    this.viewerCanUpdate = false,
    this.viewerDidAuthor = false,
  });

  final DateTime? publishedAt;
  final String url;
  final bool viewerCanDelete;
  final bool viewerCanUpdate;
  final bool viewerDidAuthor;

  QLComment.fromJson(Map<String, dynamic> input)
      : url = input['url'] ?? '',
        publishedAt = _parseDateTime(input['publishedAt']),
        viewerCanDelete = input['viewerCanDelete'] ?? false,
        viewerCanUpdate = input['viewerCanUpdate'] ?? false,
        viewerDidAuthor = input['viewerDidAuthor'] ?? false,
        super(
          author: QLActor.maybeFromJson(input['author']),
          body: input['body'] ?? '',
          //bodyHTML: input['bodyHTML'],
          createdAt: _parseDateTime(input['createdAt']),
          editor: QLActor.maybeFromJson(input['editor']),
          lastEditedAt: _parseDateTime(input['lastEditedAt']),
          updatedAt: _parseDateTime(input['updatedAt']),
        );
}

/// 子模块
///
/// https://docs.github.com/zh/graphql/reference/objects#submodule
class QLSubmodule {
  const QLSubmodule(
      {this.branch = '', this.gitUrl = '', this.name = '', this.path = ''});

  /// `String`
  final String branch;

  /// `URI!`
  final String gitUrl;

  /// `String!`
  final String name;

  /// `String!`
  final String path;
  QLSubmodule.fromJson(Map<String, dynamic> input)
      : branch = input['branch'] ?? '',
        name = input['name'] ?? '',
        path = input['path'] ?? '',
        gitUrl = input['gitUrl'] ?? '';
}

// class QLCommitHistory {
//   const QLCommitHistory();
//
//   QLCommitHistory.fromJson(Map<String, dynamic> input)
//       : branch = input['branch'] ?? '',
//         name = input['name'] ?? '',
//         path = input['path'] ?? '',
//         gitUrl = input['gitUrl'] ?? '';
// }

/// 提交记录
///
/// https://docs.github.com/zh/graphql/reference/objects#commit
class QLCommit {
  const QLCommit({
    this.oid = '',
    this.abbreviatedOid = '',
    this.additions = 0,
    this.author,
    this.authoredByCommitter = false,
    this.authoredDate,
    this.committedDate,
    this.changedFiles = 0,
    this.message = '',
    this.history = const QLList(),
    this.messageHeadline = '',
  });

  /// `GitObjectID!`
  final String oid;

  /// `String!`
  final String abbreviatedOid;

  /// `Int!`
  final int additions;

  /// `GitActor`
  final QLGitActor? author;

  /// `Boolean!`
  final bool authoredByCommitter;

  /// `DateTime!`
  final DateTime? authoredDate;

  // authors (GitActorConnection!)
// blame (Blame!)
  /// changedFiles (Int!)
  final int changedFiles;
// changedFilesIfAvailable (Int)
// comments (CommitCommentConnection!)
  /// committedDate (DateTime!)
  final DateTime? committedDate;
// committer (GitActor)
// deletions (Int!)
// file (TreeEntry)
  /// history (CommitHistoryConnection!)
  final QLList<QLCommit> history;

// id (ID!)
//
// The Node ID of the Commit object.
//
  /// message (String!)
  final String message;
//
// The Git commit message.
//
// messageBody (String!)
//
// The Git commit message body.
//
// messageBodyHTML (HTML!)
//
// The commit message body rendered to HTML.
//
  /// messageHeadline (String!)
  final String messageHeadline;
//
// The Git commit message headline.
//
// messageHeadlineHTML (HTML!)
//
// The commit message headline rendered to HTML.
//
// oid (GitObjectID!)
//
// The Git object ID.
//
// onBehalfOf (Organization)
//
// The organization this commit was made on behalf of.
//
// parents (CommitConnection!)
//
// The parents of a commit.
// repository (Repository!)
//
// The Repository this commit belongs to.
//
// resourcePath (URI!)
//
// The HTTP path for this commit.
//
// signature (GitSignature)
//
// Commit signing information, if present.
//
// status (Status)
//
// Status information for this commit.
//
// statusCheckRollup (StatusCheckRollup)
//
// Check and Status rollup information for this commit.
//
// submodules (SubmoduleConnection!)
//
// Returns a list of all submodules in this repository as of this Commit parsed from the .gitmodules file.
//tarballUrl (URI!)
//
// Returns a URL to download a tarball archive for a repository. Note: For private repositories, these links are temporary and expire after five minutes.
//
// tree (Tree!)
//
// Commit's root Tree.
//
// treeResourcePath (URI!)
//
// The HTTP path for the tree of this commit.
//
// treeUrl (URI!)
//
// The HTTP URL for the tree of this commit.
//
// url (URI!)
//
// The HTTP URL for this commit.
//
// viewerCanSubscribe (Boolean!)
//
// Check if the viewer is able to change their subscription status for the repository.
//
// viewerSubscription (SubscriptionState)
//
// Identifies if the viewer is watching, not watching, or ignoring the subscribable entity.
//
// zipballUrl (URI!)

  QLCommit.fromJson(Map<String, dynamic> json)
      : oid = json['oid'] ?? '',
        abbreviatedOid = json['abbreviatedOid'] ?? '',
        additions = json['additions'] ?? 0,
        changedFiles = json['changedFiles'] ?? 0,
        message = json['message'] ?? '',
        messageHeadline = json['messageHeadline'] ?? '',
        author = QLGitActor.maybeFromJson(json['author']),
        committedDate = _parseDateTime(json['committedDate']),
        authoredByCommitter = json['authoredByCommitter'] ?? false,
        authoredDate = _parseDateTime(json['authoredDate']),
        history = QLList.maybeFromJson(json['history'], QLCommit.fromJson) ??
            const QLList();
}

///==========GitObject 的实现方式
// Blob
// Commit
// Tag
// Tree

/// 内容信息
/// https://docs.github.com/zh/graphql/reference/objects#treeentry
class QLTreeEntry {
  const QLTreeEntry({
    //this.extension = '',
    //this.language = const QLLanguage(),
    this.isGenerated = false,
    //this.lineCount = 0,
    this.name = '',
    this.path = '',
    this.size = 0,
    this.type = '',
    this.submodule,
  });

  /// `String` 文件扩展名
  //final String extension;

  /// `Language` 本文件所用的编程语言
  //final QLLanguage language;

  /// `Boolean!` 是否已生成此树状条目
  final bool isGenerated;

  /// `Int` 文件行数
  //final int lineCount;

  /// `String!` 文件名
  final String name;

  /// Entry file name. (Base64-encoded).
  /// nameRaw

  /// `String` 文件路径
  final String path;

  /// The full path of the file. (Base64-encoded).
  /// pathRaw

  /// `Int!` 文件size
  final int size;

  /// `String!` 类型： `blob`=文件、`tree`=目录, `commit`=子模块
  final String type;

  /// `Submodule`
  final QLSubmodule? submodule;
  //
  // If the TreeEntry is for a directory occupied by a submodule project, this returns the corresponding submodule.

  /// 是否为文件
  bool get isFile => type == "blob";

  /// 是否为目录
  bool get isDir => type == "tree";

  /// 是否为子模块
  bool get isSubmodule => type == "commit";

  /// submodule (Submodule)
  ///
  /// If the TreeEntry is for a directory occupied by a submodule project, this returns the corresponding submodule.

  QLTreeEntry.fromJson(Map<String, dynamic> input)
      : //extension = input['extension'] ?? '',
        //language = input['language'] == null
        //    ? const QLLanguage()
        //    : QLLanguage.fromJson(input['language']),
        isGenerated = input['isGenerated'] ?? false,
        //lineCount = input['lineCount'] ?? 0,
        name = input['name'] ?? '',
        path = input['path'] ?? '',
        size = input['size'] ?? 0,
        type = input['type'] ?? '',
        submodule = input['submodule'] == null
            ? null
            : QLSubmodule.fromJson(input['submodule']);
}

/// 内容树，包含目录和文件列表
///
/// https://docs.github.com/zh/graphql/reference/objects#tree
class QLTree {
  const QLTree({this.entries = const []});

  /// `entries ([TreeEntry!])` 目录
  final List<QLTreeEntry> entries;

  QLTree.fromJson(Map<String, dynamic> input)
      : entries = input['entries'] == null
            ? const []
            : List.from(input['entries'])
                .map((e) => QLTreeEntry.fromJson(e))
                .toList();
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

  /// `GitObjectID!` Git 对象 ID
  final String oid;

  /// `Int!` Blob 对象的字节大小
  final int byteSize;

  /// `Boolean` 指示 Blob 是二进制数据还是文本数据。如果无法确定编码方式，则返回 null
  final bool isBinary;

  /// `Boolean!` 指示内容是否被截断
  final bool isTruncated;

  /// `String` 如果`binary=true`则为`null`，否则为一个UTF8文本数据
  final String? text;

  QLBlob.fromJson(Map<String, dynamic> input)
      : oid = input['oid'] ?? '',
        byteSize = input['byteSize'] ?? 0,
        isBinary = input['isBinary'] ?? false,
        isTruncated = input['isTruncated'] ?? false,
        text = input['text'];
}

/// 仓库目录或者文件
///
/// https://docs.github.com/zh/graphql/reference/interfaces#gitobject
class QLGitObject {
  const QLGitObject({
    this.tree,
    this.blob,
    this.commit,
    this.typeName = '',
  });

  /// 类型名，对应字段 `__typename`
  final String typeName;

  /// 目录
  final QLTree? tree;

  /// 文件内容
  final QLBlob? blob;

  /// git提交记录
  final QLCommit? commit;

  /// 是否为目录
  bool get isDir => typeName == 'Tree';

  /// 是否为文件
  bool get isFile => typeName == 'Blob';

  /// 是否为提交记录
  bool get isCommit => typeName == 'Commit';

  // Tree

  static bool _isType(Map<String, dynamic> json, String type) =>
      json['__typename'] == type;

  QLGitObject.fromJson(Map<String, dynamic> input)
      : typeName = input['__typename'] ?? '',
        blob = !_isType(input, 'Blob') ? null : QLBlob.fromJson(input),
        tree = !_isType(input, 'Tree') ? null : QLTree.fromJson(input),
        commit = !_isType(input, 'Commit') ? null : QLCommit.fromJson(input);

  static QLGitObject? maybeFromJson(Map<String, dynamic>? input) =>
      input == null ? null : QLGitObject.fromJson(input);

  /// 返回一个错误
  QLGitObject.error(Object? err)
      : tree = null,
        commit = null,
        typeName = '',
        blob = QLBlob(byteSize: 1, isBinary: false, text: '$err', oid: '');
}

/// Represents an actor in a Git commit (ie. an author or committer).
///
/// https://docs.github.com/zh/graphql/reference/objects#gitactor
///
class QLGitActor {
  const QLGitActor({
    required this.avatarUrl,
    this.date,
    this.email = '',
    this.name = '',
    this.user,
  });

  /// `URI!` A URL pointing to the author's public avatar.
  final String avatarUrl;

  /// The timestamp of the Git action (authoring or committing).
  ///
  /// `GitTimestamp`
  /// An ISO-8601 encoded date string. Unlike the DateTime type, GitTimestamp is not converted in UTC.
  final DateTime? date;

  /// `String` The email in the Git commit.
  final String email;

  /// `String` The name in the Git commit.
  final String name;

  /// `User` The GitHub user corresponding to the email field. Null if no such user exists.
  final QLUser? user;

  QLGitActor.fromJson(Map<String, dynamic> json)
      : avatarUrl = json['avatarUrl'] ?? '',
        date = _parseDateTime(json['date']),
        email = json['email'] ?? '',
        name = json['name'] ?? '',
        user = QLUser.maybeFromJson(json['user']);

  static QLGitActor? maybeFromJson(Map<String, dynamic>? json) =>
      json == null ? null : QLGitActor.fromJson(json);
}

/// https://docs.github.com/zh/graphql/reference/objects#topic
class QLTopic {
  const QLTopic({required this.name});
  final String name;

  // int stargazerCount
  // bool viewerHasStarred

  QLTopic.fromJson(Map<String, dynamic> json) : name = json['name'] ?? '';
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

typedef JSONConverter<T> = T Function(Map<String, dynamic>);

/// 异常类型
///
/// ```json
/// {
///   "message":"Problems parsing JSON",
///   "documentation_url":"https://docs.github.com/graphql",
///   "status":"400"
/// }
///```
/// 实际为422错误，但没有哈
///
/// ```json
///{
/// 	"errors": [
/// 		{
/// 			"path": [
/// 				"query",
/// 				"DSD"
/// 			],
/// 			"extensions": {
/// 				"code": "undefinedField",
/// 				"typeName": "Query",
/// 				"fieldName": "DSD"
/// 			},
/// 			"locations": [
/// 				{
/// 					"line": 11,
/// 					"column": 4
/// 				}
/// 			],
/// 			"message": "Field 'DSD' doesn't exist on type 'Query'"
/// 		}
/// 	]
/// }
/// ```
class GitHubGraphQLError {
  const GitHubGraphQLError(this.message, {required this.statusCode});

  /// 错误消息
  final dynamic message;

  /// 状态码
  final int statusCode;

  @override
  String toString() => message == null
      ? ''
      : (message is String ? message as String : jsonEncode(message));

  bool get isBadCredentials =>
      (message is String && message == 'Bad credentials') || statusCode == 401;
}

/// 代码提取自 github-9.24.0\lib\src\common\github.dart - GitHub类。
///
/// 问：为什么要提取而不自己写？
///
/// 因为我也没研究过他这个东西，目前以实现为主，后面再有想法时研究下。
class GitHubRateLimit {
  GitHubRateLimit();

  static const _ratelimitLimitHeader = 'x-ratelimit-limit';
  static const _ratelimitResetHeader = 'x-ratelimit-reset';
  static const _ratelimitRemainingHeader = 'x-ratelimit-remaining';

  int? get rateLimitLimit => _rateLimitLimit;

  int? get rateLimitRemaining => _rateLimitRemaining;

  DateTime? get rateLimitReset => _rateLimitReset == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_rateLimitReset! * 1000,
          isUtc: true);
  int? _rateLimitReset, _rateLimitLimit, _rateLimitRemaining;

  /// 更新
  void updateRateLimit(Map<String, String> headers) {
    if (headers.containsKey(_ratelimitLimitHeader)) {
      _rateLimitLimit = int.parse(headers[_ratelimitLimitHeader]!);
      _rateLimitRemaining = int.parse(headers[_ratelimitRemainingHeader]!);
      _rateLimitReset = int.parse(headers[_ratelimitResetHeader]!);
    }
  }

  /// 等待，如果有的话
  Future<void> wait() async {
    if (rateLimitRemaining != null && rateLimitRemaining! <= 0) {
      assert(rateLimitReset != null);
      final now = DateTime.now();
      final waitTime = rateLimitReset!.difference(now);
      if (kDebugMode) {
        print('遇到服务器请求频率限制，需要等待${waitTime.inMilliseconds}ms后继续');
      }
      return Future.delayed(waitTime);
    }
  }
}

/// 认证类型
enum AuthType {
  anonymous,
  accessToken,
  oauth2,
}

/// 认证方式
class Authorization {
  const Authorization({required this.type, this.token});

  final AuthType type;
  final String? token;

  const Authorization.anonymous()
      : type = AuthType.anonymous,
        token = null;

  const Authorization.withOAuth2Token(this.token) : type = AuthType.oauth2;

  const Authorization.withBearerToken(this.token) : type = AuthType.accessToken;
}

class GitHubGraphQL {
  GitHubGraphQL({
    this.auth = const Authorization.anonymous(),
  });

  /// graphql API地址
  static const graphqlApiUrl = 'https://api.github.com/graphql';

  /// 认证信息
  Authorization auth;

  /// http客户端
  final http.Client _client = http.Client();

  /// 缓存
  final HTTPCache _cache = HTTPCache();

  /// 是否使用匿名方式
  bool get isAnonymous => auth.type == AuthType.anonymous;

  /// 速率限制
  final GitHubRateLimit _rateLimit = GitHubRateLimit();

  /// 一个查询
  /// ```json
  /// query{ viewer { login name } }
  /// ```
  Future<T> query<S, T>(
    QLQuery query, {
    Map<String, String>? headers,
    JSONConverter<T>? convert,
    bool? force,
    ValueChanged<Map<String, dynamic>>? secondUpdateCallback,
  }) =>
      _request(query,
          headers: headers,
          convert: convert,
          force: force,
          secondUpdateCallback: secondUpdateCallback);

  //  "Content-Type: application/json",
  //   "Accept: application/vnd.github.v4.idl"

  /// 修改操作
  Future<T> mutation<S, T>(
    QLQuery query, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    JSONConverter<T>? convert,
  }) async =>
      // 对于基变，不能缓存数据
      _request(query, headers: headers, convert: convert, force: true);

  /// 忽略path字段，强制为[endpoint]，本可不这样做的，但是他内部的[request]方法在判断[path]时
  /// 附加了一个”/“符号，造成服务端识为这是一个rest API。
  /// 暂时不公开，之后再看吧
  /// Accept: application/vnd.github+json.
  Future<T> _request<T>(
    QLQuery query, {
    Map<String, String>? headers,
    JSONConverter<T>? convert,
    bool? force,
    ValueChanged<Map<String, dynamic>>? secondUpdateCallback,
  }) async {
    final queryBody = query.jsonText;

    // 默认的
    var needUpdate = true;
    var needWait = true;
    Map<String, dynamic>? data = {};
    var key = '';
    // 是否需要强制更新
    if (!(force ?? false)) {
      key = _cache.genKey("POST:$graphqlApiUrl:$queryBody");
      // 不管缓存过不过期都读取，后面再根据缓存是否过期去操作
      //TODO: 这里暂时修改下逻辑吧，启动时不从文件缓存加载，必须要更新
      //data = !_cache.isCached(key) ? null : await _cache.readCachedFile(key);
      data = await _cache.readCachedFile(key);
      // 是否需要更新缓存
      needUpdate = data == null; // 数据为null则没有本地缓存
      needWait = data == null; // 是否需要等待
      if (data != null && data.isNotEmpty) {
        // 本次是否已经更新过缓存了
        if (!_cache.isCached(key)) {
          needUpdate = true;
        }
      }
    }

    // 是否需要更新
    if (needUpdate) {
      //print("需要更新");
      if (needWait) {
        data =
            await _doRequest(cachedKey: key, body: queryBody, headers: headers);
      } else {
        //TODO: 这里还要弄下，完成后通知更新
        _doRequest(cachedKey: key, body: queryBody, headers: headers)
            .then((data) {
          if (secondUpdateCallback != null && data['data'] != null) {
            secondUpdateCallback.call(data['data']);
          }
        });
      }
    } else {
      //print("正在使用缓存");
    }

    /// 取数据段
    data = data?['data'];
    if (data == null) return null as T;
    // 实际数据节点
    if (convert == null) {
      return data as T;
    }
    return convert(data);
  }

  Future<Map<String, dynamic>> _doRequest({
    required String cachedKey,
    required String body,
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) {
      //print("body: body");
    }
    await _rateLimit.wait();
    headers ??= <String, String>{};
    // ????用这个，还是？，好像也不一定要设置哈
    //headers['Accept'] = 'application/vnd.github+json';
    headers['Accept'] = 'application/json';
    headers['Content-Type'] = 'application/json';

    // 设置认证方式
    if (auth.type != AuthType.anonymous && (auth.token?.isNotEmpty ?? false)) {
      headers.putIfAbsent(
          'Authorization',
          () => switch (auth.type) {
                AuthType.accessToken => 'Bearer ${auth.token}',
                AuthType.oauth2 => 'token ${auth.token}',
                _ => ''
              });
    }

    // user-Agent
    headers.putIfAbsent('User-Agent', () => 'GitHub PC/1.0.0');
    // 新建一个请求
    final req = http.Request('POST', Uri.parse(graphqlApiUrl));
    // 添加http头
    req.headers.addAll(headers);
    // 设置body数据
    req.body = body;
    // 等待结果
    final resp = await http.Response.fromStream(await _client.send(req));
    _rateLimit.updateRateLimit(resp.headers);
    // 解码json
    final json = jsonDecode(resp.body);
    // 有错误
    // {"message":"Problems parsing JSON","documentation_url":"https://docs.github.com/graphql","status":"400"}
    if (json['message'] != null) {
      throw GitHubGraphQLError(json['message'],
          statusCode: int.tryParse("${json['status']}") ?? resp.statusCode);
    }
    // 实际为422错误，但没有哈
    // {"errors":[{"path":["query","DSD"],"extensions":{"code":"undefinedField","typeName":"Query","fieldName":"DSD"},"locations":[{"line":11,"column":4}],"message":"Field 'DSD' doesn't exist on type 'Query'"}]}
    // 按理说应该状态码返回422，但实际返回了200状态码，但没返回的原因是啥？？？？
    if (json['errors'] != null) {
      throw GitHubGraphQLError(json, statusCode: 422);
    }
    // 不为200的，直接返回状态码和状态码描述
    if (resp.statusCode != 200) {
      throw GitHubGraphQLError(resp.reasonPhrase ?? 'unknown Error',
          statusCode: resp.statusCode);
    }
    // 写缓存数据
    if (cachedKey.isNotEmpty && cachedKey.length == 32) {
      _cache.writeFileCache(cachedKey, resp.bodyBytes);
    }
    // 200的时候才写数据
    return json;
  }
}
