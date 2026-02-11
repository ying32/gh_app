part of '../../repo.dart';

/// Release
class RepoReleases extends StatelessWidget {
  const RepoReleases({super.key});

  Widget _buildBody(BuildContext context, QLRepository repo) {
    final lastRelease = repo.latestRelease!;
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Releases',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TagLabel(
                  text: Text(
                    "${repo.releasesCount}",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          // Text('${}'),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // 这里先不管哈
                ReleasesPage.createNewTab(context, repo);
              },
              child: IconText(
                icon: DefaultIcons.releases,
                iconColor: Colors.green,
                expanded: true,
                text: Text(
                  lastRelease.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis),
                ),
                trailing: TagLabel.other(
                  "Latest",
                  color: Colors.green,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 22.0),
            child: Text(lastRelease.publishedAt!.toLabel,
                style: const TextStyle(fontSize: 11)),
          ),
          if (repo.releasesCount > 1)
            LinkButton(
              text: Text('+ ${repo.releasesCount - 1} releases'),
              onPressed: () {
                // 这里先不管哈
                ReleasesPage.createNewTab(context, repo);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepoSelector(
      builder: (_, repo) => repo.latestRelease == null
          ? const SizedBox.shrink()
          : _buildBody(context, repo),
    );
  }
}
