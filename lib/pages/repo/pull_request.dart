part of '../repo.dart';

class _PullRequestsList extends StatelessWidget {
  const _PullRequestsList(this.repo, this.isOpen);

  final QLRepository repo;
  final bool isOpen;

  void _update(BuildContext context, QLList<QLPullRequest> data) {
    if (isOpen) {
      context.curRepo.openPullRequestCount = data.totalCount;
    } else {
      context.read<_IssuesOrPullRequestsTabViewModel>().closedCount =
          data.totalCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WantKeepAlive(
        onInit: (context) {
          APIWrap.instance.repoPullRequests(repo,
              isOpen: isOpen, isMerged: !isOpen, onSecondUpdate: (value) {
            context.read<_IssueOrPullRequestListModel<QLPullRequest>>().items =
                value;
          }).then((data) {
            context.read<_IssueOrPullRequestListModel<QLPullRequest>>().items =
                data;
            _update(context, data);
          });
        },
        child: SelectorQLList<_IssueOrPullRequestListModel<QLPullRequest>,
            QLPullRequest>(
          selector: (_, model) => model.items,
          builder: (_, pulls, __) {
            return Card(
              padding: EdgeInsets.zero,
              child: ListViewRefresher<QLPullRequest>(
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
                  return APIWrap.instance.repoPullRequests(repo,
                      isOpen: isOpen,
                      isMerged: !isOpen,
                      nextCursor: pageInfo.endCursor);
                },
                onRefresh: () async {
                  final data = await APIWrap.instance.repoPullRequests(repo,
                      isOpen: isOpen, isMerged: !isOpen, force: true);
                  //????
                  _update(context, data);
                  return data;
                },
              ),
            );
          },
        ));
  }
}

class RepoPullRequestPage extends StatelessWidget {
  const RepoPullRequestPage(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return RepoIssuesOrPullRequestsCommon<QLPullRequest>(
      repo,
      openWidget: _PullRequestsList(repo, true),
      openIcon: const DefaultIcon.pullRequest(color: Colors.grey),
      closedWidget: _PullRequestsList(repo, false),
      closedIcon: const DefaultIcon.check(color: Colors.grey),
      isIssue: false,
    );
  }
}
