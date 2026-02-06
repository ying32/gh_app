import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:gh_app/utils/utils.dart';
import 'package:http/http.dart' as http;

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

  //void clear() => _data.clear();

  QLList.fromJson(
      Map<String, dynamic> input, T Function(Map<String, dynamic>) convert,
      {this.pageSize = 0, String? totalCountAlias})
      : _data = input['nodes'] == null
            ? []
            : List.from(input['nodes'] as List).map((e) => convert(e)).toList(),
        totalCount = input[totalCountAlias ?? 'totalCount'] ?? 0,
        pageInfo = input['pageInfo'] == null
            ? null
            : QLPageInfo.fromJson(input['pageInfo']);

  /// 空数据
  const QLList.empty()
      : _data = const [],
        totalCount = 0,
        pageSize = 0,
        pageInfo = null;
}

/// 仓库的主语言
///
/// https://docs.github.com/zh/graphql/reference/objects#language
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

/// 用户信息基础类，包含用户和组织等
///
/// https://docs.github.com/zh/graphql/reference/interfaces#actor
class QLActor {
  const QLActor({
    required this.login,
    this.avatarUrl = '',
    this.url = '',
  });

  /// The username of the actor.
  final String login;

  /// A URL pointing to the actor's public avatar.
  final String avatarUrl;

  /// 用户或者组织的html url
  /// 链接地址，比如 https://github.com/{user-name}
  final String url;

  QLActor.fromJson(Map<String, dynamic> input)
      : url = input['url'] ?? '',
        login = input['login'] ?? '',
        avatarUrl = input['avatarUrl'] ?? '';
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
}

/// 许可协议
///
/// https://docs.github.com/zh/graphql/reference/objects#license
class QLLicense {
  const QLLicense({this.name = ''});

  /// 许可协议名
  final String name;

  QLLicense.fromJson(Map<String, dynamic> json) : name = json['name'] ?? '';
}

DateTime? _parseDateTime(String? value) =>
    value == null ? null : DateTime.parse(value);

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
  ///final List<QLReleaseAsset>? assets;

  /// 附件总数，这里不再查询全部的了
  final int assetsCount;

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
        assetsCount = input['releaseAssets']?['totalCount'] ?? 0;
// assets = input['releaseAssets']?['nodes'] == null
//     ? null
//     : List.from(input['releaseAssets']?['nodes'])
//         .map((e) => QLReleaseAsset.fromJson(e))
//         .toList();
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
  });

  /// 分支或者tag名
  final String name;

  /// The ref's prefix, such as refs/heads/ or refs/tags/.
  final String prefix;

  QLRef.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? 'HEAD',
        prefix = json['prefix'] ?? 'refs/heads/';
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
    this.owner,
    this.parent,
    this.forksCount = 0,
    this.stargazersCount = 0,
    this.isPrivate = false,
    this.description = '',
    this.isArchived = false,
    this.updatedAt,
    this.pushedAt,
    this.url = '',
    this.openIssuesCount = 0,
    this.licenseInfo,
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
    this.permission,
    this.viewerSubscription,
    this.releasesCount = 0,
    this.latestRelease,
    this.refsCount = 0,
    this.tagsCount = 0,
  });

  /// 仓库名
  final String name;

  /// 仓库所有者
  final QLRepositoryOwner? owner;

  /// 父仓库，一般为fork来的
  final QLRepository? parent;

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
  final QLLicense? licenseInfo;

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

  /// 当前查看者权限
  final QLRepositoryPermission? permission;

  /// 当前查看者定阅状态
  final QLSubscriptionState? viewerSubscription;

  /// Release总数量
  final int releasesCount;

  /// 最后一次发布的信息
  final QLRelease? latestRelease;

  /// 分支总数
  final int refsCount;

  /// tags总数
  final int tagsCount;

  /// 仓库全名：${owner.login}/$name
  String get fullName => "${owner?.login}/$name";

  /// 当前查看用户是否已订阅，也就是watch
  bool get viewerHasSubscribed =>
      viewerSubscription == QLSubscriptionState.subscribed;

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
      openPullRequestsCount: input['pullRequests']?['totalCount'] ?? 0,
      watchersCount: input['watchers']?['totalCount'] ?? 0,
      mirrorUrl: input['mirrorUrl'] ?? '',
      defaultBranchRef: input['defaultBranchRef'] == null
          ? const QLRef()
          : QLRef.fromJson(input['defaultBranchRef']),
      releasesCount: input['releases']?['totalCount'] ?? 0,
      refsCount: input['refs']?['totalCount'] ?? 0,
      tagsCount: input['tags']?['totalCount'] ?? 0,
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
      licenseInfo: input['licenseInfo'] == null
          ? null
          : QLLicense.fromJson(input['licenseInfo']),
      topics: input['repositoryTopics']?['nodes'] == null
          ? null
          : List.of(input['repositoryTopics']?['nodes'])
              .map((e) => "${e['topic']?['name'] ?? ''}")
              .toList(),
      parent: input['parent'] == null
          ? null
          : QLRepository.fromJson(input['parent']),
    );
  }
}

/// 组织用户
///
/// 不要那么多东西，所以合并到QLUser上面
///
/// https://docs.github.com/zh/graphql/reference/objects#organization
typedef QLOrganization = QLUser;

///
// class QLOrganization extends QLUser {
//   const QLOrganization({
//     required super.login,
//   });
//
//   factory QLOrganization.fromJson(Map<String, dynamic> input) {
//     input = input['viewer'] ?? input['organization'] ?? input;
//     return QLOrganization(
//       login: input['login'] ?? '',
//       // name: input['name'] ?? '',
//       // avatarUrl: input['avatarUrl'] ?? '',
//       // company: input['company'] ?? '',
//       // bio: input['bio'] ?? '',
//       // email: input['email'] ?? '',
//       // location: input['location'] ?? '',
//       // twitterUsername: input['twitterUsername'] ?? '',
//       // url: input['url'] ?? '',
//       // websiteUrl: input['websiteUrl'] ?? '',
//       // followersCount: input['followers']?['totalCount'] ?? 0,
//       // followingCount: input['following']?['totalCount'] ?? 0,
//       // pinnedItems: input['pinnedItems']?['nodes'] != null
//       //     ? List.of(input['pinnedItems']?['nodes'])
//       //     .map((e) => QLRepository.fromJson(e))
//       //     .toList()
//       //     : null,
//     );
//   }
// }

/// 用户状态
///
/// https://docs.github.com/zh/graphql/reference/objects#userstatus
class QLUserStatus {
  const QLUserStatus({this.emoji = '', this.emojiHTML = '', this.message = ''});

  final String emoji;
  final String emojiHTML;
  final String message;

  QLUserStatus.fromJson(Map<String, dynamic> input)
      : emoji = input['emoji'] ?? '',
        emojiHTML = input['emojiHTML'] ?? '',
        message = input['message'] ?? '';
}

/// 个人用户
///
/// https://docs.github.com/zh/graphql/reference/objects#user
class QLUser extends QLActor {
  const QLUser({
    required super.login,
    super.avatarUrl,
    super.url,
    this.isViewer = false,
    this.name = '',
    this.company = '',
    this.websiteUrl = '',
    this.location = '',
    this.email = '',
    this.bio = '',
    this.status = const QLUserStatus(),
    this.followersCount = 0,
    this.followingCount = 0,
    this.twitterUsername = '',
    this.pinnedItems,
  });

  /// 是否登录的用户
  final bool isViewer;

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

  /// 用户状态
  final QLUserStatus status;

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
      status: input['status'] == null
          ? const QLUserStatus()
          : QLUserStatus.fromJson(input['status']),
      email: input['email'] ?? '',
      location: input['location'] ?? '',
      twitterUsername: input['twitterUsername'] ?? '',
      url: input['url'] ?? '',
      isViewer: input['isViewer'] ?? false,
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

  final String name;
  final String color;
  final String description;
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

  /// 创建的作者信息
  final QLActor? author;

  /// 内容
  final String body;

  //final String? bodyHTML;

  /// Returns whether or not a comment has been minimized.
  final bool isMinimized;

  //Returns why the comment was minimized. One of abuse, off-topic, outdated, resolved, duplicate and spam. Note that the case and formatting of these values differs from the inputs to the MinimizeComment mutation.
  //final String minimizedReason

  /// 创建时间
  final DateTime? createdAt;

  /// 编辑人的信息
  final QLActor? editor;

  /// 最后一次编辑时间
  final DateTime? lastEditedAt;

  /// 更新的时间
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
    this.labels = const [],
    this.commentsCount = 0,
    this.locked = false,
    this.state,
    this.viewerCanClose = false,
    this.viewerCanReopen = true,
  });

  /// issue或者pullRequest的编号
  final int number;

  /// 标题
  final String title;

  /// 关闭时间
  final DateTime? closedAt;

  /// 标签列表
  final List<QLLabel> labels;

  /// 评论总数
  final int commentsCount;

  /// 是否已锁定
  final bool locked;

  // final milestone;
  /// 状态 取值 `OPEN` 和 `CLOSED`，如果QLPullRequest时可多取值`MERGED`
  final String? state;

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

  /// https://docs.github.com/zh/graphql/reference/enums#issuetypecolor
  final QLIssueTypeColor color;
  final String description;
  final bool isEnabled;

  //isPrivate is deprecated.
  // final bool isPrivate;
  final String name;

  QLIssueType.fromJson(Map<String, dynamic> input)
      : color = QLIssueTypeColor(input['color'] ?? ''),
        description = input['description'] ?? '',
        isEnabled = input['isEnabled'] ?? false,
        name = input['name'] ?? '';
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

  final QLIssueType? issueType;

  QLIssue.fromJson(Map<String, dynamic> input)
      : issueType = input['issueType'] == null
            ? null
            : QLIssueType.fromJson(input['issueType']),
        super(
          number: input['number'] ?? 0,
          author: input['author'] == null
              ? null
              : QLActor.fromJson(input['author']),
          title: input['title'] ?? '',
          body: input['body'] ?? '',
          //bodyHTML: input['bodyHTML'],
          isMinimized: input['isMinimized'] ?? false,
          closedAt: _parseDateTime(input['closedAt']),
          createdAt: _parseDateTime(input['createdAt']),
          editor: input['editor'] == null
              ? null
              : QLActor.fromJson(input['editor']),
          labels: input['labels']?['nodes'] == null
              ? const []
              : List.from(input['labels']?['nodes'])
                  .map((e) => QLLabel.fromJson(e))
                  .toList(),
          lastEditedAt: _parseDateTime(input['lastEditedAt']),
          locked: input['locked'] ?? false,
          commentsCount: input['comments']?['totalCount'] ?? 0,
          state: input['state'],
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
  });

  /// 是否已经合并
  bool get isMerged => state == 'MERGED';

  QLPullRequest.fromJson(Map<String, dynamic> input)
      : super(
          number: input['number'] ?? 0,
          author: input['author'] == null
              ? null
              : QLActor.fromJson(input['author']),
          title: input['title'] ?? '',
          body: input['body'] ?? '',
          //bodyHTML: input['bodyHTML'],
          isMinimized: input['isMinimized'] ?? false,
          closedAt: _parseDateTime(input['closedAt']),
          createdAt: _parseDateTime(input['createdAt']),
          editor: input['editor'] == null
              ? null
              : QLActor.fromJson(input['editor']),
          labels: input['labels']?['nodes'] == null
              ? const []
              : List.from(input['labels']?['nodes'])
                  .map((e) => QLLabel.fromJson(e))
                  .toList(),
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
          author: input['author'] == null
              ? null
              : QLActor.fromJson(input['author']),
          body: input['body'] ?? '',
          //bodyHTML: input['bodyHTML'],
          createdAt: _parseDateTime(input['createdAt']),
          editor: input['editor'] == null
              ? null
              : QLActor.fromJson(input['editor']),
          lastEditedAt: _parseDateTime(input['lastEditedAt']),
          updatedAt: _parseDateTime(input['updatedAt']),
        );
}

///==========GitObject 的实现方式
// Blob
// Commit
// Tag
// Tree

/// 内容树，包含目录和文件列表
///
/// https://docs.github.com/zh/graphql/reference/objects#tree
class QLTree {
  const QLTree({
    //this.extension = '',
    //this.language = const QLLanguage(),
    this.isGenerated = false,
    //this.lineCount = 0,
    this.name = '',
    this.path = '',
    this.size = 0,
    this.type = '',
  });

  /// 文件扩展名
  //final String extension;

  /// 本文件所用的编程语言
  //final QLLanguage language;

  /// 是否已生成此树状条目
  final bool isGenerated;

  /// 文件行数
  //final int lineCount;

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

  /// 是否为文件
  bool get isFile => type == "blob";

  /// 是否为目录
  bool get isDir => type == "tree";

  /// submodule (Submodule)
  ///
  /// If the TreeEntry is for a directory occupied by a submodule project, this returns the corresponding submodule.

  QLTree.fromJson(Map<String, dynamic> input)
      : //extension = input['extension'] ?? '',
        //language = input['language'] == null
        //    ? const QLLanguage()
        //    : QLLanguage.fromJson(input['language']),
        isGenerated = input['isGenerated'] ?? false,
        //lineCount = input['lineCount'] ?? 0,
        name = input['name'] ?? '',
        path = input['path'] ?? '',
        size = input['size'] ?? 0,
        type = input['type'] ?? '';
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
class QLObject {
  const QLObject({
    this.entries,
    this.blob,
  }) : _hasEntries = false;

  /// 目录
  final List<QLTree>? entries;

  /// 文件内容
  final QLBlob? blob;

  /// 通过查询是否有`entries`节点来判断
  final bool _hasEntries;

  /// 是否为目录
  bool get isDir => _hasEntries;

  /// 是否为文件
  bool get isFile => !_hasEntries;

  QLObject.fromJson(Map<String, dynamic> input)
      : _hasEntries = input['entries'] != null,
        blob = input['entries'] != null ? null : QLBlob.fromJson(input),
        entries = input['entries'] == null
            ? null
            : List.from(input['entries'])
                .map((e) => QLTree.fromJson(e))
                .toList();

  /// 返回一个错误
  QLObject.error(Object? err)
      : entries = null,
        _hasEntries = false,
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

  /// A URL pointing to the author's public avatar.
  final String avatarUrl;

  /// The timestamp of the Git action (authoring or committing).
  ///
  /// GitTimestamp
  /// An ISO-8601 encoded date string. Unlike the DateTime type, GitTimestamp is not converted in UTC.
  final DateTime? date;

  /// The email in the Git commit.
  final String email;

  /// The name in the Git commit.
  final String name;

  /// The GitHub user corresponding to the email field. Null if no such user exists.
  final QLUser? user;
}

/// https://docs.github.com/zh/graphql/reference/objects#topic
class QLTopic {
  const QLTopic({required this.name});
  final String name;

  // int stargazerCount
  // bool viewerHasStarred
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
  final Map<String, dynamic>? variables;

  /// 这个我也不知道干啥的（难道是有多个ql语句指定操作哪个的？？？，没研究过）
  final String? operationName;
  final bool isQuery;

  /// 编码后的graphql
  String get jsonText => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        //TODO: mutation 是不是这样操作呢？还没测试过，到时候测试了再说吧
        //"query": isQuery ? "query {\n $body \n}" : "mutation {\rn $body \n}",
        "query": body,
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

typedef JSONConverter<T> = T Function(Map<String, dynamic>);

class GitHubGraphQLError {
  const GitHubGraphQLError(this.error);

  final Map<String, dynamic> error;

  @override
  String toString() => jsonEncode(error);

  bool get isBadCredentials =>
      error['message'] == 'Bad credentials' || error['status'] == 401;
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
      await Future.delayed(waitTime);
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
    // 都没必要判断状态码了，反正他有没有错误在某些情况下都返回200。
    // if (response.statusCode != 200) {}
    final json = jsonDecode(resp.body);
    // 有错误，这个错误在定义了[statusCode]时会解析
    // {"message":"Problems parsing JSON","documentation_url":"https://docs.github.com/graphql","status":"400"}
    // 实际为422错误，但没有哈
    // {"errors":[{"path":["query","DSD"],"extensions":{"code":"undefinedField","typeName":"Query","fieldName":"DSD"},"locations":[{"line":11,"column":4}],"message":"Field 'DSD' doesn't exist on type 'Query'"}]}
    // 这个错误貌似依然返回200？
    if (json['errors'] != null ||
        (resp.statusCode != 200 && json['message'] != null)) {
      // 按理说应该状态码返回422，但没返回的原因是啥？？？？
      throw GitHubGraphQLError(json); //懒得处理了，直接整个错误得了
    }
    // 不为200的，直接返回状态码和状态码描述
    if (resp.statusCode != 200) {
      throw GitHubGraphQLError(
          {"code": resp.statusCode, "message": resp.reasonPhrase});
    }
    // 写缓存数据
    if (cachedKey.isNotEmpty && cachedKey.length == 32) {
      _cache.writeFileCache(cachedKey, resp.bodyBytes);
    }
    // 200的时候才写数据
    return json;
  }
}
