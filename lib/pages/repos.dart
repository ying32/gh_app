import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/router.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/page.dart';
import 'package:github/github.dart';
import 'package:remixicon/remixicon.dart';

class _RepoListView extends StatelessWidget {
  const _RepoListView({
    super.key,
    required this.repos,
  });

  final List<Repository> repos;

  @override
  Widget build(BuildContext context) {
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
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Text("${item.owner?.login ?? ''}/${item.name}"),
                  HyperlinkButton(
                    onPressed: () {
                      //  context.go('/navigation_view');
                      pushRoute(context, '/repo', extra: repo);
                    },
                    child: Text("${repo.owner?.login ?? ''}/${repo.name}"),
                  ),

                  const SizedBox(width: 8.0),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(28),
                      border: Border.all(color: Colors.grey.withAlpha(28)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${repo.isPrivate ? '私有' : '公开'}${repo.archived ? " 已归档" : ""}',
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8.0),
              Text(repo.description),
              const SizedBox(height: 8.0),
              //Text('${item.tagsUrl}'),

              Row(
                children: [
                  ClipOval(
                    child: Container(
                        width: 10.0, height: 10.0, color: Colors.green),
                  ),
                  const SizedBox(width: 8.0),
                  Text(repo.language),
                  const SizedBox(width: 8.0),
                  if (repo.license?.name != null) ...[
                    // const Icon(FluentIcons.lic, size: 16.0),
                    Text(repo.license!.name!),
                  ],
                  const SizedBox(width: 8.0),
                  const Icon(Remix.git_fork_line, size: 16.0),
                  Text('${repo.forks ?? 0}'),
                  const SizedBox(width: 8.0),
                  const Icon(Remix.star_line, size: 16.0),
                  Text('${repo.stargazersCount ?? 0}'),
                  const SizedBox(width: 8.0),
                  const Icon(Remix.info_i, size: 16.0),
                  Text('${repo.openIssuesCount}'),
                  const SizedBox(width: 8.0),
                  Text(timeToLabel(repo.updatedAt)),
                ],
              ),
            ],
          ),
        );
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
