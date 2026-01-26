import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/fonts/remix_icon.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/highlight_plus.dart';
import 'package:gh_app/widgets/markdown.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';

/// 仓库目录列表
class _RepoContents extends StatelessWidget {
  const _RepoContents(
    this.repo, {
    super.key,
    this.path = "/",
    required this.onPathChange,
  });
  final Repository repo;
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
  const _RepoReadMe(
    this.repo, {
    super.key,
  });

  final Repository repo;

  @override
  Widget build(BuildContext context) {
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
  }
}

/// 关于
class _RepoAbout extends StatelessWidget {
  const _RepoAbout(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
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

class RepoPage extends StatefulWidget {
  const RepoPage({
    super.key,
    required this.repo,
  });

  final Repository repo;

  @override
  State<RepoPage> createState() => _RepoPageState();
}

class _RepoPageState extends State<RepoPage> {
  String _currentPath = "/";

  @override
  void initState() {
    super.initState();
  }

  Repository get _repo => widget.repo;

  void _setCurrentPath(String path) {
    if (path.isEmpty) return;
    setState(() {
      _currentPath = path;
    });
  }

  void _onContentPathChange(String value) {
    if (value == _currentPath) return;
    _setCurrentPath(value);
  }

  List<String> get _segmentedPaths {
    if (_currentPath.isEmpty || _currentPath == "/") return [""];
    final arr = _currentPath.split("/");
    return arr;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: PageHeader(
        title: Row(
          children: [
            Text(widget.repo.fullName),
            if (_repo.isPrivate)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Remix.git_repository_private_line),
              ),
            if (_repo.archived)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TagLabel(
                    color: Colors.orange,
                    text: Text(
                      '已归档 ',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    )),
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
                        child: const IconText(
                          icon: Remix.eye_line,
                          text: Text('关注/取消关注'),
                        ),
                        onPressed: () => debugPrint('pressed button'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Button(
                        onPressed: _repo.isFork
                            ? null
                            : () => debugPrint('pressed button'),
                        child: const IconText(
                          icon: Remix.git_fork_line,
                          text: Text('分叉'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Button(
                        child: const IconText(
                          icon: Remix.star_line,
                          text: Text('点赞'),
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
                  DropDownButton(
                    title: IconText(
                        icon: Remix.git_branch_line,
                        text: Text(_repo.defaultBranch)),
                    items: [
                      MenuFlyoutItem(
                          text: const Text('Send'), onPressed: () {}),
                      const MenuFlyoutSeparator(),
                      MenuFlyoutItem(
                          text: const Text('Reply'), onPressed: () {}),
                      MenuFlyoutItem(
                          text: const Text('Reply all'), onPressed: () {}),
                    ],
                  ),
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
                child: BreadcrumbBar(
                  items: _segmentedPaths
                      .map((e) => BreadcrumbItem(
                          label: Text(e.isEmpty ? _repo.name : e), value: e))
                      .toList(),
                  onItemPressed: (item) {
                    final key = "/${item.value}";
                    final pos = _currentPath.indexOf(key);

                    if (pos != -1) {
                      _setCurrentPath(
                          _currentPath.substring(0, pos + key.length));
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView(
                // padding: EdgeInsetsDirectional.only(
                //   bottom: kPageDefaultVerticalPadding,
                //   start: PageHeader.horizontalPadding(context),
                //   end: PageHeader.horizontalPadding(context),
                // ),
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
                                _repo,
                                path: _currentPath,
                                onPathChange: _onContentPathChange,
                              )),
                              const SizedBox(height: 8.0),
                              // readme，只有根目录下才显示README？或者文件中有就显示？
                              if (_currentPath == "/") _RepoReadMe(_repo),
                            ]),
                      ),
                      // Expanded(child: )),
                      const SizedBox(width: 8.0),
                      // 右边

                      SizedBox(
                        width: 300,
                        child: Card(child: _RepoAbout(_repo)),
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
  }
}
