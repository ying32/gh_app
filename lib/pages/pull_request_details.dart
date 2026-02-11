import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:provider/provider.dart';

import 'issue_or_pull_request_details.dart';

class PullRequestDetailsPage extends StatelessWidget {
  const PullRequestDetailsPage(
    this.pull, {
    super.key,
    required this.repo,
  });

  final QLRepository repo;
  final QLPullRequest pull;

  @override
  Widget build(BuildContext context) =>
      IssueOrPullRequestDetailsPage(pull, repo: repo);

  /// 创建一个仓库页
  static void createNewTab(
      BuildContext context, QLRepository repo, QLPullRequest pull) {
    context.read<TabViewModel>().addTab(
          PullRequestDetailsPage(pull, repo: repo),
          key: ValueKey("${RouterTable.pulls}/${repo.fullName}/${pull.number}"),
          title: "合并请求 #${pull.number} - ${repo.fullName}",
        );
  }
}
