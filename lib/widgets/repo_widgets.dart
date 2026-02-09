import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/pages/repo.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class RepoTopics extends StatelessWidget {
  const RepoTopics(this.topics, {super.key});

  final QLList<QLTopic> topics;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();
    return Wrap(
        runSpacing: 8.0,
        spacing: 5.0,
        children: topics
            .map(
              // (e) => TagLabel.other(e.name,
              //     color: Colors.blue, fontSize: 12, radius: 10.0),
              (e) => MaterialStyleButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(10),
                splashColor: Colors.blue.withOpacity(0.1),
                child: TagLabel.other(e.name,
                    color: Colors.blue, fontSize: 12, radius: 10.0),
                onPressed: () {
                  launchUrl(Uri.parse('$githubTopicsUrl/$e'));
                },
              ),
            )
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
    this.expanded = false,
  });

  final QLRepository repo;
  final bool isPinStyle;
  final bool showOpenIssues;

  final bool expanded;

  String get _title => isPinStyle ? repo.name : repo.fullName;

  Widget _buildDescription(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SelectableText(
          repo.description,
          style: TextStyle(
              color: context.textColor200, overflow: TextOverflow.ellipsis),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 6);
    //final theme = FluentTheme.of(context);
    return Card(
      // child: DefaultTextStyle(
      //   style: TextStyle(color: appTheme.color.lightest),
      child: Column(
        mainAxisSize: expanded
            ? MainAxisSize.max
            : MainAxisSize.min, // 这里不能设置为min，否则Expanded不能使用，但是
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPinStyle)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: DefaultIcon.repository(),
                ),
              if (!isPinStyle && repo.owner.avatarUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ActorHeadImage(repo.owner, imageSize: 35),
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
          if (expanded)
            Expanded(child: _buildDescription(context))
          else
            _buildDescription(context),
          if (!isPinStyle && (repo.repositoryTopics?.isNotEmpty ?? false))
            // tags
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: RepoTopics(repo.repositoryTopics!)),

          //Text('${item.tagsUrl}'),
          //const Spacer(),

          Row(
            children: [
              // 语言的一个圆，颜色还要待弄下哈
              if (repo.primaryLanguage != null)
                LangCircleDot(repo.primaryLanguage!),

              // 语言
              if (repo.primaryLanguage != null)
                Padding(
                    padding: padding,
                    child: Text(repo.primaryLanguage!.name,
                        style: TextStyle(color: context.textColor200))),
              // 许可协议
              if (!isPinStyle &&
                  (repo.licenseInfo?.name.isNotEmpty ?? false)) ...[
                IconText(
                  icon: DefaultIcons.license,
                  padding: padding,
                  iconColor: context.textColor200,
                  text: Text(repo.licenseInfo!.name,
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
    const style = TextStyle(fontSize: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          const Text('派生自 ', style: style),
          LinkButton(
              text: Text('${repo.parent?.fullName}', style: style),
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
    this.padding,
  });

  final QLList<QLRepository> repos;
  final bool showOpenIssues;
  final AsyncQLListGetter<QLRepository>? onRefresh;
  final AsyncNextQLListGetter<QLRepository>? onLoading;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (repos.isEmpty) return const SizedBox.shrink();
    return ListViewRefresher(
      initData: repos,
      separator: const SizedBox(height: 8),
      padding: padding,
      itemBuilder: (context, item, index) =>
          RepoListItem(item, showOpenIssues: showOpenIssues),
      onLoading: onLoading,
      onRefresh: onRefresh,
    );
  }
}
