import 'dart:math' as math;

import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/pages/repo.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'highlight_plus.dart';
import 'markdown_plus.dart';

class RepoTopics extends StatelessWidget {
  const RepoTopics(this.topics, {super.key});

  final List<String> topics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
        runSpacing: 3.0,
        spacing: 1.0,
        children: topics
            .map((e) => LinkButton(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(10),
                  text: TagLabel.other(e, color: Colors.blue),
                  onPressed: () {
                    launchUrl(Uri.parse('$githubTopicsUrl/$e'));
                  },
                ))
            .toList());
  }
}

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
                  onPressed: () => RepoPage.createNewTab(context, repo),
                  text: Text(
                    _title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.0),
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
          // fork信息
          if (repo.isFork && repo.parent != null) RepoItemForkInfo(repo),
          // 描述
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SelectableText(
              repo.description,
              style: TextStyle(color: context.textColor200),
            ),
          ),

          if (!isPinStyle && (repo.topics?.isNotEmpty ?? false))
            // tags
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: RepoTopics(repo.topics!)),

          //Text('${item.tagsUrl}'),

          Row(
            children: [
              // 语言的一个圆，颜色还要待弄下哈
              LangCircleDot(repo.primaryLanguage),

              // 语言
              Padding(
                  padding: padding,
                  child: Text(repo.primaryLanguage.name,
                      style: TextStyle(color: context.textColor200))),
              // 许可协议
              if (!isPinStyle && repo.license.name.isNotEmpty) ...[
                IconText(
                  icon: DefaultIcons.license,
                  padding: padding,
                  iconColor: context.textColor200,
                  text: Text(repo.license.name,
                      style: TextStyle(color: context.textColor200)),
                ),
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
                      style: TextStyle(color: context.textColor200)),
                ),
            ],
          ),
        ],
        // ),
      ),
    );
  }
}

class RepoItemForkInfo extends StatelessWidget {
  const RepoItemForkInfo(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          const Text('forked 自 '),
          LinkButton(
              text: Text('${repo.parent?.fullName}'),
              onPressed: () {
                RepoPage.createNewTab(context, repo.parent!);
              })
        ],
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
    this.onRefresh,
    this.onLoading,
  });

  final QLList<QLRepository> repos;
  final bool showOpenIssues;
  final AsyncQLListGetter<QLRepository>? onRefresh;
  final AsyncNextQLListGetter<QLRepository>? onLoading;

  @override
  Widget build(BuildContext context) {
    if (repos.isEmpty) return const SizedBox.shrink();
    return ListViewRefresher(
      initData: repos,
      separator: const SizedBox(height: 8),
      padding: EdgeInsetsDirectional.only(
        bottom: kPageDefaultVerticalPadding,
        // start: PageHeader.horizontalPadding(context),
        end: PageHeader.horizontalPadding(context),
      ),
      itemBuilder: (context, item, index) =>
          RepoListItem(item, showOpenIssues: showOpenIssues),
      onLoading: onLoading,
      onRefresh: onRefresh,
    );
  }
}

/// 仓库路径导航指示条
class RepoBreadcrumbBar extends StatelessWidget {
  const RepoBreadcrumbBar({super.key, this.repo});

  final QLRepository? repo;

  @override
  Widget build(BuildContext context) {
    //return Consumer<RepoModel>(
    return Selector<RepoModel, List<String>>(
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
            final model = context.read<RepoModel>();
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
class RepoFileContentView extends StatelessWidget {
  const RepoFileContentView(
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
        return MarkdownBlockPlus(body);
      }
      return HighlightViewPlus(body, fileName: filename);
    } catch (e) {
      return Text("Error: $e");
    }
  }
}

/// 仓库目录列表
class RepoTreeEntriesView extends StatelessWidget {
  const RepoTreeEntriesView({
    super.key,
  });

  Widget _buildItem(BuildContext context, QLTree file) {
    return ListTile(
      leading: SizedBox(
        width: 24,
        child: file.isFile
            ? FileIcon(file.name, size: 24)
            : DefaultIcon.folder(color: Colors.blue.lighter),
      ),
      title: Text(file.name),
      onPressed: () {
        context.read<RepoModel>().path = file.path;
      },
    );
  }

  // 构建目录，这个还可以再优化的，不使用Column，暂时先这样吧
  Widget _buildTree(BuildContext context, List<QLTree> entries) => Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...entries.where((e) => e.isDir).map((e) => _buildItem(context, e)),
            ...entries
                .where((e) => e.isFile)
                .map((e) => _buildItem(context, e)),
          ],
        ),
      );

  Widget _buildContent(
      BuildContext context, QLObject object, QLRepository repo) {
    // 如果数据是文件，则显示内容
    if (object.isFile) {
      if (kDebugMode) {
        print("file isBinary =${object.blob?.isBinary}");
      }
      // blob不为null时
      if (object.blob != null && object.blob!.text != null) {
        return Card(
          child: RepoFileContentView(
            object.blob!,
            filename: p.basename(context.read<RepoModel>().path),
          ),
        );
      }
      //TODO: 这里待完善
      return const Text('还没做内容的哈');
      //return RepoContentView(contents.file!);
    }
    if (object.entries == null) {
      return const SizedBox.shrink();
    }
    // 返回目录结构
    return _buildTree(context, object.entries!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // 监视文件对象改变
        Selector<RepoModel, QLObject?>(
            selector: (_, model) => model.object,
            builder: (_, object, __) {
              if (object == null) {
                return SizedBox(
                    height: MediaQuery.of(context).size.height / 2,
                    child: const Center(child: ProgressRing()));
              }
              return _buildContent(
                  context, object, context.read<RepoModel>().repo);
            }),
        // readme
        const SizedBox(height: 8.0),
        const RepoReadMe(),
      ],
    );
  }
}
