import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/router.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';
import 'package:url_launcher/link.dart';

class UserHeadNameWidget extends StatelessWidget {
  const UserHeadNameWidget({
    super.key,
    required this.login,
    this.name,
    this.avatarUrl,
    this.htmlUrl,
    this.imageSize = 64.0,
    this.onlyNickName = false,
  });

  final String? login;
  final String? name;
  final String? avatarUrl;
  final String? htmlUrl;
  final double imageSize;
  final bool onlyNickName;

  String get _displayName {
    final nickName = name ?? login ?? '';
    if (onlyNickName) return nickName;
    if (nickName == "" || nickName == login) {
      return login ?? '';
    }
    return "$login${"($nickName)"}";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (avatarUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 1.0),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                width: imageSize,
                errorWidget: (_, __, ___) =>
                    Icon(Remix.github_fill, size: imageSize),
              ),
            ),
          ),
        Link(
          uri: Uri.parse(htmlUrl ?? ''),
          builder: (context, open) => Semantics(
            link: true,
            child: LinkStyleButton(
                onPressed: () => open?.call(),
                text: Text(
                  _displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: appTheme.color.lightest),
                )),
          ),
        )
      ],
    );
  }
}

class UserHeadName extends StatelessWidget {
  const UserHeadName({
    super.key,
    required this.user,
    this.imageSize = 40.0,
  });

  final User? user;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return UserHeadNameWidget(
      login: user?.login,
      name: user?.name,
      avatarUrl: user?.avatarUrl,
      htmlUrl: user?.htmlUrl,
      imageSize: imageSize,
    );
  }
}

class CurrentUserHeadName extends StatelessWidget {
  const CurrentUserHeadName(
    this.user, {
    super.key,
    this.imageSize = 64.0,
    this.onlyNickName = false,
  });

  final CurrentUser? user;
  final double imageSize;
  final bool onlyNickName;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    return UserHeadNameWidget(
      login: user?.login,
      name: user?.name,
      avatarUrl: user?.avatarUrl,
      htmlUrl: user?.htmlUrl,
      imageSize: imageSize,
      onlyNickName: onlyNickName,
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
            ? Link(
                uri: Uri.parse(isEmail ? "mailto:$value" : value),
                builder: (context, open) => Semantics(
                  link: true,
                  child: LinkStyleButton(
                    onPressed: () => open?.call(),
                    text: child,
                    padding: EdgeInsets.zero,
                  ),
                ),
              )
            : child,
      );

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
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
      icon: Remix.drive_line,
      value: (value ?? 0).toSizeString(),
    );
  }
}

class UserInfoPanel extends StatelessWidget {
  const UserInfoPanel(
    this.user, {
    super.key,
  });

  final CurrentUser? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.start,
      // mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentUserHeadName(user),
        UserLineInfo(icon: null, value: user?.bio),
        UserLineInfo(
          icon: Remix.group_line,
          value: Row(
            children: [
              HyperlinkButton(
                onPressed: () {
                  pushRoute(context, RouterTable.followers);
                },
                child: Text("${user?.followersCount ?? 0}个关注者"),
              ),
              const Text('·'),
              HyperlinkButton(
                onPressed: () {
                  pushRoute(context, RouterTable.following);
                },
                child: Text("${user?.followingCount ?? 0}个关注"),
              ),

              // m.RichText(
              //   text: m.TextSpan(
              //     children: [
              //       const m.WidgetSpan(
              //           child: Icon(Remix.group_line, size: 16)),
              //       m.TextSpan(
              //         text:
              //             "${_currentUser?.followersCount ?? 0}个关注者",
              //         recognizer: TapGestureRecognizer()
              //           ..onTap = () {
              //             debugPrint("单击");
              //           },
              //       ),
              //       const m.TextSpan(text: '·'),
              //       m.TextSpan(
              //         text:
              //             "${_currentUser?.followingCount ?? 0}个关注",
              //         recognizer: TapGestureRecognizer()
              //           ..onTap = () {
              //             debugPrint("单击");
              //           },
              //       ),
              //     ],
              //   ),
              // ),

              // 这里要用RichText来弄
              // m.TextButton.icon(
              //     label: Text(
              //         "${_currentUser?.followersCount ?? 0}个关注者· "),
              //     icon: const Icon(Remix.group_line, size: 16),
              //     onPressed: () {}),
              // m.TextButton.icon(
              //     label: Text(
              //         "${_currentUser?.followingCount ?? 0}个关注· "),
              //     icon: const Icon(Remix.group_line, size: 16),
              //     onPressed: () {}),
            ],
          ),
        ),
        UserLineInfo(icon: Remix.organization_chart, value: user?.company),
        UserLineInfo(icon: Remix.twitter_line, value: user?.twitterUsername),
        UserLineInfo(icon: Remix.map_pin_line, value: user?.location),
        UserLineInfo(
            icon: Remix.mail_line,
            value: user?.email,
            isLink: true,
            isEmail: true),
        UserLineInfo(icon: Remix.links_line, value: user?.blog, isLink: true),
        // if (user?.blog != null && user!.blog!.isNotEmpty)
        //   UserLineInfo(
        //       icon: Remix.links_line,
        //       value: Link(
        //         uri: Uri.parse(user!.blog!),
        //         builder: (context, open) => Semantics(
        //           link: true,
        //           child: TextButton(
        //               onPressed: open,
        //               child: Text(
        //                 user!.blog!,
        //               )),
        //         ),
        //       )),
        UserLineDiskUseInfo(value: user?.diskUsage),
        const SizedBox(height: 8.0),
      ],
    );
  }
}
