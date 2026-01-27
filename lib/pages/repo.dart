import 'dart:convert';
import 'dart:math' as math;

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

/// 内容视图
class _ContentView extends StatelessWidget {
  const _ContentView(this.file, {super.key});

  final GitHubFile file;

  bool get _canPreview => (file.size ?? 0) <= 1024 * 1024 * 1;

  static const _jpegHeader = [0xFF, 0xD8, 0xFF];
  static const tiffHeader1 = [0x49, 0x49, 0x2A];
  static const tiffHeader2 = [0x4D, 0x4D, 0x2A];
  static const tiffHeader3 = [0x4D, 0x4D, 0x00];
  static const pngHeader = [0x89, 0x50, 0x4E, 0x47];
  static const bmpHeader = [0x42, 0x4D];
  static const gifHeader = [0x47, 0x49, 0x46];

  bool _compareBytes(List<int> data1, List<int> data2) {
    final count = math.min(data1.length, data2.length);
    for (int i = 0; i < count; i++) {
      if (data1[i] != data2[i]) return false;
    }
    return true;
  }

  /// 判断file类型
  bool _isImage(List<int> data) {
    return _compareBytes(data, _jpegHeader) ||
        _compareBytes(data, tiffHeader1) ||
        _compareBytes(data, tiffHeader2) ||
        _compareBytes(data, tiffHeader3) ||
        _compareBytes(data, pngHeader) ||
        _compareBytes(data, bmpHeader) ||
        _compareBytes(data, gifHeader);
  }

  @override
  Widget build(BuildContext context) {
    if (!_canPreview) {
      return const Center(child: Text('<...文件太大...>'));
    }
    try {
      // 解码数据
      final data = base64Decode(file.content!.replaceAll("\n", ""));
      if (_isImage(data)) {
        return Image.memory(data);
      }
      return HighlightViewPlus(
        utf8.decode(data), // 这里还要处理编码
        fileName: file.name ?? '',
      );
    } catch (e) {
      return Text("Error: $e");
    }
  }
}

/// 仓库目录列表
class _RepoContents extends StatelessWidget {
  const _RepoContents({
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
      trailing: FutureBuilder(
        future: null,
        builder: (_, snapshot) {
          return const SizedBox.shrink();
        },
      ),
      onPressed: () {
        onPathChange.call("/${file.path}");
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
            return _ContentView(contents.file!);
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
                            icon: Remix.book_open_line,
                            text: Text(
                              'README',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                        const SizedBox(width: 12.0),
                        IconText(
                            icon: Remix.scales_line,
                            text: Text(
                              repo.license?.name ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            )),
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
        if (repo.homepage.isNotEmpty)
          IconText(
              icon: Remix.links_line,
              padding: padding,
              text: Text(repo.homepage)),

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
class _RepoBranches extends StatelessWidget {
  const _RepoBranches({super.key});

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
        final branches = (snapshot.data ?? [Branch(repo.defaultBranch, null)]);
        return Row(
          children: [
            DropDownButton(
                title: IconText(
                    icon: Remix.git_branch_line,
                    text: Text(repo.defaultBranch)),
                items: branches
                    .map((e) => MenuFlyoutItem(
                        leading: e.name == repo.defaultBranch
                            ? const Icon(Remix.check_line)
                            : null,
                        text: Text(e.name ?? ''),
                        trailing: e.name == repo.defaultBranch
                            ? TagLabel.other('默认')
                            : null,
                        onPressed: () {}))
                    .toList()),
            const SizedBox(width: 10.0),
            HyperlinkButton(
              onPressed: () {},
              child: IconText(
                  icon: Remix.git_branch_line,
                  text: Text("${branches.length}")),
            ),
            const SizedBox(width: 10.0),
            HyperlinkButton(
              onPressed: () {},
              child:
                  const IconText(icon: Remix.price_tag_line, text: Text("0")),
            ),
          ],
        );
      },
    );
  }
}

/// Release
class _RepoReleases extends StatelessWidget {
  const _RepoReleases({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return FutureBuilder(
      future: GithubCache.instance.repoReleases(repo),
      builder: (_, snapshot) {
        if (!snapshotIsOk(snapshot) || (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }

        final releases = snapshot.data ?? [];
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Releases ${releases.length}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Text('${}'),
              IconText(
                icon: Remix.price_tag_line,
                iconColor: Colors.green,
                text: Text(
                  releases.last.name ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                trailing: TagLabel.other(
                  "Latest",
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              if (releases.length > 1)
                Text(
                  '+ ${releases.length - 1} releases',
                  style: TextStyle(color: Colors.blue),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 顶部条1
class _TopBar1 extends StatelessWidget {
  const _TopBar1({
    super.key,
    this.useCard = true,
  });

  final bool useCard;

  void _onFork() {
    // showInfoDialog("", context: )
  }

  void _onStar() {}

  void _onWatch() {}

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    Widget child = Row(
      children: [
        // Title(
        //     color: appTheme.color.lightest, child: Text(_repo.name)),
        // const Spacer(),
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
            onPressed: _onWatch,
            child: IconText(
              icon: Remix.eye_line,
              text: Text('${repo.watchersCount} 关注/取消关注'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            onPressed: repo.allowForking != true ? null : _onFork,
            child: IconText(
              icon: Remix.git_fork_line,
              text: Text('${repo.forksCount} 分叉'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            onPressed: _onStar,
            child: IconText(
              icon: Remix.star_line,
              text: Text('${repo.stargazersCount} 点赞'),
            ),
          ),
        ),
      ],
    );
    if (useCard) {
      child = Card(child: child);
    }
    return child;
  }
}

class _TopBar2 extends StatelessWidget {
  const _TopBar2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Row(
        children: [
          _RepoBranches(),
          Spacer(),
          _TopBar1(useCard: false),
          SizedBox(width: 10.0),
          // FilledButton(
          //   style: ButtonStyle(
          //     backgroundColor: ButtonState.all(Colors.green),
          //     // foregroundColor: ButtonState.all(Colors.white),
          //     textStyle:
          //         ButtonState.all(const TextStyle(color: Colors.white)), //????
          //   ),
          //   child: const IconText(
          //       icon: Remix.code_line,
          //       text: Text('代码'),
          //       trailing: Icon(Remix.arrow_drop_down_fill, size: 16)),
          //   onPressed: () {},
          // )
        ],
      ),
    );
  }
}

/// 导航指示器
class _RepoBreadcrumbBar extends StatelessWidget {
  const _RepoBreadcrumbBar({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return Selector<PathModel, List<String>>(
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
              model.path = model.path.substring(0, pos + key.length);
            }
          },
        );
      },
    );
  }
}

/// 关于/Release信息等
class _CodePageRight extends StatelessWidget {
  const _CodePageRight({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: double.infinity, child: Card(child: _RepoAbout())),
        SizedBox(height: 2),
        SizedBox(width: double.infinity, child: _RepoReleases()),
      ],
    );
  }
}

class _CodePage extends StatelessWidget {
  const _CodePage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(size: 1),
        // const Padding(
        //   padding: EdgeInsets.symmetric(vertical: 8.0),
        //   child: _TopBar1(),
        // ),
        const _TopBar2(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Card(child: _RepoBreadcrumbBar()),
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
                    child: _CodePageRight(),
                  )
                  //  Expanded(flex: 1, child: Card(child: _RepoAbout(_repo))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IssuesPage extends StatelessWidget {
  const _IssuesPage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _PullRequestPage extends StatelessWidget {
  const _PullRequestPage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _ActionPage extends StatelessWidget {
  const _ActionPage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _WikiPage extends StatelessWidget {
  const _WikiPage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _TabPages extends StatefulWidget {
  const _TabPages({super.key});

  @override
  State<_TabPages> createState() => _TabPagesState();
}

class _TabPagesState extends State<_TabPages> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return TabView(
      currentIndex: currentIndex,
      tabs: [
        Tab(
          text: const Text('代码'),
          icon: const Icon(Remix.code_line),
          closeIcon: null,
          body: _CodePage(repo),
        ),
        Tab(
          text: Text('问题 ${repo.openIssues ?? 0}'),
          icon: const Icon(Remix.issues_line),
          closeIcon: null,
          body: _IssuesPage(repo),
        ),
        Tab(
          text: const Text('合并请求 ${0}'),
          icon: const Icon(Remix.git_pull_request_line),
          closeIcon: null,
          body: _PullRequestPage(repo),
        ),
        Tab(
          text: const Text('Actions'),
          icon: const Icon(Remix.play_circle_line),
          closeIcon: null,
          body: _ActionPage(repo),
        ),
        Tab(
          text: const Text('Wiki'),
          icon: const Icon(Remix.book_open_line),
          closeIcon: null,
          body: _WikiPage(repo),
        ),
      ],
      onChanged: (index) {
        setState(() => currentIndex = index);
      },
      tabWidthBehavior: TabWidthBehavior.sizeToContent,
      closeButtonVisibility: CloseButtonVisibilityMode.never,
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
            const Spacer(),
            LinkAction(
              icon: const Icon(FluentIcons.open_source, size: 18),
              link: repo.htmlUrl,
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
        child: const _TabPages(),
      ),
    );
  }
}
