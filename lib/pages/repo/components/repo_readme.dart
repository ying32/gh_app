part of '../../repo.dart';

/// README文件
class RepoReadMe extends StatelessWidget {
  const RepoReadMe({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector2<PathModel, RepoBranchModel, (String, String?)>(
        selector: (_, model, model2) => (model.path, model2.selectedBranch),
        builder: (_, p, __) {
          if (p.$1 != "") return const SizedBox.shrink();
          final repo = context.read<RepoModel>().repo;
          return FutureBuilder(
            future: GithubCache.instance.repoReadMe(repo, ref: p.$2),
            builder: (_, snapshot) {
              if (!snapshotIsOk(snapshot, false, false)) {
                return const SizedBox.shrink();
              }
              final body = snapshot.data ?? '';
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
                        if (repo.license != null)
                          IconText(
                              icon: Remix.scales_line,
                              text: Text(
                                repo.license!.name ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                      ],
                    ),
                    if (body.isNotEmpty) MarkdownBlockPlusDefaultAction(body),
                  ],
                ),
              );
            },
          );
        });
  }
}
