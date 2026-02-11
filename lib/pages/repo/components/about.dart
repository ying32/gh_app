part of '../../repo.dart';

/// 关于
class RepoAbout extends StatelessWidget {
  const RepoAbout({super.key});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 2, vertical: 8);
    return RepoSelector(
      builder: (_, repo) {
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
              child: SelectableText(repo.description),
            ),

            // blog
            if (repo.homepageUrl.isNotEmpty)
              UserLineInfo(
                  textColor: Colors.blue,
                  icon: DefaultIcons.links,
                  value: repo.homepageUrl,
                  isLink: true),
            // IconText(
            //     icon: Remix.links_line,
            //     padding: padding,
            //     text: Text(repo.homepage)),

            if (repo.repositoryTopics?.isNotEmpty ?? false)
              Padding(
                padding: padding,
                child: RepoTopics(repo.repositoryTopics!),
              ),

            const IconText(
                icon: DefaultIcons.readme,
                padding: padding,
                text: Text('Readme')),
            if (repo.licenseInfo?.name.isNotEmpty ?? false)
              IconText(
                  icon: DefaultIcons.license,
                  padding: padding,
                  text: Text(
                    repo.licenseInfo!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  expanded: true),
            // Activity
            IconText(
                icon: DefaultIcons.star,
                padding: padding,
                text: Text('${repo.stargazersCount.toKiloString()} 点赞')),
            IconText(
                icon: DefaultIcons.watch,
                padding: padding,
                text: Text('${repo.watchersCount.toKiloString()} 关注')),
            IconText(
                icon: DefaultIcons.fork,
                padding: padding,
                text: Text('${repo.forksCount.toKiloString()} 派生')),
          ],
        );
      },
    );
  }
}
