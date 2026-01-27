import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/fonts/remix_icon.dart';
import 'package:gh_app/router.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/page.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';

class _RepoListItem extends StatelessWidget {
  const _RepoListItem(this.repo);

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
                  pushRoute(context, '/repo', extra: repo);
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

          //Text('${item.tagsUrl}'),

          Row(
            children: [
              // 语言的一个圆，颜色还要待弄下哈
              ClipOval(
                child:
                    Container(width: 10.0, height: 10.0, color: Colors.green),
              ),
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
                    text: Text('${repo.forks ?? 0}')),
              ),
              // 关注数
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: Remix.star_line,
                    // padding: padding,
                    text: Text('${repo.stargazersCount}')),
              ),
              // 当前打开的issue数
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: Remix.issues_line,
                    // padding: padding,
                    text: Text('${repo.openIssuesCount}')),
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

class _RepoListView extends StatelessWidget {
  const _RepoListView({
    super.key,
    required this.repos,
  });

  final List<Repository> repos;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 6);

    return ListView.separated(
      itemCount: repos.length,
      // controller: scrollController,
      padding: EdgeInsetsDirectional.only(
        bottom: kPageDefaultVerticalPadding,
        start: PageHeader.horizontalPadding(context),
        end: PageHeader.horizontalPadding(context),
      ),
      itemBuilder: (context, index) {
        final repo = repos[index];
        return _RepoListItem(repo);
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: 2), // Divider(size: 1, direction: Axis.horizontal),
    );
  }
}

class ReposPage extends StatefulWidget {
  const ReposPage({
    super.key,
    required this.owner,
  });

  final String owner;

  @override
  State<ReposPage> createState() => _ReposPageState();
}

class _ReposPageState extends State<ReposPage> with PageMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('仓库'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      content: FutureBuilder(
        future: GithubCache.instance.userRepos(widget.owner),
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          return _RepoListView(repos: snapshot.data ?? []);
        },
      ),
    );
  }
}
