import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/pages/repos.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:markdown/markdown.dart' as mk;
import 'package:url_launcher/url_launcher.dart';

/// 用户头像
class UserHeadImage extends StatelessWidget {
  const UserHeadImage(
    this.avatarUrl, {
    super.key,
    this.imageSize = 64,
    this.tooltip,
    this.onPressed,
  });

  final String? avatarUrl;
  final double imageSize;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null) {
      return const SizedBox.shrink();
    }
    Widget child = ClipOval(
      child: Container(
        color: Colors.black.withOpacity(0.08),
        child: CachedNetworkImageEx(
          avatarUrl!,
          fit: BoxFit.cover,
          width: imageSize,
          height: imageSize,
          errorWidget: DefaultIcon.github(size: imageSize),
        ),
      ),
    );
    if (onPressed != null) {
      // child = LinkButton(onPressed: onPressed, text: child);
      child = MaterialStyleButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(imageSize / 2),
        child: child,
      );
    }
    if (tooltip != null) {
      child = Tooltip(message: tooltip, child: child);
    }
    return child;
  }
}

class ActorHeadImage extends UserHeadImage {
  ActorHeadImage(
    this.user, {
    super.key,
    super.imageSize,
    super.tooltip,
    super.onPressed,
  }) : super(user?.avatarUrl);

  final QLActor? user;
}

class GitActorHeadImage extends UserHeadImage {
  GitActorHeadImage(
    this.user, {
    super.key,
    super.imageSize,
    super.tooltip,
    super.onPressed,
  }) : super(user?.avatarUrl);

  final QLGitActor? user;
}

/// 用户名
class UserNameWidget extends StatelessWidget {
  const UserNameWidget(
    this.user, {
    super.key,
    this.onlyNickName = false,
  });

  final QLUserOrOrganizationCommon user;
  final bool onlyNickName;

  String get _displayName {
    final nickName = user.name.isEmpty ? user.login : user.name;
    if (onlyNickName) return nickName;
    if (nickName == "" || nickName == user.login) {
      return user.login;
    }
    return "${user.login}${"($nickName)"}";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayName,
      style:
          TextStyle(fontWeight: FontWeight.w500, color: context.textColor200),
    );
  }
}

class UserLineInfo extends StatelessWidget {
  const UserLineInfo({
    super.key,
    required this.icon,
    required this.value,
    this.isLink = false,
    this.isEmail = false,
    this.textColor,
  });

  final IconData? icon;
  final dynamic value;
  final bool isLink;
  final bool isEmail;
  final Color? textColor;

  Widget _buildLinkIf(Widget child) => isLink && value is String
      ? LinkButton(
          onPressed: () {
            launchUrl(Uri.parse(isEmail ? "mailto:$value" : value));
          },
          text: child,
          padding: EdgeInsets.zero,
        )
      : child;

  @override
  Widget build(BuildContext context) {
    if (value == null || (value is String && (value as String).isEmpty)) {
      return const SizedBox.shrink();
    }

    late Widget child;
    if (value is Widget) {
      if (icon == null) {
        child = _buildLinkIf(value);
      } else {
        child = IconText(icon: icon!, text: _buildLinkIf(value));
      }
    } else {
      Widget child2 = Text("$value", style: TextStyle(color: textColor));
      if (icon == null) {
        child = child2;
      } else {
        child = IconText(
            icon: icon!, text: _buildLinkIf(child2), iconColor: textColor);
      }
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), child: child);
  }
}

class UserLineDiskUseInfo extends StatelessWidget {
  const UserLineDiskUseInfo({
    super.key,
    required this.value,
  });

  final int? value;

  @override
  Widget build(BuildContext context) {
    return UserLineInfo(
      icon: DefaultIcons.drive,
      value: (value ?? 0).toSizeString(),
    );
  }
}

class UserInfoPanel extends StatelessWidget {
  const UserInfoPanel(
    this.user, {
    super.key,
  });

  final QLUserOrOrganizationCommon user;

  QLUser get _user => user as QLUser;
  QLOrganization get _org => user as QLOrganization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像和名字
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              ActorHeadImage(user, imageSize: 60),
              const SizedBox(width: 10.0),
              Expanded(child: SelectionArea(child: UserNameWidget(user))),
            ],
          ),
        ),
        if (user is QLUser) ...[
          // 签名信息
          SelectableText(_user.bio,
              style: TextStyle(color: context.textColor200)),
          // SelectionArea(
          //     child: UserLineInfo(
          //         icon: null,
          //         value: _user.bio,
          //         textColor: context.textColor200)),
          const SizedBox(height: 8),
          // 心情
          if (_user.status != null &&
              (_user.status!.emojiHTML.isNotEmpty ||
                  _user.status!.message.isNotEmpty))
            SelectableText.rich(
                TextSpan(text: mk.emojis[_user.status!.emoji] ?? '', children: [
                  const TextSpan(text: ' '),
                  TextSpan(text: _user.status!.message),
                ]),
                style: TextStyle(color: context.textColor200)),
          // SelectionArea(
          //     child: HtmlWidget(
          //         "${_user.status!.emojiHTML}${_user.status!.message}")),

          UserLineInfo(
            icon: DefaultIcons.group,
            value: Wrap(
              children: [
                HyperlinkButton(
                  onPressed: () {
                    // pushRoute(context, RouterTable.followers);
                  },
                  child: Text("${_user.followersCount}个关注者"),
                ),
                const Text(dotChar),
                HyperlinkButton(
                  onPressed: () {
                    //pushRoute(context, RouterTable.following);
                  },
                  child: Text("${_user.followingCount}个关注"),
                ),
              ],
            ),
          ),

          // 公司
          UserLineInfo(
              icon: DefaultIcons.organization,
              value: _user.company,
              textColor: context.textColor200),
        ],
        // twitter
        UserLineInfo(
            icon: DefaultIcons.twitter,
            value: user.twitterUsername,
            textColor: context.textColor200),
        // 位置
        UserLineInfo(
            icon: DefaultIcons.location,
            value: user.location,
            textColor: context.textColor200),
        // 邮箱
        UserLineInfo(
            icon: DefaultIcons.mail,
            value: user.email,
            isLink: true,
            isEmail: true),
        // 个人主页
        UserLineInfo(
            icon: DefaultIcons.links, value: user.websiteUrl, isLink: true),
        //UserLineDiskUseInfo(value: user?.diskUsage),
        const SizedBox(height: 8.0),
        const Divider(),
        if (user.repositoryCount > 0)
          UserLineInfo(
              icon: DefaultIcons.repository,
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("仓库数：", style: TextStyle(color: context.textColor200)),
                  HyperlinkButton(
                    child: Text("( ${user.repositoryCount} )"),
                    onPressed: () {
                      ReposPage.createNewTab(context, user);
                    },
                  ),
                ],
              )),
      ],
    );
  }
}

/// 用户置顶的项目列表
class UserPinned extends StatelessWidget {
  const UserPinned(this.items, {super.key});

  final QLList<QLRepository> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '置顶的', //Pinned
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ),
        Wrap(
          runSpacing: 10,
          spacing: 10,
          children: items
              .map((e) => ConstrainedBox(
                    constraints:
                        const BoxConstraints.tightFor(width: 400, height: 150),
                    child: RepoListItem(
                      e,
                      isPinStyle: true,
                      expanded: true,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
