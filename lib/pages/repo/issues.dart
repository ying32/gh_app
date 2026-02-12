part of '../repo.dart';

class _IssuesList extends StatelessWidget {
  const _IssuesList(this.repo, this.isOpen);

  final QLRepository repo;
  final bool isOpen;

  void _update(BuildContext context, QLList<QLIssue> data) {
    if (isOpen) {
      context.curRepo.openIssueCount = data.totalCount;
    } else {
      context.read<_IssuesOrPullRequestsTabViewModel>().closedCount =
          data.totalCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WantKeepAlive(
      onInit: (context) {
        APIWrap.instance.repoIssues(repo, isOpen: isOpen,
            onSecondUpdate: (value) {
          context.read<_IssueOrPullRequestListModel<QLIssue>>().items = value;
        }).then((data) {
          context.read<_IssueOrPullRequestListModel<QLIssue>>().items = data;
          _update(context, data);
        });
      },
      child: SelectorQLList<_IssueOrPullRequestListModel<QLIssue>, QLIssue>(
          selector: (_, model) => model.items,
          builder: (_, issues, __) {
            return Card(
              padding: EdgeInsets.zero,
              child: ListViewRefresher<QLIssue>(
                initData: issues,
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
                  return APIWrap.instance.repoIssues(repo,
                      isOpen: isOpen, nextCursor: pageInfo.endCursor);
                },
                onRefresh: () async {
                  final data = await APIWrap.instance
                      .repoIssues(repo, isOpen: isOpen, force: true);
                  //????
                  _update(context, data);
                  return data;
                },
              ),
            );
          }),
    );
  }
}

class RepoIssuesPage extends StatelessWidget {
  const RepoIssuesPage(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return RepoIssuesOrPullRequestsCommon<QLIssue>(
      repo,
      openWidget: _IssuesList(repo, true),
      openIcon: const DefaultIcon.issues(color: Colors.grey),
      closedWidget: _IssuesList(repo, false),
      closedIcon: const DefaultIcon.check(color: Colors.grey),
      isIssue: true,
    );
  }
}
