import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';
import 'package:remixicon/remixicon.dart';

/// 仓库目录列表
class _RepoContents extends StatelessWidget {
  const _RepoContents({
    super.key,
    required this.repo,
    this.path = "/",
    required this.onPathChange,
  });
  final Repository repo;
  final String path;
  final ValueChanged<String> onPathChange;

  /// 检测path，如果为空，则直接为 /
  String get _checkedPath => path.isEmpty ? "/" : path;

  Widget _buildItem(GitHubFile file) {
    return ListTile(
      leading: Icon(file.type == "file" ? Remix.file_4_line : Remix.folder_fill,
          size: 16),
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
        print("path=$_checkedPath, file.path=${file.path}");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
            return Text(contents.file?.text ?? '');
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
    );
  }
}

/// README文件
class _RepoReadMe extends StatelessWidget {
  const _RepoReadMe({
    super.key,
    required this.repo,
  });

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GitHubFile?>(
      future: GithubCache.instance.repoReadMe(repo),
      builder: (_, snapshot) {
        if (!snapshotIsOk(snapshot)) {
          return const SizedBox.shrink();
        }
        return Card(child: MarkdownBody(data: snapshot.data?.text ?? ''));
      },
    );
  }
}

class _RepoAbout extends StatelessWidget {
  const _RepoAbout({super.key, required this.repo});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('关于'),
        Text(repo.description),
        const Text('Readme'),
        Text('${repo.stargazersCount}点赞'),
        Text('${repo.watchersCount}关注'),
        Text('${repo.forksCount}分叉'),
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
    if (_currentPath.isEmpty || _currentPath == "/") return [];
    final arr = _currentPath.split("/");
    return arr;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: PageHeader(
        title: Text(widget.repo.fullName),
        commandBar:
            const Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      content: ListView(
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        children: [
          Card(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(28),
                border: Border.all(color: Colors.grey.withAlpha(28)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_repo.isPrivate ? '私有' : '公开'}${_repo.archived ? " 已归档" : ""}',
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          const Divider(size: 1),
          const SizedBox(height: 8.0),
          Row(
            children: [
              DropDownButton(
                title: Row(
                  children: [
                    const Icon(Remix.git_branch_line, size: 16),
                    const SizedBox(width: 8.0),
                    Text(_repo.defaultBranch)
                  ],
                ),
                items: [
                  MenuFlyoutItem(text: const Text('Send'), onPressed: () {}),
                  const MenuFlyoutSeparator(),
                  MenuFlyoutItem(text: const Text('Reply'), onPressed: () {}),
                  MenuFlyoutItem(
                      text: const Text('Reply all'), onPressed: () {}),
                ],
              ),
              const SizedBox(width: 10.0),
              const Icon(Remix.git_branch_line, size: 16),
              const Text("1"), // 分支数，待写
              const SizedBox(width: 10.0),
              const Icon(Remix.price_tag_line, size: 16),
              const Text("0"), // 分支数，待写
              const Spacer(),
              FilledButton(
                child: const Row(
                  children: [
                    Icon(Remix.code_line, size: 16),
                    SizedBox(width: 5),
                    Text('代码'),
                    SizedBox(width: 5),
                    Icon(Remix.arrow_drop_down_fill, size: 16),
                  ],
                ),
                onPressed: () {},
              )
            ],
          ),
          const SizedBox(height: 8.0),
          BreadcrumbBar(
            items: _segmentedPaths
                .map((e) => BreadcrumbItem(
                    label: Text(e.isEmpty ? _repo.name : e), value: e))
                .toList(),
            onItemPressed: (item) {
              final key = "/${item.value}";
              final pos = _currentPath.indexOf(key);

              if (pos != -1) {
                _setCurrentPath(_currentPath.substring(0, pos + key.length));
              }
            },
          ),
          const SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                          child: _RepoContents(
                        repo: _repo,
                        path: _currentPath,
                        onPathChange: _onContentPathChange,
                      )),
                      const SizedBox(height: 8.0),
                      // readme，只有根目录下才显示README？或者文件中有就显示？
                      if (_currentPath == "/") _RepoReadMe(repo: _repo),
                    ]),
              ),
              // Expanded(child: )),
              const SizedBox(width: 8.0),
              // 右边
              Card(child: _RepoAbout(repo: _repo)),
            ],
          ),
        ],
      ),
    );
  }
}
