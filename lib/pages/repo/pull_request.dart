part of '../repo.dart';

class RepoPullRequestPage extends StatelessWidget {
  const RepoPullRequestPage(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return WantKeepAlive(
        onInit: (context) {
          APIWrap.instance.repoPullRequests(repo, onSecondUpdate: (value) {
            context.read<RepoModel>().pullRequests = value;
          }).then((data) {
            context.read<RepoModel>().pullRequests = data;
          });
        },
        child: SelectorQLList<RepoModel, QLPullRequest>(
          selector: (_, model) => model.pullRequests,
          builder: (_, pulls, __) {
            return Card(
              padding: EdgeInsets.zero,
              child: ListViewRefresher(
                initData: pulls,
                separator: const Divider(
                    size: 1,
                    direction: Axis.horizontal,
                    style: DividerThemeData(
                        verticalMargin: EdgeInsets.zero,
                        horizontalMargin: EdgeInsets.zero)),
                itemBuilder: (_, item, __) => IssueOrPullRequestListItem(item),
                onLoading: (QLPageInfo? pageInfo) async {
                  if (pageInfo == null || !pageInfo.hasNextPage) {
                    return const QLList();
                  }
                  return APIWrap.instance
                      .repoPullRequests(repo, nextCursor: pageInfo.endCursor);
                },
                onRefresh: () async {
                  // return const QLList.empty();
                  return APIWrap.instance.repoPullRequests(repo, force: true);
                },
              ),
            );
          },
        ));
  }
}
