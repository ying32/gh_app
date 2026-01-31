part of '../../repo.dart';

/// Release
class RepoReleases extends StatelessWidget {
  const RepoReleases({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return FutureBuilder(
      future: GithubCache.instance.repoReleases(repo),
      builder: (_, snapshot) {
        if (!snapshotIsOk(snapshot) || (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }

        final releases = snapshot.data ?? [];
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Releases ${releases.length}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Text('${}'),
              IconText(
                icon: Remix.price_tag_3_line,
                iconColor: Colors.green,
                text: Text(
                  releases.last.name ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                trailing: TagLabel.other(
                  "Latest",
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              if (releases.length > 1)
                LinkStyleButton(
                  text: Text('+ ${releases.length - 1} releases',
                      style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    ReleasesPage.createNewTab(context, repo, releases);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
