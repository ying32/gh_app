part of '../repo.dart';

class _PullRequestItem extends StatelessWidget {
  const _PullRequestItem(this.pull, {required this.repo});

  final QLPullRequest pull;
  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Remix.issues_line,
        color: pull.isOpen ? Colors.green : Colors.red,
      ),
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
                icon: Remix.chat_2_line,
                text: Text('${pull.commentsCount}'),
              ),
            ),
      onPressed: () {
        PullRequestDetails.createNewTab(context, repo, pull);
      },
    );
  }
}

class RepoPullRequestPage extends StatelessWidget with PageMixin {
  const RepoPullRequestPage(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: APIWrap.instance.repoPullRequests(repo),
      builder: (context, snapshot) {
        if (!snapshotIsOk(snapshot, false, false)) {
          return const Center(child: ProgressRing());
        }
        if (snapshot.hasError) {
          return errorDescription(snapshot.error);
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(child: Text('没有数据'));
        }
        return Card(
          padding: EdgeInsets.zero,
          child: ListView.separated(
              itemCount: snapshot.data!.length,
              itemBuilder: (_, index) =>
                  _PullRequestItem(snapshot.data![index], repo: repo),
              separatorBuilder: (_, index) => const Divider(
                    size: 1,
                    direction: Axis.horizontal,
                    style: DividerThemeData(
                        verticalMargin: EdgeInsets.zero,
                        horizontalMargin: EdgeInsets.zero),
                  )),
        );
      },
    );
  }
}
