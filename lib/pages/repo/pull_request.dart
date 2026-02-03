part of '../repo.dart';

class _PullRequestItem extends StatelessWidget {
  const _PullRequestItem(this.pull, {required this.repo});

  final QLPullRequest pull;
  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          DefaultIcon.issues(color: pull.isOpen ? Colors.green : Colors.red),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Text(
              pull.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (pull.labels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IssueLabels(labels: pull.labels),
              ),
          ],
        ),
      ),
      subtitle: Row(
        children: [
          Text('#${pull.number}'),
          Text(' $dotChar ${pull.author?.login ?? ''}'),
          Text(' $dotChar 打开于 ${pull.createdAt?.toLabel ?? ''}')
        ],
      ),
      trailing: pull.commentsCount == 0
          ? null
          : SizedBox(
              width: 60,
              child: IconText(
                icon: DefaultIcons.comment,
                text: Text('${pull.commentsCount}'),
              ),
            ),
      onPressed: () {
        PullRequestDetails.createNewTab(context, repo, pull);
      },
    );
  }
}

class RepoPullRequestPage extends StatelessWidget {
  const RepoPullRequestPage(this.repo, {super.key});

  final QLRepository repo;

  Future<QLList<QLPullRequest>> _onLoadData(QLPageInfo? pageInfo) async {
    if (pageInfo == null || !pageInfo.hasNextPage) return const QLList.empty();
    return APIWrap.instance
        .repoPullRequests(repo, nextCursor: pageInfo.endCursor);
  }

  @override
  Widget build(BuildContext context) {
    return APIFutureBuilder(
      future: APIWrap.instance.repoPullRequests(repo),
      builder: (context, snapshot) {
        return Card(
          child: ListViewRefresher(
            initData: snapshot,
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
            itemBuilder: (_, item, __) => _PullRequestItem(item, repo: repo),
            onLoading: _onLoadData,
          ),
        );

        // return Card(
        //   padding: EdgeInsets.zero,
        //   child: ListView.separated(
        //       itemCount: snapshot.length,
        //       itemBuilder: (_, index) =>
        //           _PullRequestItem(snapshot[index], repo: repo),
        //       separatorBuilder: (_, index) => const Divider(
        //             size: 1,
        //             direction: Axis.horizontal,
        //             style: DividerThemeData(
        //                 verticalMargin: EdgeInsets.zero,
        //                 horizontalMargin: EdgeInsets.zero),
        //           )),
        // );
      },
    );
  }
}
