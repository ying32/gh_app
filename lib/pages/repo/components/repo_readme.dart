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
    return Card(
      child: Column(
        children: [
          Row(
            children: [
              const IconText(
                  icon: DefaultIcons.readme,
                  text: Text(
                    'README',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
              const SizedBox(width: 12.0),
              if (repo.license.name.isNotEmpty)
                IconText(
                    icon: DefaultIcons.license,
                    text: Text(
                      repo.license.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
            ],
          ),
          APIFutureBuilder(
            noDataWidget: const SizedBox.shrink(),
            errorWidget: const SizedBox.shrink(),
            future: APIWrap.instance.repoReadMe(repo, filename, ref: ref),
            builder: (_, snapshot) {
              return MarkdownBlockPlusDefaultAction(snapshot);
            },
          ),
        ],
      ),
    );
  }
}
