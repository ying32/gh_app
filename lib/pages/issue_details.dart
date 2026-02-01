import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/issues_widgets.dart';
import 'package:gh_app/widgets/page.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

class IssueDetailsPage extends StatelessWidget with PageMixin {
  const IssueDetailsPage(
    this.issue, {
    super.key,
    required this.repo,
  });

  final QLRepository repo;
  final QLIssue issue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: kPageDefaultVerticalPadding,
        // start: PageHeader.horizontalPadding(context),
        end: PageHeader.horizontalPadding(context),
      ),
      child: Card(
        child: ListView(
          children: [
            Wrap(
              runAlignment: WrapAlignment.start,
              runSpacing: 10,
              spacing: 10,
              children: [
                Text(
                  issue.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  '# ${issue.number}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 20),
                ),
                Row(
                  children: [
                    TagLabel(
                        opacity: 1,
                        radius: 15,
                        text: Row(
                          children: [
                            const Icon(Remix.issues_line, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(issue.isOpen ? '打开' : '关闭',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        color: issue.isOpen
                            ? Colors.green.lighter
                            : Colors.red.lighter),
                    const Spacer(),
                    LinkAction(
                      icon: const Icon(FluentIcons.open_source, size: 18),
                      link:
                          "https://github.com/${repo.fullName}/issues/${issue.number}",
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
                          item: issue,
                          owner: repo.owner?.login,
                          openAuthor: issue.author?.login,
                          isFirst: true),
                      IssuesCommentsView(issue, repo: repo),
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
                      if (issue.labels.isNotEmpty)
                        IssueLabels(
                            labels: (issue as QLIssueOrPullRequest).labels)
                      else
                        const Text('No labels'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
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

  /// 创建一个仓库页
  static void createNewTab(
      BuildContext context, QLRepository repo, QLIssue issue) {
    context.read<TabviewModel>().addTab(
          IssueDetailsPage(issue, repo: repo),
          key: ValueKey(
              "${RouterTable.issues}/${repo.fullName}/${issue.number}"),
          title: "${repo.fullName} issue ${issue.number}",
        );
  }
}
