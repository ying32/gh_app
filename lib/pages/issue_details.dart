import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:provider/provider.dart';

import 'issue_or_pull_request_details.dart';

class IssueDetailsPage extends StatelessWidget {
  const IssueDetailsPage(
    this.issue, {
    super.key,
    required this.repo,
  });

  final QLRepository repo;
  final QLIssue issue;

  @override
  Widget build(BuildContext context) =>
      IssueOrPullRequestDetailsPage(issue, repo: repo);

  /// 创建一个仓库页
  static void createNewTab(
      BuildContext context, QLRepository repo, QLIssue issue) {
    context.read<TabViewModel>().addTab(
          IssueDetailsPage(issue, repo: repo),
          key: ValueKey(
              "${RouterTable.issues}/${repo.fullName}/${issue.number}"),
          title: "问题 #${issue.number} - ${repo.fullName}",
        );
  }
}
