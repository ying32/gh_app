import 'dart:math' as math;

import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/pages/repo.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'highlight_plus.dart';
import 'markdown_plus.dart';

/// 语言的圆点
class LangCircleDot extends StatelessWidget {
  const LangCircleDot(this.lang, {super.key});
  final QLLanguage lang;

  @override
  Widget build(BuildContext context) {
    if (lang.name.isEmpty) return const SizedBox.shrink();
    return ClipOval(
      child: Container(
        width: 10.0,
        height: 10.0,
        color: hexColorTo(lang.color),
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
    this.showOpenIssues = true,
  });

  final QLRepository repo;
  final bool isPinStyle;
  final bool showOpenIssues;

  String get _title => isPinStyle ? repo.name : repo.fullName;

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
                  child: DefaultIcon.repository(),
                ),
              if (!isPinStyle && repo.owner?.avatarUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: UserHeadImage(repo.owner!.avatarUrl, imageSize: 35),
                ),
              LinkButton(
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
              if (repo.isArchived)
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: TagLabel.archived()),

              const Spacer(),
              if (!isPinStyle) IconLinkButton.linkSource(repo.url),
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
              LangCircleDot(repo.primaryLanguage),

              // 语言
              Padding(
                  padding: padding,
                  child: Text(repo.primaryLanguage.name,
                      style: TextStyle(color: appTheme.color.lightest))),
              // 授权协议
              if (!isPinStyle && repo.license.name.isNotEmpty) ...[
                IconText(
                    icon: DefaultIcons.license,
                    padding: padding,
                    iconColor: appTheme.color.lightest,
                    text: Text(repo.license.name,
                        style: TextStyle(color: appTheme.color.lightest))),
              ],
              // fork数
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: DefaultIcons.fork,
                    // padding: padding,
                    text: Text(repo.forksCount.toKiloString())),
              ),
              // 关注数
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: DefaultIcons.star,
                    // padding: padding,
                    text: Text(repo.stargazersCount.toKiloString())),
              ),
              if (!isPinStyle && showOpenIssues)
                // 当前打开的issue数，这里貌似包含pull requests的数量
                HyperlinkButton(
                  onPressed: () {},
                  child: IconText(
                      icon: DefaultIcons.issues,
                      // padding: padding,
                      text: Text(repo.openIssuesCount.toKiloString())),
                ),
              if (!isPinStyle)
                // 最后更新时间
                Padding(
                  padding: padding,
                  child: Text(repo.pushedAt?.toLabel ?? '',
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
    this.showOpenIssues = true,
  });

  final QLList<QLRepository> repos;
  final bool showOpenIssues;

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
        return RepoListItem(repo, showOpenIssues: showOpenIssues);
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: 8), // Divider(size: 1, direction: Axis.horizontal),
    );
  }
}

/// 仓库路径导航指示条
class RepoBreadcrumbBar extends StatelessWidget {
  const RepoBreadcrumbBar({super.key, this.repo});

  final QLRepository? repo;

  @override
  Widget build(BuildContext context) {
    return Consumer<PathModel>(
      //selector: (_, model) => model.segmentedPaths,
      builder: (context, model, __) {
        final r = repo ?? context.read<RepoModel>().repo;
        return BreadcrumbBar(
          items: model.segmentedPaths
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
  const RepoContentView(
    this.file, {
    super.key,
    required this.filename,
  });

  final QLBlob file;
  final String filename;

  bool get _canPreview => file.byteSize <= 1024 * 1024 * 1;

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
      if (file.isBinary) {
        return const Center(child: Text('<...还没做预览二进制文件的功能...>'));
        // 解码数据
        // final data = base64Decode(file.content!.replaceAll("\n", ""));
        // if (file.isBinary && _isImage(data)) {
        //   return Image.memory(data);
        // }
      }

      // 这里还要处理编码
      final body = file.text ?? '';

      /// utf8数据  //utf8.decode(data);
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

  Widget _buildItem(QLTree file) {
    return ListTile(
      leading: SizedBox(
        width: 24,
        child: file.isFile
            ? FileIcon(file.name, size: 24)
            : DefaultIcon.folder(color: Colors.blue.lighter),
      ),
      title: Text(file.name),
      //trailing: const SizedBox.shrink(),
      onPressed: () {
        onPathChange.call(file.path);
      },
    );
  }

  QLTree _matchReadMeFile(QLObject object, RegExp regex) {
    return object.entries!.firstWhere((e) => regex.firstMatch(e.name) != null,
        orElse: () => const QLTree());
  }

  String _getReadMeFile(BuildContext context, QLObject object) {
    if (object.isFile) return '';
    // 优先匹配本地化的
    var tree = _matchReadMeFile(
        object,
        RegExp(
            r'README[\.|-|_]?' +
                Localizations.localeOf(context).languageCode +
                r'[\s\S]*?\.?(?:md|txt)',
            caseSensitive: false));
    if (tree.name.isNotEmpty) {
      return tree.name;
    }
    // 没有则匹配默认的
    tree = _matchReadMeFile(object,
        RegExp(r'README[\.|-|_]?[\s\S]*?\.?(?:md|txt)', caseSensitive: false));
    if (tree.name.isNotEmpty) {
      return tree.name;
    }
    return '';
  }

  // 构建目录，这个还可以再优化的，不使用Column，暂时先这样吧
  Widget _buildTree(List<QLTree> entries) => Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...entries.where((e) => e.isDir).map((e) => _buildItem(e)),
            ...entries.where((e) => e.isFile).map((e) => _buildItem(e)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return SizedBox(
      width: double.infinity,
      child: APIFutureBuilder(
        future: APIWrap.instance.repoContents(repo, path, ref: ref),
        builder: (_, object) {
          // 如果数据是文件，则显示内容
          if (object!.isFile) {
            if (kDebugMode) {
              print("file isBinary =${object.blob?.isBinary}");
            }
            // blob不为null时
            if (object.blob != null && object.blob!.text != null) {
              return RepoContentView(
                object.blob!,
                filename: p.basename(path),
              );
            }
            //TODO: 这里待完善
            return const Text('还没做内容的哈');
            //return RepoContentView(contents.file!);
          }
          if (object.entries == null) {
            return const SizedBox.shrink();
          }
          // 找readme文件，仅限根目录下，其实按情况其它的目录也可以查找下。
          final readmeFile =
              path.isEmpty ? _getReadMeFile(context, object) : '';
          // 返回目录结构
          return Column(
            children: [
              _buildTree(object.entries!),
              const SizedBox(height: 10.0),
              if (readmeFile.isNotEmpty)
                RepoReadMe(repo: repo, ref: ref, filename: readmeFile),
            ],
          );
        },
      ),
    );
  }
}
