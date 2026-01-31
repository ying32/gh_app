import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/widgets/markdown_plus.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class _RepoReleaseItem extends StatelessWidget {
  const _RepoReleaseItem(
    this.item, {
    this.isLast = false,
  });

  final Release item;
  final bool isLast;

  Widget _buildLinkButton(String title, String link, {int? size}) {
    final style = TextStyle(color: Colors.blue, fontWeight: FontWeight.w500);
    Widget child = Text(title, style: style);
    if (size != null && size > 0) {
      child = Row(children: [
        child,
        const Spacer(),
        Text(size.toSizeString(), style: style)
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

  Widget _buildLeftLabel(String? text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: (text?.isNotEmpty ?? false)
            ? Text(text ?? '')
            : const SizedBox.shrink(),
      );

  Widget _buildTitle(String? text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          text ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Column(
            children: [
              const SizedBox(height: 15.0),
              if (item.createdAt != null)
                _buildLeftLabel(
                    '${item.createdAt!.year}年${item.createdAt!.month}月${item.createdAt!.day}日'),
              _buildLeftLabel(item.author?.name ?? item.author?.login),
              _buildLeftLabel(item.tagName),
              _buildLeftLabel(item.targetCommitish),
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
                  _buildTitle(item.name),
                  if (item.isPrerelease ?? false)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TagLabel.other('预览版', color: Colors.orange),
                    ),
                  if (item.isDraft ?? false)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TagLabel.other('草稿', color: Colors.yellow),
                    ),
                  //TODO: 这个要获取是否为最后一个，restapi貌似没有哈，得用graphql的才有
                  if (isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TagLabel.other('Latest', color: Colors.green),
                    ),
                ],
              ),
              if (item.description?.isNotEmpty ?? false)
                Text(item.description ?? ''),
              if (item.body?.isNotEmpty ?? false)
                MarkdownBlockPlus(
                  data: item.body!,
                  onTap: (link) {
                    //TODO：这里要分析链接，如果是github的，就解析后跳转相应的
                    print("点击了链接=$link");
                  },
                ),
              // item.assets
              const SizedBox(height: 10),
              Expander(
                header: Row(
                  children: [
                    _buildTitle('Assets '),
                    TagLabel.other("${2 + (item.assets?.length ?? 0)}",
                        radius: 15.0),
                  ],
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.zipballUrl != null)
                      _buildLinkButton('Source code (zip)', item.zipballUrl!),
                    if (item.tarballUrl != null)
                      _buildLinkButton(
                          'Source code (tar.gz)', item.tarballUrl!),
                    if (item.assets?.isNotEmpty ?? false)
                      ...item.assets!.map((e) => _buildLinkButton(
                          '${e.name}', e.browserDownloadUrl!,
                          size: e.size)),
                  ],
                ),
              )
            ],
          ),
        )),
      ],
    );
  }
}

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
        itemBuilder: (context, index) =>
            _RepoReleaseItem(releases[index], isLast: index == 0),
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
          icon: Remix.price_tag_3_line,
        );
  }
}
