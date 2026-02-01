part of '../../repo.dart';

/// README文件
class RepoReadMe extends StatelessWidget {
  const RepoReadMe({
    super.key,
    required this.repo,
    this.ref,
    required this.filename,
  });

  final QLRepository repo;
  final String? ref;
  final String filename;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: APIWrap.instance.repoReadMe(repo, filename, ref: ref),
      builder: (_, snapshot) {
        if (!snapshotIsOk(snapshot, false, false)) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Column(
            children: [
              Row(
                children: [
                  const IconText(
                      icon: Remix.book_open_line,
                      text: Text(
                        'README',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(width: 12.0),
                  if (repo.license.name.isNotEmpty)
                    IconText(
                        icon: Remix.scales_line,
                        text: Text(
                          repo.license.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                ],
              ),
              MarkdownBlockPlusDefaultAction(snapshot.data),
            ],
          ),
        );
      },
    );
  }
}
