import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/fonts/remix_icon.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/highlight_plus.dart';
import 'package:gh_app/widgets/markdown.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';
import 'package:provider/provider.dart';

/// 仓库目录列表
class _RepoContents extends StatelessWidget {
  const _RepoContents({
    super.key,
    this.path = "/",
    required this.onPathChange,
  });

  final String path;
  final ValueChanged<String> onPathChange;

  /// 检测path，如果为空，则直接为 /
  String get _checkedPath => path.isEmpty ? "/" : path;

  Widget _buildItem(GitHubFile file) {
    final isFile = file.type == "file";
    return ListTile(
      leading: SizedBox(
        width: 24,
        child: isFile
            ? FileIcon(file.name ?? '', size: 24)
            : Icon(Remix.folder_fill, color: Colors.blue.lighter),
      ),
      title: Text(file.name ?? ''),
      // trailing: Text(timeToLabel(e.)),
      // trailing: Text(file.sha ?? ''),
      trailing: FutureBuilder(
        future: null,
        builder: (_, snapshot) {
          return const SizedBox.shrink();
        },
      ),
      onPressed: () {
        onPathChange.call("/${file.path}");
        // print("path=$_checkedPath, file.path=${file.path}");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return SizedBox(
      width: double.infinity,
      child: FutureBuilder(
        future: GithubCache.instance.repoContents(repo, _checkedPath),
        builder: (_, snapshot) {
          if (!snapshotIsOk(snapshot, false)) {
            return const Center(child: ProgressRing());
          }
          final contents = snapshot.data;
          if (contents == null) {
            return const SizedBox.shrink();
          }
          // 如果数据是文件，则显示内容
          if (contents.isFile) {
            print(
                "file encoding=${contents.file?.encoding}, type=${contents.file?.type}");

            try {
              return HighlightViewPlus(
                contents.file?.text ?? '',
                fileName: contents.file?.name ?? '',
              );
              // return Text(contents.file?.text ?? '');
            } catch (e) {
              return Text("Error: $e");
            }
          }
          //
          if (!contents.isDirectory || contents.tree == null) {
            return const SizedBox.shrink();
          }
          // 返回目录结构
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...contents.tree!
                  .where((e) => e.type == "dir")
                  .map((e) => _buildItem(e)),
              ...contents.tree!
                  .where((e) => e.type == "file")
                  .map((e) => _buildItem(e)),
            ],
          );
        },
      ),
    );
  }
}

/// README文件
class _RepoReadMe extends StatelessWidget {
  const _RepoReadMe({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<PathModel, String>(
        selector: (_, model) => model.path,
        builder: (_, p, __) {
          if (p != "/") return const SizedBox.shrink();
          final repo = context.read<RepoModel>().repo;
          return FutureBuilder(
            future: GithubCache.instance.repoReadMe(repo),
            builder: (_, snapshot) {
              if (!snapshotIsOk(snapshot, false, false)) {
                return const SizedBox.shrink();
              }
              final body = snapshot.data ?? '';
              return Card(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const IconText(
                            icon: Remix.book_open_line, text: Text('README')),
                        const SizedBox(width: 12.0),
                        IconText(
                            icon: Remix.scales_line,
                            text: Text(repo.license?.name ?? '')),
                      ],
                    ),
                    if (body.isNotEmpty) MarkdownBlockPlus(data: body),
                  ],
                ),
              );
            },
          );
        });
  }
}

/// 关于
class _RepoAbout extends StatelessWidget {
  const _RepoAbout({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    const padding = EdgeInsets.symmetric(horizontal: 2, vertical: 8);
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
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
        if (repo.homepage.isNotEmpty)
          IconText(
              icon: Remix.links_line,
              padding: padding,
              text: Text(repo.homepage)),

        // tags

        const IconText(
            icon: Remix.book_open_line, padding: padding, text: Text('Readme')),
        if (repo.license?.name != null)
          IconText(
              icon: Remix.scales_line,
              padding: padding,
              text: Text(
                repo.license!.name!,
                overflow: TextOverflow.ellipsis,
              )),
        // Activity
        IconText(
            icon: Remix.star_line,
            padding: padding,
            text: Text('${repo.stargazersCount}个点赞')),
        IconText(
            icon: Remix.eye_line,
            padding: padding,
            text: Text('${repo.watchersCount}个关注')),
        IconText(
            icon: Remix.git_fork_line,
            padding: padding,
            text: Text('${repo.forksCount}个分叉')),
      ],
    );
  }
}

/// 分支列表
class _Branches extends StatelessWidget {
  const _Branches({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;

    return FutureBuilder(
      future: GithubCache.instance.repoBranches(repo),
      builder: (_, snapshot) {
        // if (!snapshotIsOk(snapshot, false, false)) {
        //   return DropDownButton(
        //     title: IconText(
        //         icon: Remix.git_branch_line, text: Text(repo.defaultBranch)),
        //     items: [
        //       MenuFlyoutItem(
        //           text: const Center(
        //             child: SizedBox(width: 100, child: ProgressRing()),
        //           ),
        //           onPressed: () {})
        //     ],
        //   );
        // }
        return DropDownButton(
            title: IconText(
                icon: Remix.git_branch_line, text: Text(repo.defaultBranch)),
            items: (snapshot.data ?? [Branch(repo.defaultBranch, null)])
                .map((e) => MenuFlyoutItem(
                    leading: e.name == repo.defaultBranch
                        ? const Icon(Remix.check_line)
                        : null,
                    text: Text(e.name ?? ''),
                    trailing: e.name == repo.defaultBranch
                        ? TagLabel.other('默认')
                        : null,
                    onPressed: () {}))
                .toList());
      },
    );
  }
}

class RepoPage extends StatelessWidget {
  const RepoPage({super.key});

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    final model = context.watch<RepoModel>();
    final repo = model.repo;

    return ScaffoldPage(
      header: PageHeader(
        title: Row(
          children: [
            Text(repo.fullName),
            if (repo.isPrivate)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Remix.git_repository_private_line),
              ),
            if (repo.archived)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: TagLabel.archived(),
              ),
          ],
        ),
      ),
      content: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        child: Column(
          children: [
            // const SizedBox(height: 8.0),
            const Divider(size: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                child: Row(
                  children: [
                    // Title(
                    //     color: appTheme.color.lightest, child: Text(_repo.name)),
                    const Spacer(),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 4),
                    //   child: Button(
                    //     child: const IconText(
                    //       icon: Remix.layout_top_fill,
                    //       text:  Text('Pin/UnPin'),
                    //     ),
                    //     onPressed: () => debugPrint('pressed button'),
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Button(
                        child: IconText(
                          icon: Remix.eye_line,
                          text: Text('${repo.watchersCount} 关注/取消关注'),
                        ),
                        onPressed: () => debugPrint('pressed button'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Button(
                        onPressed: repo.allowForking ?? false
                            ? null
                            : () => debugPrint('pressed button'),
                        child: IconText(
                          icon: Remix.git_fork_line,
                          text: Text('${repo.forksCount} 分叉'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Button(
                        child: IconText(
                          icon: Remix.star_line,
                          text: Text('${repo.stargazersCount} 点赞'),
                        ),
                        onPressed: () => debugPrint('pressed button'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Row(
                children: [
                  const _Branches(),
                  const SizedBox(width: 10.0),
                  HyperlinkButton(
                    onPressed: () {},
                    child: const IconText(
                        icon: Remix.git_branch_line, text: Text("1")),
                  ),
                  const SizedBox(width: 10.0),
                  HyperlinkButton(
                    onPressed: () {},
                    child: const IconText(
                        icon: Remix.price_tag_line, text: Text("0")),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: ButtonStyle(
                      backgroundColor: ButtonState.all(Colors.green),
                      // foregroundColor: ButtonState.all(Colors.white),
                      textStyle: ButtonState.all(
                          const TextStyle(color: Colors.white)), //????
                    ),
                    child: const IconText(
                        icon: Remix.code_line,
                        text: Text('代码'),
                        trailing: Icon(Remix.arrow_drop_down_fill, size: 16)),
                    onPressed: () {},
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                child: Selector<PathModel, List<String>>(
                  selector: (_, model) => model.segmentedPaths,
                  builder: (context, segmentedPaths, __) {
                    return BreadcrumbBar(
                      items: segmentedPaths
                          .map((e) => BreadcrumbItem(
                              label: Text(e.isEmpty ? repo.name : e), value: e))
                          .toList(),
                      onItemPressed: (item) {
                        final key = "/${item.value}";
                        final model = context.read<PathModel>();
                        final pos = model.path.indexOf(key);
                        if (pos != -1) {
                          model.path =
                              model.path.substring(0, pos + key.length);
                        }
                      },
                    );
                  },
                ),
                // child: Selector<PathModel, List<String>>(
                //   selector: (_, model) => model.segmentedPaths,
                //   builder: (context, segmentedPaths, __) {
                //     return BreadcrumbBar(
                //       items: segmentedPaths
                //           .map((e) => BreadcrumbItem(
                //               label: Text(e.isEmpty ? repo.name : e), value: e))
                //           .toList(),
                //       onItemPressed: (item) {
                //         final key = "/${item.value}";
                //         final model = context.read<RepoModel>();
                //         final pos = model.path.indexOf(key);
                //         if (pos != -1) {
                //           model.path =
                //               model.path.substring(0, pos + key.length);
                //         }
                //       },
                //     );
                //   },
                // ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        // flex: 4,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                child: _RepoContents(
                                  path: context.watch<PathModel>().path,
                                  onPathChange: (value) {
                                    context.read<PathModel>().path = value;
                                  },
                                ),
                              ),
                              // Selector<RepoModel, String>(
                              //   selector: (_, model) => model.path,
                              //   builder: (_, p, __) {
                              //     return Card(
                              //         child: _RepoContents(
                              //       repo,
                              //       path: p, //context.watch<RepoModel>().path,
                              //       onPathChange: (value) {
                              //         model.path = value;
                              //       },
                              //     ));
                              //   },
                              // ),
                              const SizedBox(height: 8.0),
                              // readme，只有根目录下才显示README？或者文件中有就显示？

                              const _RepoReadMe(),
                            ]),
                      ),
                      // Expanded(child: )),
                      const SizedBox(width: 8.0),
                      // 右边
                      const SizedBox(
                        width: 300,
                        child: Card(child: _RepoAbout()),
                      )
                      //  Expanded(flex: 1, child: Card(child: _RepoAbout(_repo))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // return Selector<RepoModel, Repository>(
    //   selector: (_, model) => model.repo,
    //   builder: (_, repo, __) {
    //
    //   },
    //   // shouldRebuild: (previous, next) {
    //   //   return false;
    //   // },
    // );
  }
}
