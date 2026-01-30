part of '../repo.dart';

class _PullRequestItem extends StatelessWidget {
  const _PullRequestItem(this.data, {super.key});

  final PullRequest data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Remix.issues_line,
        color: data.state == "open" ? Colors.green : Colors.red,
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Text(
              data.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (data.labels != null && data.labels!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IssueLabels(labels: data.labels!),
              ),
          ],
        ),
      ),
      subtitle: Row(
        children: [
          Text('#${data.number}'),
          Text(' · ${data.user?.login ?? ''}'),
          Text(' · opened on ${timeToLabel(data.createdAt)}')
        ],
      ),
      trailing: data.commentsCount == 0
          ? null
          : SizedBox(
              width: 60,
              child: IconText(
                icon: Remix.chat_2_line,
                text: Text('${data.commentsCount}'),
              ),
            ),
      onPressed: () {
        //
      },
    );
  }
}

class RepoPullRequestPage extends StatelessWidget {
  const RepoPullRequestPage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GithubCache.instance.repoPullRequests(repo),
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
              itemBuilder: (_, index) =>
                  _PullRequestItem(snapshot.data![index]),
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
