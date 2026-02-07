part of '../../repo.dart';

/// Languages
class RepoLanguages extends StatelessWidget {
  const RepoLanguages({super.key});

  Widget _buildBody(BuildContext context, QLRepository repo) {
    final languages = repo.languages!;
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '语言',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (repo.languages!.isNotEmpty)
            Wrap(
              runSpacing: 6,
              spacing: 10,
              children: languages
                  .map((e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LangCircleDot(e),
                          const SizedBox(width: 5),
                          Text(e.name)
                        ],
                      ))
                  .toList(),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<RepoModel, QLRepository>(
      selector: (_, model) => model.repo,
      builder: (_, repo, __) => repo.languages == null
          ? const SizedBox.shrink()
          : _buildBody(context, repo),
    );
  }
}
