import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/pages/issue_details.dart';
import 'package:gh_app/pages/pull_request_details.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

import 'default_icons.dart';
import 'markdown_plus.dart';

/// issues的标签
class IssueLabels extends StatelessWidget {
  const IssueLabels({super.key, required this.labels});

  final List<QLLabel> labels;

  static Color _getColor(Color color) {
    if ((0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue) /
            255.0 <
        0.66) return Colors.white;
    return Colors.black;
  }

  Widget _build(QLLabel label) {
    final color = hexColorTo(label.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label.name,
        style: TextStyle(color: _getColor(color), fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 5,
        runSpacing: 5,
        children: labels.map((e) => _build(e)).toList(),
      );
}

class _IssueLine extends StatelessWidget {
  const _IssueLine({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Container(
              color: const Color.fromARGB(255, 243, 243, 243),
              height: 30,
              width: 1,
              child: const Divider(direction: Axis.vertical)),
        ),
      ],
    );
  }
}

class IssueCommentItem extends StatelessWidget {
  const IssueCommentItem({
    super.key,
    this.item,
    required this.owner,
    required this.openAuthor,
    this.isFirst = false,
  });

  final QLIssueOrPullRequestOrCommentBase? item;
  final String? owner;
  final String? openAuthor;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: UserHeadImage(item?.author?.avatarUrl, imageSize: 40),
        ),
        Expanded(
          child: _IssueLine(
            child: Card(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                        '${item?.author?.login} 打开于 ${item?.createdAt?.toLabel}'),
                    const Spacer(),
                    if (!isFirst && (item?.author?.login.isNotEmpty ?? false))
                      TagLabel.other(item?.author?.login == owner
                          ? '所有者'
                          : item?.author?.login == openAuthor
                              ? '作者'
                              : ''),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
                if (item?.body.isNotEmpty ?? false)
                  MarkdownBlockPlus(item!.body),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

/// issues的评论显示
class IssuesCommentsView extends StatelessWidget {
  const IssuesCommentsView(
    this.data, {
    super.key,
    required this.repo,
  });

  final QLRepository repo;
  final QLIssueOrPullRequest data;

  @override
  Widget build(BuildContext context) {
    return APIFutureBuilder(
        noDataWidget: const SizedBox.shrink(),
        future: APIWrap.instance.repoIssueOrPullRequestComments(repo,
            number: data.number, isIssues: data is QLIssue),
        builder: (_, snapshot) {
          return Column(
            children: snapshot.data
                .map((e) => IssueCommentItem(
                      item: e,
                      owner: repo.owner?.login,
                      openAuthor: data.author?.login,
                    ))
                .toList(),
          );
        });
  }
}

/// issue类型标签，这个只取了默认的，他貌似还有个list类型的
class IssueTypeLabel extends StatelessWidget {
  const IssueTypeLabel(this.issueType, {super.key, this.fontSize});

  final QLIssueType issueType;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return TagLabel(
        color: issueType.color.color,
        text: Text(
          issueType.name,
          style: TextStyle(
            color: issueType.color.color,
            fontSize: fontSize ?? 11.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }
}

/// issue和pull request列表的显示项目
class IssueOrPullRequestListItem extends StatelessWidget {
  const IssueOrPullRequestListItem(this.item, {super.key});

  final QLIssueOrPullRequest item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: item is QLIssue
          ? DefaultIcon.issues(color: item.isOpen ? Colors.green : Colors.red)
          : DefaultIcon.pullRequest(
              color: item.isOpen ? Colors.green : Colors.red),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Wrap(
          runSpacing: 6.0,
          children: [
            Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (item.labels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IssueLabels(labels: item.labels),
              ),
          ],
        ),
      ),
      subtitle: Row(
        children: [
          if (item is QLIssue && (item as QLIssue).issueType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: IssueTypeLabel((item as QLIssue).issueType!),
            ),
          Text('#${item.number}'),
          Text(' $dotChar ${item.author?.login ?? ''}'),
          Text(' $dotChar 打开于 ${item.createdAt?.toLabel ?? ''}')
        ],
      ),
      trailing: item.commentsCount == 0
          ? null
          : SizedBox(
              width: 60,
              child: IconText(
                icon: DefaultIcons.comment,
                text: Text('${item.commentsCount}'),
              ),
            ),
      onPressed: () {
        if (item is QLIssue) {
          IssueDetailsPage.createNewTab(
              context, context.read<RepoModel>().repo, item as QLIssue);
        } else if (item is QLPullRequest) {
          PullRequestDetails.createNewTab(
              context, context.read<RepoModel>().repo, item as QLPullRequest);
        }
      },
    );
  }
}
