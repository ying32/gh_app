part of '../../repo.dart';

/// README文件
class RepoReadMe extends StatelessWidget {
  const RepoReadMe({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<RepoModel, String>(
        selector: (_, model) => model.readmeContent,
        builder: (context, content, __) {
          final repo = context.read<RepoModel>().repo;
          if (content.isEmpty) {
            return const SizedBox.shrink();
          }
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
                    if (repo.licenseInfo?.name.isNotEmpty ?? false)
                      IconText(
                          icon: DefaultIcons.license,
                          text: Text(
                            repo.licenseInfo!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                  ],
                ),
                MarkdownBlockPlus(content),
              ],
            ),
          );
          // return MarkdownBlockPlus(content);
        });
  }
}
