part of '../../repo.dart';

/// Release
class RepoReleases extends StatelessWidget {
  const RepoReleases({super.key});

  Widget _buildBody(BuildContext context, Repository repo, Release lastRelease,
      int releaseCount) {
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
                    "$releaseCount",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          // Text('${}'),
          IconText(
            icon: Remix.price_tag_3_line,
            iconColor: Colors.green,
            text: Text(
              lastRelease.name ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            trailing: TagLabel.other(
              "Latest",
              color: Colors.green,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 22.0),
            child: Text(lastRelease.publishedAt!.toLabel,
                style: const TextStyle(fontSize: 11)),
          ),
          if (releaseCount > 1)
            LinkStyleButton(
              text: Text('+ ${releaseCount - 1} releases',
                  style: TextStyle(color: Colors.blue)),
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
    final repo = context.read<RepoModel>().repo;
    if (repo is QLRepository) {
      return Selector<RepoModel, Repository>(
        selector: (_, model) => model.repo,
        builder: (_, repo, __) =>
            repo is! QLRepository || repo.latestRelease == null
                ? const SizedBox.shrink()
                : _buildBody(
                    context, repo, repo.latestRelease!, repo.releasesCount),
      );
    }
    return const SizedBox.shrink();

    // return FutureBuilder(
    //   future: GithubCache.instance.repoReleases(repo),
    //   builder: (_, snapshot) {
    //     if (!snapshotIsOk(snapshot) || (snapshot.data?.isEmpty ?? true)) {
    //       return const SizedBox.shrink();
    //     }
    //     final releases = snapshot.data ?? [];
    //     if (releases.isEmpty) {
    //       return const SizedBox.shrink();
    //     }
    //     return _buildBody(context, repo, releases.last, releases.length);
    //   },
    // );
  }
}
