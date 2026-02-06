part of '../repo.dart';

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
                itemBuilder: (_, item, __) => IssueOrPullRequestListItem(item),
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
