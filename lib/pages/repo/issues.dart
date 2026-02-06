part of '../repo.dart';

class _IssueItem extends StatelessWidget {
  const _IssueItem(this.issue);

  final QLIssue issue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          DefaultIcon.issues(color: issue.isOpen ? Colors.green : Colors.red),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Wrap(
          runSpacing: 6.0,
          children: [
            Text(
              issue.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (issue.labels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IssueLabels(labels: issue.labels),
              ),
          ],
        ),
      ),
      subtitle: Row(
        children: [
          if (issue.issueType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: IssueType(issue.issueType!),
            ),
          Text('#${issue.number}'),
          Text(' $dotChar ${issue.author?.login ?? ''}'),
          Text(' $dotChar 打开于 ${issue.createdAt?.toLabel ?? ''}')
        ],
      ),
      trailing: issue.commentsCount == 0
          ? null
          : SizedBox(
              width: 60,
              child: IconText(
                icon: DefaultIcons.comment,
                text: Text('${issue.commentsCount}'),
              ),
            ),
      onPressed: () {
        IssueDetailsPage.createNewTab(
            context, context.read<RepoModel>().repo, issue);
      },
    );
  }
}

class RepoIssuesPage extends StatelessWidget {
  const RepoIssuesPage(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return WantKeepAlive(
      onInit: (context) {
        APIWrap.instance.repoIssues(repo, onSecondUpdate: (value) {
          context.read<RepoModel>().issues = value;
        }).then((data) {
          context.read<RepoModel>().issues = data;
        });
      },
      child: SelectorQLList<RepoModel, QLIssue>(
          selector: (_, model) => model.issues,
          builder: (_, issues, __) {
            return Card(
              child: ListViewRefresher(
                initData: issues,
                separator: const Divider(
                    size: 1,
                    direction: Axis.horizontal,
                    style: DividerThemeData(
                        verticalMargin: EdgeInsets.zero,
                        horizontalMargin: EdgeInsets.zero)),
                padding: EdgeInsetsDirectional.only(
                  bottom: kPageDefaultVerticalPadding,
                  // start: PageHeader.horizontalPadding(context),
                  end: PageHeader.horizontalPadding(context),
                ),
                itemBuilder: (_, item, __) => _IssueItem(item),
                onLoading: (QLPageInfo? pageInfo) async {
                  if (pageInfo == null || !pageInfo.hasNextPage) {
                    return const QLList.empty();
                  }
                  return APIWrap.instance
                      .repoIssues(repo, nextCursor: pageInfo.endCursor);
                },
                onRefresh: () async {
                  // return const QLList.empty();
                  return APIWrap.instance.repoIssues(repo, force: true);
                },
              ),
            );
          }),
    );
  }
}
