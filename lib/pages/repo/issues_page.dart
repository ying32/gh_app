import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';

class IssueLabelWidget extends StatelessWidget {
  const IssueLabelWidget({super.key, required this.label});

  final IssueLabel label;

  static Color _getColor(Color color) {
    if ((0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue) /
            255.0 <
        0.66) return Colors.white;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final color = hexColorTo(label.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label.name,
        style: TextStyle(color: _getColor(color), fontSize: 11),
      ),
    );
  }
}

class IssueLabels extends StatelessWidget {
  const IssueLabels({super.key, required this.labels});

  final List<IssueLabel> labels;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 5,
        runSpacing: 5,
        children: labels.map((e) => IssueLabelWidget(label: e)).toList(),
      );
}

class IssuesPage extends StatelessWidget {
  const IssuesPage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GithubCache.instance.repoIssues(repo),
      builder: (context, snapshot) {
        if (!snapshotIsOk(snapshot, false, false)) {
          return const Center(child: ProgressRing());
        }
        return Card(
          child: ListView(
            children: snapshot.data?.map((e) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: appTheme.color)),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Remix.issues_line,
                        color: e.state == "open" ? Colors.green : Colors.red,
                      ),
                      title: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Row(
                          children: [
                            Text(
                              e.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: IssueLabels(labels: e.labels),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text('#${e.number}'),
                          Text(' · ${e.user?.login ?? ''}'),
                          Text(' · opened on ${timeToLabel(e.createdAt)}')
                        ],
                      ),
                      trailing: e.commentsCount == 0
                          ? null
                          : IconText(
                              icon: Remix.chat_2_line,
                              text: Text('${e.commentsCount}'),
                            ),
                      onPressed: () {
                        //
                      },
                    ),
                  );
                }).toList() ??
                [],
          ),
        );
      },
    );
  }
}
