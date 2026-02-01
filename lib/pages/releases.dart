import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/markdown_plus.dart';
import 'package:gh_app/widgets/page.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class _TitleText extends StatelessWidget {
  const _TitleText(this.text);

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text ?? '',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton(this.title, this.link, {this.size});

  final String title;
  final String link;
  final int? size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: Colors.blue, fontWeight: FontWeight.w500);
    Widget child = Text(title, style: style);
    if (size != null && size! > 0) {
      child = Row(children: [
        child,
        const Spacer(),
        Text(size!.toSizeString(), style: style)
      ]);
    }

    return Tooltip(
      message: link,
      child: LinkStyleButton(
        text: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0), child: child),
        // 这里还可以添加一个替换规则，替换成镜像啥的
        onPressed: () => launchUrl(Uri.parse(link)),
      ),
    );
  }
}

class _AssetsPanel extends StatefulWidget {
  const _AssetsPanel(this.item, this.repo);

  final QLRelease item;
  final QLRepository repo;

  @override
  State<_AssetsPanel> createState() => _AssetsPanelState();
}

class _AssetsPanelState extends State<_AssetsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Expander(
      headerBackgroundColor: ButtonState.all(Colors.transparent),
      initiallyExpanded: false,
      header: Row(
        children: [
          const _TitleText('Assets '),
          TagLabel.other("${widget.item.assetsCount}", // 没有发现2个默认的url的啊
              //TagLabel.other("${2 + (item.assets?.length ?? 0)}",
              radius: 15.0,
              color: context.isDark ? Colors.white : Colors.black),
        ],
      ),
      content: !_expanded
          ? const SizedBox.shrink()
          : FutureBuilder(
              future:
                  APIWrap.instance.repoReleaseAssets(widget.repo, widget.item),
              builder: (_, snapshot) {
                if (!snapshotIsOk(snapshot, false, false)) {
                  return const Center(
                      child: SizedBox(
                          width: 20, height: 20, child: ProgressRing()));
                }
                if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                  return const Center(child: Text('没有数据'));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // if (item.zipballUrl != null)
                    //   _buildLinkButton('Source code (zip)', item.zipballUrl!),
                    // if (item.tarballUrl != null)
                    //   _buildLinkButton(
                    //       'Source code (tar.gz)', item.tarballUrl!),
                    // if (item.assets?.isNotEmpty ?? false)
                    ...snapshot.data!.data.map((e) =>
                        _LinkButton(e.name, e.downloadUrl, size: e.size)),
                  ],
                );
              },
            ),
      onStateChanged: (value) {
        setState(() {
          _expanded = value;
        });
      },
    );
  }
}

class _RepoReleaseItem extends StatelessWidget {
  const _RepoReleaseItem(this.item, {required this.repo});

  final QLRelease item;
  final QLRepository repo;

  Widget _buildLeftLabel(String? text, {IconData? icon, Widget? trailing}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: (text?.isNotEmpty ?? false)
            ? icon != null
                ? IconText(
                    iconSize: 18,
                    icon: icon,
                    text: Text(text ?? '', overflow: TextOverflow.ellipsis),
                    trailing: trailing)
                : Text(text ?? '', overflow: TextOverflow.ellipsis)
            : const SizedBox.shrink(),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          // width: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15.0),
              if (item.createdAt != null)
                _buildLeftLabel(
                    '${item.createdAt!.year}年${item.createdAt!.month}月${item.createdAt!.day}日'),
              //TODO: 这里实际为发布者的头像，但这里懒得弄了
              _buildLeftLabel(item.author?.name ?? item.author?.login,
                  icon: Remix.github_fill),
              _buildLeftLabel(item.tagName, icon: Remix.price_tag_2_line),
              //TODO: 这个后面图标其实应该根据状态显示，但是graphql貌似没发现相关的
              _buildLeftLabel(item.abbreviatedOid,
                  icon: Remix.git_commit_line,
                  trailing: Icon(Remix.verified_badge_line,
                      color: Colors.green, size: 18)),
            ],
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
            child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //if(item.isDraft)
              Row(
                children: [
                  _TitleText(item.name),
                  if (item.isPrerelease)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TagLabel.other('预览版', color: Colors.orange),
                    ),
                  if (item.isDraft)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TagLabel.other('草稿', color: Colors.yellow),
                    ),
                  //TODO: 这个要获取是否为最后一个，restapi貌似没有哈，得用graphql的才有
                  if (item.isLatest)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TagLabel.other('Latest', color: Colors.green),
                    ),
                ],
              ),

              if (item.description.isNotEmpty)
                MarkdownBlockPlus(
                  data: item.description,
                  onTap: (link) {
                    //TODO：这里要分析链接，如果是github的，就解析后跳转相应的
                    if (kDebugMode) {
                      print("点击了链接=$link");
                    }
                  },
                ),
              // item.assets
              const SizedBox(height: 10),
              if (item.assetsCount > 0) _AssetsPanel(item, repo),
            ],
          ),
        )),
      ],
    );
  }
}

class ReleasesPage extends StatelessWidget with PageMixin {
  const ReleasesPage({
    super.key,
    required this.repo,
  });

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: APIWrap.instance.repoReleases(repo),
        builder: (_, snapshot) {
          if (!snapshotIsOk(snapshot, false, false)) {
            return const Center(
              child: ProgressRing(),
            );
          }
          if (snapshot.hasError) {
            return errorDescription(snapshot.error);
          }
          final releases = snapshot.data ?? const QLList.empty();
          if (releases.isEmpty) {
            return const Center(
              child: Text('没有数据'),
            );
          }
          return ListView.separated(
              itemCount: releases.length,
              padding: EdgeInsetsDirectional.only(
                bottom: kPageDefaultVerticalPadding,
                // start: PageHeader.horizontalPadding(context),
                end: PageHeader.horizontalPadding(context),
              ),
              itemBuilder: (context, index) =>
                  _RepoReleaseItem(releases[index], repo: repo),
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 30));
        });
  }

  static void createNewTab(BuildContext context, QLRepository repo) {
    context.read<TabviewModel>().addTab(
          ReleasesPage(repo: repo),
          key: ValueKey("${RouterTable.release}/${repo.fullName}"),
          title: '${repo.fullName} Releases',
          icon: Remix.price_tag_3_line,
        );
  }
}
