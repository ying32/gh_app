part of '../repo.dart';

class _IssueItem extends StatelessWidget {
  const _IssueItem(this.issue);

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Remix.issues_line,
        color: issue.state == "open" ? Colors.green : Colors.red,
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Wrap(
          runSpacing: 6.0,
          children: [
            Text(
              issue.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IssueLabels(labels: issue.labels),
            ),
          ],
        ),
      ),
      subtitle: Row(
        children: [
          Text('#${issue.number}'),
          Text(' · ${issue.user?.login ?? ''}'),
          Text(' · 打开于 ${issue.createdAt?.toLabel ?? ''}')
        ],
      ),
      trailing: issue.commentsCount == 0
          ? null
          : SizedBox(
              width: 60,
              child: IconText(
                icon: Remix.chat_2_line,
                text: Text('${issue.commentsCount}'),
              ),
            ),
      onPressed: () {
        //
      },
    );
  }
}

class RepoIssuesPage extends StatelessWidget {
  const RepoIssuesPage(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: APIWrap.instance.repoIssues(repo),
      builder: (context, snapshot) {
        if (!snapshotIsOk(snapshot, false, false)) {
          return const Center(child: ProgressRing());
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(child: Text('没有数据'));
        }
        return Card(
          padding: EdgeInsets.zero,
          child: ListView.separated(
              itemCount: snapshot.data!.length,
              itemBuilder: (_, index) => _IssueItem(snapshot.data![index]),
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
