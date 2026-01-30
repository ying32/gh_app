import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/widgets/markdown_plus.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleasesPage extends StatelessWidget {
  const ReleasesPage({
    super.key,
    required this.repo,
    required this.releases,
  });

  final Repository repo;
  final List<Release> releases;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        itemCount: releases.length,
        // controller: scrollController,
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          // start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        itemBuilder: (context, index) {
          final item = releases[index];

          return Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 15.0),
                  if (item.createdAt != null)
                    Text(
                        '${item.createdAt!.year}年${item.createdAt!.month}月${item.createdAt!.day}日'),
                  Text(item.author?.name ?? item.author?.login ?? ''),
                  Text('${item.tagName}'),
                  Text('${item.targetCommitish}'),
                ],
              ),
              const SizedBox(width: 10.0),
              Expanded(
                  child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? '',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (item.description?.isNotEmpty ?? false)
                      Text(item.description ?? ''),
                    if (item.body?.isNotEmpty ?? false)
                      MarkdownBlockPlus(
                        data: item.body!,
                        onTap: (link) {
                          print("点击了链接=$link");
                        },
                      ),
                    // item.assets
                    const Divider(size: 1),

                    Text(
                      'Assets ${2 + (item.assets?.length ?? 0)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (item.zipballUrl != null)
                      LinkStyleButton(
                        text: Text(
                          'Source code (zip)',
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () {
                          launchUrl(Uri.parse(item.zipballUrl!));
                        },
                      ),
                    if (item.tarballUrl != null)
                      LinkStyleButton(
                        text: Text(
                          'Source code (tar.gz)',
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () {
                          launchUrl(Uri.parse(item.tarballUrl!));
                        },
                      ),

                    if (item.assets?.isNotEmpty ?? false)
                      ...item.assets!.map((e) => Text('${e.name}')),
                  ],
                ),
              )),
            ],
          );

          return Card(
            child: ListTile(
              title: Text(item.name ?? ''),
              subtitle: Text(
                  "${item.description ?? ''}, ${item.tagName} ${item.body}"),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 30));
  }

  static void createNewTab(
      BuildContext context, Repository repo, List<Release> releases) {
    context.read<TabviewModel>().addTab(
          // ChangeNotifierProvider<RepoModel>(
          //   create: (_) => RepoModel(repo),
          //   child: const RepoPage(),
          // ),
          ReleasesPage(repo: repo, releases: releases),
          key: ValueKey("${RouterTable.release}/${repo.fullName}"),
          title: '${repo.fullName} Releases',
          icon: Remix.git_branch_line,
        );
  }
}
