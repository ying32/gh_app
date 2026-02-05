import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

/// 仓库列表，可以是当前用户的仓库/点赞的仓库或者其它用户的仓库/其它用户点赞的仓库
class ReposPage extends StatelessWidget {
  const ReposPage({
    super.key,
    this.owner = '',
    this.isStarred = false,
  });

  final String owner;
  final bool isStarred;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RepoListModel(owner: owner, isStarred: isStarred),
      child: WantKeepAlive(
          onInit: (context) {
            APIWrap.instance
                .userRepos(owner, isStarred: isStarred)
                .then((data) {
              context.read<RepoListModel>().repos = data;
            });
          },
          child: const _ReposPage()),
    );
  }
}

class _ReposPage extends StatelessWidget {
  const _ReposPage();

  @override
  Widget build(BuildContext context) {
    return Selector<RepoListModel, QLList<QLRepository>>(
      selector: (_, model) => model.repos,
      builder: (context, repos, __) {
        if (repos.isEmpty) {
          return const LoadingRing();
        }
        final model = context.read<RepoListModel>();
        return RepoListView(
            repos: repos,
            onLoading: (QLPageInfo? pageInfo) async {
              if (pageInfo == null || !pageInfo.hasNextPage) {
                return const QLList.empty();
              }
              return APIWrap.instance.userRepos(model.owner,
                  isStarred: model.isStarred, nextCursor: pageInfo.endCursor);
            },
            onRefresh: () async {
              // return const QLList.empty();
              return APIWrap.instance.userRepos(model.owner,
                  isStarred: model.isStarred, force: true);
            });
      },
    );
  }
}
