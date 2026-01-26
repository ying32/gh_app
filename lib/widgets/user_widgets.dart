import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart' as fui;
import 'package:flutter/material.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:github/github.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/link.dart';

class UserHeadNameWidget extends StatelessWidget {
  const UserHeadNameWidget({
    super.key,
    required this.login,
    this.name,
    this.avatarUrl,
    this.htmlUrl,
    this.imageSize = 64.0,
  });

  final String? login;
  final String? name;
  final String? avatarUrl;
  final String? htmlUrl;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (avatarUrl != null)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              width: imageSize,
              errorWidget: (_, __, ___) =>
                  Icon(Remix.github_fill, size: imageSize),
            ),
          ),
        const SizedBox(width: 5.0),
        Link(
          uri: Uri.parse(htmlUrl ?? ''),
          builder: (context, open) => Semantics(
            link: true,
            child: TextButton(
                onPressed: open,
                child: Text(
                  "$login${name != null && name!.isNotEmpty ? "($name)" : ''}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
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
  const CurrentUserHeadName({
    super.key,
    required this.user,
    this.imageSize = 64.0,
  });

  final CurrentUser? user;
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

class UserLineInfo extends StatelessWidget {
  const UserLineInfo({
    super.key,
    required this.icon,
    required this.value,
  });

  final IconData? icon;
  final dynamic value;

  Widget _build(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    if (value is Widget) {
      if (icon == null) return _build(value);
      return _build(Row(children: [
        Icon(icon!, size: 16),
        const SizedBox(width: 8.0),
        value
      ]));
    } else {
      Widget child = Text("$value");
      if (icon == null) return child;
      return _build(Row(children: [
        Icon(icon!, size: 16),
        const SizedBox(width: 8.0),
        child
      ]));
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
  const UserInfoPanel({
    super.key,
    required this.user,
  });

  final CurrentUser? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentUserHeadName(user: user),
        UserLineInfo(icon: null, value: user?.bio),
        UserLineInfo(
          icon: Remix.group_line,
          value: Row(
            children: [
              fui.HyperlinkButton(
                onPressed: () {
                  if (GoRouterState.of(context).uri.toString() !=
                      '/followers') {
                    context.go('/followers');
                  }
                },
                child: Text("${user?.followersCount ?? 0}个关注者"),
              ),
              const Text('·'),
              fui.HyperlinkButton(
                onPressed: () {
                  if (GoRouterState.of(context).uri.toString() !=
                      '/following') {
                    context.go('/following');
                  }
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
        UserLineInfo(icon: Remix.map_pin_line, value: user?.location),
        UserLineInfo(icon: Remix.mail_line, value: user?.email),
        UserLineInfo(icon: Remix.links_line, value: user?.blog),
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
        // UserLineDiskUseInfo(value: user?.diskUsage),
        const SizedBox(height: 8.0),
      ],
    );
  }
}
