import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/issues_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';

class IssueOrPullRequestDetailsPage extends StatelessWidget {
  const IssueOrPullRequestDetailsPage(
    this.item, {
    super.key,
    required this.repo,
  });

  final QLRepository repo;
  final QLIssueOrPullRequest item;

  bool get _isIssue => item is QLIssue;
  QLIssue get _issue => (item as QLIssue);
  QLPullRequest get _pull => (item as QLPullRequest);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: kPageDefaultVerticalPadding / 2.0,
        // start: PageHeader.horizontalPadding(context),
        //end: PageHeader.horizontalPadding(context),
        // end: kPageDefaultVerticalPadding / 2.0,
      ),
      child: Card(
        child: ListView(
          children: [
            Wrap(
              runAlignment: WrapAlignment.start,
              runSpacing: 10,
              spacing: 10,
              children: [
                // SelectableText(
                //   issue.title,
                //   style: const TextStyle(
                //       fontWeight: FontWeight.bold, fontSize: 20),
                // ),
                // SelectableText(
                //   '# ${issue.number}',
                //   style: const TextStyle(
                //       fontWeight: FontWeight.w400, fontSize: 20),
                // ),
                SelectableText.rich(
                  TextSpan(
                      text: item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 22),
                      children: [
                        TextSpan(
                          text: ' # ${item.number}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 20),
                        )
                      ]),
                  selectionHeightStyle: ui.BoxHeightStyle.max,
                  // style: TextStyle(fontFamily: appTheme.fontFamily),
                ),
                Row(
                  children: [
                    TagLabel(
                        opacity: 1,
                        radius: 15,
                        text: Row(
                          children: [
                            const DefaultIcon.issues(color: Colors.white),
                            const SizedBox(width: 5),
                            Text(item.isOpen ? '打开' : '关闭',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        color: item.isOpen
                            ? Colors.green.lighter
                            : Colors.red.lighter),
                    if (_isIssue && _issue.issueType != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: IssueTypeLabel(_issue.issueType!, fontSize: 14),
                      ),
                    //TODO: 这里还差一个合并的标签
                    const Spacer(),
                    IconLinkButton.linkSource(
                      "$githubUrl/${repo.fullName}/${_isIssue ? 'issues' : 'pull'}/${item.number}",
                      //message: '在浏览器中打开',
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 10),
            const Divider(direction: Axis.horizontal),
            // 首个
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      IssueCommentItem(
                          item: item,
                          owner: repo.owner.login,
                          openAuthor: item.author?.login,
                          isFirst: true),
                      // 余下的项目，需要请求
                      IssuesCommentsView(item, repo: repo),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assignees'),
                      const SizedBox(height: 10),
                      const Text('No one assigned'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      //
                      const Text('标签'),
                      const SizedBox(height: 10),
                      if (item.labels.isNotEmpty)
                        IssueLabels(labels: item.labels)
                      else
                        const Text('No labels'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      if (_isIssue && _issue.issueType != null) ...[
                        const Text('类型'),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: IssueTypeLabel(_issue.issueType!),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(),
                        ),
                      ],
                      //
                      const Text('Projects'),
                      const SizedBox(height: 10),
                      const Text('No projects'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      //
                      const Text('Milestone'),
                      const SizedBox(height: 10),
                      const Text('No milestone'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      //
                      const Text('Relationships'),
                      const SizedBox(height: 10),
                      const Text('None yet'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      //
                      const Text('Development'),
                      const SizedBox(height: 10),
                      const Text('No branches or pull requests'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      //
                      const Text('Participants'),
                      const SizedBox(height: 10),
                      const Text('参与者的头像'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                    ],
                  ),
                )
              ],
            ),

            // 列表
          ],
        ),
      ),
    );
  }
}
