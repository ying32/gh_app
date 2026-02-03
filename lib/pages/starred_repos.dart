import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';

class StarredReposPage extends StatelessWidget {
  const StarredReposPage({super.key, this.owner = ''});

  final String owner;

  Future<QLList<QLRepository>> _onLoadData(QLPageInfo? pageInfo) async {
    if (pageInfo == null || !pageInfo.hasNextPage) return const QLList.empty();
    return APIWrap.instance
        .userRepos(owner, nextCursor: pageInfo.endCursor, isStarred: true);
  }

  Future<QLList<QLRepository>> _onRefreshData() async {
    // return const QLList.empty();
    return APIWrap.instance.userRepos(owner, isStarred: true, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return APIFutureBuilder(
      future: APIWrap.instance.userRepos(owner, isStarred: true),
      builder: (_, snapshot) {
        return RepoListView(
            repos: snapshot,
            showOpenIssues: false,
            onLoading: _onLoadData,
            onRefresh: _onRefreshData);
      },
    );
  }
}
