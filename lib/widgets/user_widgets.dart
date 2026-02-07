import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// 用户头像
class UserHeadImage extends StatelessWidget {
  const UserHeadImage(
    this.user, {
    super.key,
    this.imageSize = 64,
    this.tooltip,
    this.onPressed,
  });

  final QLActor? user;
  final double imageSize;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }
    Widget child = ClipOval(
      child: Container(
        color: Colors.black.withOpacity(0.08),
        child: CachedNetworkImageEx(
          user!.avatarUrl,
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
      return user.login ?? '';
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

  Widget _build(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: isLink && value is String
            ? LinkButton(
                onPressed: () {
                  launchUrl(Uri.parse(isEmail ? "mailto:$value" : value));
                },
                text: child,
                padding: EdgeInsets.zero,
              )
            : child,
      );

  @override
  Widget build(BuildContext context) {
    if (value == null || (value is String && (value as String).isEmpty)) {
      return const SizedBox.shrink();
    }
    if (value is Widget) {
      if (icon == null) return _build(value);
      return _build(IconText(icon: icon!, text: value));
    } else {
      Widget child = Text("$value", style: TextStyle(color: textColor));
      if (icon == null) return child;
      return _build(IconText(icon: icon!, text: child, iconColor: textColor));
    }
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
              UserHeadImage(user, imageSize: 60),
              const SizedBox(width: 10.0),
              Expanded(child: SelectionArea(child: UserNameWidget(user))),
            ],
          ),
        ),
        if (user is QLUser) ...[
          // 签名信息
          SelectionArea(
              child: UserLineInfo(
                  icon: null,
                  value: _user.bio,
                  textColor: context.textColor200)),
          const SizedBox(height: 8),
          // 心情
          if (_user.status != null && _user.status!.emojiHTML.isNotEmpty ||
              _user.status!.message.isNotEmpty)
            SelectionArea(
                child: HtmlWidget(
                    "${_user.status!.emojiHTML}${_user.status!.message}")),

          UserLineInfo(
            icon: DefaultIcons.group,
            value: Wrap(
              children: [
                HyperlinkButton(
                  onPressed: () {
                    // pushRoute(context, RouterTable.followers);
                  },
                  child: Text("${_user.followersCount ?? 0}个关注者"),
                ),
                const Text(dotChar),
                HyperlinkButton(
                  onPressed: () {
                    //pushRoute(context, RouterTable.following);
                  },
                  child: Text("${_user.followingCount ?? 0}个关注"),
                ),
                // 这里要用RichText来弄
                // m.TextButton.icon(
                //     label: Text(
                //         "${_currentUser?.followersCount ?? 0}个关注者· "),
                //     icon: const Icon(DefaultIcons.group, size: 16),
                //     onPressed: () {}),
                // m.TextButton.icon(
                //     label: Text(
                //         "${_currentUser?.followingCount ?? 0}个关注· "),
                //     icon: const Icon(DefaultIcons.group, size: 16),
                //     onPressed: () {}),
              ],
            ),
          ),

          UserLineInfo(
              icon: DefaultIcons.organization,
              value: _user.company,
              textColor: context.textColor200),
        ],
        UserLineInfo(
            icon: DefaultIcons.twitter,
            value: user.twitterUsername,
            textColor: context.textColor200),
        UserLineInfo(
            icon: DefaultIcons.location,
            value: user.location,
            textColor: context.textColor200),
        UserLineInfo(
            icon: DefaultIcons.mail,
            value: user.email,
            isLink: true,
            isEmail: true),
        UserLineInfo(
            icon: DefaultIcons.links, value: user.websiteUrl, isLink: true),
        //UserLineDiskUseInfo(value: user?.diskUsage),
        const SizedBox(height: 8.0),
      ],
    );
  }
}
