import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';

import 'dialogs.dart';
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
                // 优先显示html格式的
                //TODO: 发现个问题，使用HTML的，代码高亮没有了，如果使用markdown的HTML代码他又没解析，还得另想办法
                if (item?.bodyHTML?.isNotEmpty ?? false)
                  SelectionArea(
                    child: HtmlWidget(
                      item!.bodyHTML!,
                      baseUrl: Uri.tryParse(githubUrl),
                      onTapUrl: (link) {
                        onDefaultLinkAction(context, link);
                        return true;
                      },
                    ),
                  )
                else if (item?.body.isNotEmpty ?? false)
                  MarkdownBlockPlus(data: item!.body),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

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

class IssueType extends StatelessWidget {
  const IssueType(this.issueType, {super.key, this.fontSize});

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
