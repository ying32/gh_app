part of '../../repo.dart';

/// 关于
class RepoAbout extends StatelessWidget {
  const RepoAbout({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    const padding = EdgeInsets.symmetric(horizontal: 2, vertical: 8);
    return Column(
      // mainAxisSize: MainAxisSize.max,
      // mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: padding,
          child: Text(
            '关于',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: padding,
          child: Text(repo.description),
        ),

        // blog
        if (repo.homepageUrl.isNotEmpty)
          UserLineInfo(
              textColor: Colors.blue,
              icon: Remix.links_line,
              value: repo.homepageUrl,
              isLink: true),
        // IconText(
        //     icon: Remix.links_line,
        //     padding: padding,
        //     text: Text(repo.homepage)),

        if (repo.topics?.isNotEmpty ?? false)
          // tags
          Padding(
            padding: padding,
            child: Wrap(
                runSpacing: 10.0,
                spacing: 8.0,
                children: repo.topics!
                    .map((e) => TagLabel.other(
                          e,
                          color: Colors.blue,
                        ))
                    .toList()),
          ),

        const IconText(
            icon: Remix.book_open_line, padding: padding, text: Text('Readme')),
        if (repo.license.name.isNotEmpty)
          IconText(
              icon: Remix.scales_line,
              padding: padding,
              text: Text(
                repo.license.name,
                overflow: TextOverflow.ellipsis,
              ),
              expanded: true),
        // Activity
        IconText(
            icon: Remix.star_line,
            padding: padding,
            text: Text('${repo.stargazersCount.toKiloString()} 点赞')),
        IconText(
            icon: Remix.eye_line,
            padding: padding,
            text: Text('${repo.watchersCount.toKiloString()} 关注')),
        IconText(
            icon: Remix.git_fork_line,
            padding: padding,
            text: Text('${repo.forksCount.toKiloString()} 分叉')),
      ],
    );
  }
}
