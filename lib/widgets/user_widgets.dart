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

/// 用户名
class UserNameWidget extends StatelessWidget {
  const UserNameWidget(
    this.user, {
    super.key,
    this.onlyNickName = false,
  });

  final QLUser? user;
  final bool onlyNickName;

  String get _displayName {
    final nickName = user?.name ?? user?.login ?? '';
    if (onlyNickName) return nickName;
    if (nickName == "" || nickName == user?.login) {
      return user?.login ?? '';
    }
    return "${user?.login}${"($nickName)"}";
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

  final QLUser? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像和名字
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              UserHeadImage(user!.avatarUrl, imageSize: 60),
              const SizedBox(width: 10.0),
              SelectionArea(child: UserNameWidget(user)),
            ],
          ),
        ),
        // 签名信息
        SelectionArea(
            child: UserLineInfo(
                icon: null, value: user!.bio, textColor: context.textColor200)),
        const SizedBox(height: 8),
        // 心情
        if (user!.status.emojiHTML.isNotEmpty ||
            user!.status.message.isNotEmpty)
          SelectionArea(
              child: HtmlWidget(
                  "${user!.status.emojiHTML}${user!.status.message}")),

        UserLineInfo(
          icon: DefaultIcons.group,
          value: Row(
            children: [
              HyperlinkButton(
                onPressed: () {
                  // pushRoute(context, RouterTable.followers);
                },
                child: Text("${user?.followersCount ?? 0}个关注者"),
              ),
              const Text(dotChar),
              HyperlinkButton(
                onPressed: () {
                  //pushRoute(context, RouterTable.following);
                },
                child: Text("${user?.followingCount ?? 0}个关注"),
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
            value: user?.company,
            textColor: context.textColor200),
        UserLineInfo(
            icon: DefaultIcons.twitter,
            value: user?.twitterUsername,
            textColor: context.textColor200),
        UserLineInfo(
            icon: DefaultIcons.location,
            value: user?.location,
            textColor: context.textColor200),
        UserLineInfo(
            icon: DefaultIcons.mail,
            value: user?.email,
            isLink: true,
            isEmail: true),
        UserLineInfo(
            icon: DefaultIcons.links, value: user?.websiteUrl, isLink: true),
        //UserLineDiskUseInfo(value: user?.diskUsage),
        const SizedBox(height: 8.0),
      ],
    );
  }
}
