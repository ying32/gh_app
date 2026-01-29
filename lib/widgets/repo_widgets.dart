import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/pages/repo/repo.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';

/// 语言的圆点
class LangCircleDot extends StatelessWidget {
  const LangCircleDot(this.lang, {super.key});
  final String lang;
  @override
  Widget build(BuildContext context) {
    if (lang.isEmpty) return const SizedBox.shrink();
    return ClipOval(
      child: Container(
        width: 10.0,
        height: 10.0,
        color: hexColorTo(languageColors[lang] ?? ''),
        // color: Color(int.tryParse(
        //         "FF${(languageColors[lang] ?? '').replaceFirst("#", "")}",
        //         radix: 16) ??
        //     Colors.green.green),
      ),
    );
  }
}

class RepoListItem extends StatelessWidget {
  const RepoListItem(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 6);
    //final theme = FluentTheme.of(context);
    return Card(
      // child: DefaultTextStyle(
      //   style: TextStyle(color: appTheme.color.lightest),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Text("${item.owner?.login ?? ''}/${item.name}"),
              // 仓库所有者和仓库名
              // HyperlinkButton(
              //   onPressed: () {
              //     pushRoute(context, '/repo', extra: repo);
              //   },
              //   child: Text("${repo.owner?.login ?? ''}/${repo.name}"),
              // ),

              LinkStyleButton(
                onPressed: () {
                  RepoPage.createNewTab(context, repo);

                  //pushRoute(context, RouterTable.repo, extra: repo);
                },
                text: Text(
                  "${repo.owner?.login ?? ''}/${repo.name}",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),

              const SizedBox(width: 8.0),
              // 公开或者私有
              if (repo.isPrivate) const TagLabel.private(),

              // 是否归档
              if (repo.archived)
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: TagLabel.archived()),

              const Spacer(),
              LinkAction(
                icon: const Icon(FluentIcons.open_source, size: 18),
                link: repo.htmlUrl,
              ),
            ],
          ),

          // 描述
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              repo.description,
              style: TextStyle(color: appTheme.color.lightest),
            ),
          ),

          // 关键词
          if (repo.topics?.isNotEmpty ?? false)
            // tags
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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

          //Text('${item.tagsUrl}'),

          Row(
            children: [
              // 语言的一个圆，颜色还要待弄下哈
              LangCircleDot(repo.language),

              // 语言
              Padding(
                  padding: padding,
                  child: Text(repo.language,
                      style: TextStyle(color: appTheme.color.lightest))),
              // 授权协议
              if (repo.license?.name != null) ...[
                IconText(
                    icon: Remix.scales_line,
                    padding: padding,
                    iconColor: appTheme.color.lightest,
                    text: Text(repo.license!.name!,
                        style: TextStyle(color: appTheme.color.lightest))),
              ],
              // fork数
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: Remix.git_fork_line,
                    // padding: padding,
                    text: Text((repo.forks ?? 0).toKiloString())),
              ),
              // 关注数
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: Remix.star_line,
                    // padding: padding,
                    text: Text(repo.stargazersCount.toKiloString())),
              ),
              // 当前打开的issue数，这里貌似包含pull requests的数量
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: Remix.issues_line,
                    // padding: padding,
                    text: Text(repo.openIssuesCount.toKiloString())),
              ),
              // 最后更新时间
              Padding(
                padding: padding,
                child: Text(timeToLabel(repo.updatedAt),
                    style: TextStyle(color: appTheme.color.lightest)),
              ),
            ],
          ),
        ],
        // ),
      ),
    );
  }
}

class RepoListView extends StatelessWidget {
  const RepoListView({
    super.key,
    required this.repos,
  });

  final List<Repository> repos;

  @override
  Widget build(BuildContext context) {
    if (repos.isEmpty) return const SizedBox.shrink();
    // const padding = EdgeInsets.symmetric(horizontal: 6);
    return ListView.separated(
      itemCount: repos.length,
      // controller: scrollController,
      padding: EdgeInsetsDirectional.only(
        bottom: kPageDefaultVerticalPadding,
        // start: PageHeader.horizontalPadding(context),
        end: PageHeader.horizontalPadding(context),
      ),
      itemBuilder: (context, index) {
        final repo = repos[index];
        return RepoListItem(repo);
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: 2), // Divider(size: 1, direction: Axis.horizontal),
    );
  }
}
