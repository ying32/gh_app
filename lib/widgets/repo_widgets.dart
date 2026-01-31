import 'dart:convert';
import 'dart:math' as math;

import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/pages/repo.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'highlight_plus.dart';
import 'markdown_plus.dart';

/// 语言的圆点
class LangCircleDot extends StatelessWidget {
  const LangCircleDot(this.lang, {super.key, this.color});
  final String lang;
  final String? color;
  @override
  Widget build(BuildContext context) {
    if (lang.isEmpty) return const SizedBox.shrink();
    return ClipOval(
      child: Container(
        width: 10.0,
        height: 10.0,
        color: hexColorTo(color ?? languageColors[lang] ?? ''),
      ),
    );
  }
}

/// 仓库列表项目
class RepoListItem extends StatelessWidget {
  const RepoListItem(
    this.repo, {
    super.key,
    this.isPinStyle = false,
  });

  final Repository repo;
  final bool isPinStyle;

  String get _title =>
      isPinStyle ? repo.name : "${repo.owner?.login ?? ''}/${repo.name}";

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

              if (isPinStyle)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Remix.git_repository_line),
                ),
              LinkStyleButton(
                  onPressed: () {
                    RepoPage.createNewTab(context, repo);

                    //pushRoute(context, RouterTable.repo, extra: repo);
                  },
                  text: Text(
                    _title,
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  )),

              const SizedBox(width: 8.0),
              // 公开或者私有
              if (repo.isPrivate) const TagLabel.private(),
              if (isPinStyle && !repo.isPrivate) const TagLabel.public(),

              // 是否归档
              if (repo.archived)
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: TagLabel.archived()),

              const Spacer(),
              if (!isPinStyle)
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
          if (!isPinStyle && (repo.topics?.isNotEmpty ?? false))
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
              if (!isPinStyle && repo.license?.name != null) ...[
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
              if (!isPinStyle)
                // 当前打开的issue数，这里貌似包含pull requests的数量
                HyperlinkButton(
                  onPressed: () {},
                  child: IconText(
                      icon: Remix.issues_line,
                      // padding: padding,
                      text: Text(repo.openIssuesCount.toKiloString())),
                ),
              if (!isPinStyle)
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

/// 仓库列表
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
          height: 8), // Divider(size: 1, direction: Axis.horizontal),
    );
  }
}

/// 仓库路径导航指示条
class RepoBreadcrumbBar extends StatelessWidget {
  const RepoBreadcrumbBar({super.key, this.repo});

  final Repository? repo;

  @override
  Widget build(BuildContext context) {
    return Selector<PathModel, List<String>>(
      selector: (_, model) => model.segmentedPaths,
      builder: (context, segmentedPaths, __) {
        final r = repo ?? context.read<RepoModel>().repo;
        return BreadcrumbBar(
          items: segmentedPaths
              .map((e) => BreadcrumbItem(
                  label: Text(e.isEmpty ? r.name : e,
                      style: TextStyle(color: Colors.blue)),
                  value: e))
              .toList(),
          onItemPressed: (item) {
            final key = "/${item.value}";
            final model = context.read<PathModel>();
            final path = "/${model.path}";
            final pos = path.indexOf(key);
            if (pos != -1) {
              model.path = path.substring(1, pos + key.length);
            } else {
              model.path = "";
            }
          },
        );
      },
    );
  }
}

/// 内容视图
class RepoContentView extends StatelessWidget {
  const RepoContentView(this.file, {super.key});

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
      final filename = file.name ?? '';
      // 这里还要处理编码
      final body = utf8.decode(data);
      final ext = p.extension(filename).toLowerCase();
      if (ext == ".md" || ext == ".markdown") {
        return MarkdownBlockPlusDefaultAction(body);
      }
      return HighlightViewPlus(body, fileName: filename);
    } catch (e) {
      return Text("Error: $e");
    }
  }
}

/// 仓库目录列表
class RepoContentsListView extends StatelessWidget {
  const RepoContentsListView({
    super.key,
    this.path = "",
    this.ref,
    required this.onPathChange,
  });

  final String path;
  final String? ref;
  final ValueChanged<String> onPathChange;

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
      //trailing: const SizedBox.shrink(),
      onPressed: () {
        onPathChange.call(file.path ?? '');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return SizedBox(
      width: double.infinity,
      child: FutureBuilder(
        future: GithubCache.instance.repoContents(repo, path, ref: ref),
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
            return RepoContentView(contents.file!);
          }
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
