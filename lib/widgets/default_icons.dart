import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';

/// 定义一些使用的icon别名，方便更换其它样式的
class DefaultIcons {
  static const github = Remix.github_fill;
  static const home = Remix.home_line;
  static const issues = Remix.issues_line;
  static const pullRequest = Remix.git_pull_request_line;
  static const repository = Remix.git_repository_line;
  static const star = Remix.star_line;
  static const search = Remix.search_line;
  static const settings = Remix.settings_line;
  static const tags = Remix.price_tag_2_line;
  static const releases = Remix.price_tag_3_line;
  static const commit = Remix.git_commit_line;
  static const verifiedBadge = Remix.verified_badge_line;
  static const code = Remix.code_line;
  static const action = Remix.play_circle_line;
  static const wiki = Remix.book_open_line;
  static const repositoryPrivate = Remix.git_repository_private_line;
  static const user = Remix.user_line;
  static const branch = Remix.git_branch_line;
  static const check = Remix.check_line;
  static const watch = Remix.eye_line;
  static const fork = Remix.git_fork_line;
  static const comment = Remix.chat_2_line;
  static const links = Remix.links_line;
  static const readme = Remix.book_open_line;
  static const license = Remix.scales_line;
  static const folder = Remix.folder_fill;
  static const drive = Remix.drive_line;
  static const group = Remix.group_line;
  static const organization = Remix.organization_chart;
  static const twitter = Remix.twitter_line;
  static const location = Remix.map_pin_line;
  static const mail = Remix.mail_line;
  static const linkSource = FluentIcons.open_source;
}

class ApplicationIcon extends StatelessWidget {
  const ApplicationIcon({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/logo-128x128.png',
        width: size, height: size, fit: BoxFit.scaleDown);
  }
}

/// 定义了一些常用的icon
class DefaultIcon extends StatelessWidget {
  const DefaultIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
  });

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size ?? 16, color: color);

  const DefaultIcon.github({super.key, this.size, this.color})
      : icon = DefaultIcons.github;
  const DefaultIcon.home({super.key, this.size, this.color})
      : icon = DefaultIcons.home;
  const DefaultIcon.issues({super.key, this.size, this.color})
      : icon = DefaultIcons.issues;
  const DefaultIcon.pullRequest({super.key, this.size, this.color})
      : icon = DefaultIcons.pullRequest;
  const DefaultIcon.repository({super.key, this.size, this.color})
      : icon = DefaultIcons.repository;
  const DefaultIcon.star({super.key, this.size, this.color})
      : icon = DefaultIcons.star;
  const DefaultIcon.search({super.key, this.size, this.color})
      : icon = DefaultIcons.search;
  const DefaultIcon.settings({super.key, this.size, this.color})
      : icon = DefaultIcons.settings;
  const DefaultIcon.tag({super.key, this.size, this.color})
      : icon = DefaultIcons.tags;
  const DefaultIcon.releases({super.key, this.size, this.color})
      : icon = DefaultIcons.releases;
  const DefaultIcon.commit({super.key, this.size, this.color})
      : icon = DefaultIcons.commit;
  const DefaultIcon.verifiedBadge({super.key, this.size, this.color})
      : icon = DefaultIcons.verifiedBadge;
  const DefaultIcon.code({super.key, this.size, this.color})
      : icon = DefaultIcons.code;
  const DefaultIcon.action({super.key, this.size, this.color})
      : icon = DefaultIcons.action;
  const DefaultIcon.wiki({super.key, this.size, this.color})
      : icon = DefaultIcons.wiki;
  const DefaultIcon.repositoryPrivate({super.key, this.size, this.color})
      : icon = DefaultIcons.repositoryPrivate;
  const DefaultIcon.user({super.key, this.size, this.color})
      : icon = DefaultIcons.user;
  const DefaultIcon.branch({super.key, this.size, this.color})
      : icon = DefaultIcons.branch;
  const DefaultIcon.check({super.key, this.size, this.color})
      : icon = DefaultIcons.check;
  const DefaultIcon.watch({super.key, this.size, this.color})
      : icon = DefaultIcons.watch;
  const DefaultIcon.fork({super.key, this.size, this.color})
      : icon = DefaultIcons.fork;
  const DefaultIcon.comment({super.key, this.size, this.color})
      : icon = DefaultIcons.comment;
  const DefaultIcon.links({super.key, this.size, this.color})
      : icon = DefaultIcons.links;
  const DefaultIcon.readme({super.key, this.size, this.color})
      : icon = DefaultIcons.readme;
  const DefaultIcon.license({super.key, this.size, this.color})
      : icon = DefaultIcons.license;
  const DefaultIcon.folder({super.key, this.size, this.color})
      : icon = DefaultIcons.folder;
  const DefaultIcon.drive({super.key, this.size, this.color})
      : icon = DefaultIcons.drive;
  const DefaultIcon.group({super.key, this.size, this.color})
      : icon = DefaultIcons.group;
  const DefaultIcon.organization({super.key, this.size, this.color})
      : icon = DefaultIcons.organization;
  const DefaultIcon.twitter({super.key, this.size, this.color})
      : icon = DefaultIcons.twitter;
  const DefaultIcon.location({super.key, this.size, this.color})
      : icon = DefaultIcons.location;
  const DefaultIcon.mail({super.key, this.size, this.color})
      : icon = DefaultIcons.mail;
  const DefaultIcon.linkSource({super.key, this.size, this.color})
      : icon = DefaultIcons.linkSource;
}
