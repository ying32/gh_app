import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';

class ReposPage extends StatelessWidget {
  const ReposPage({super.key, this.owner = ''});

  final String owner;

  Future<QLList<QLRepository>> _onLoadData(QLPageInfo? pageInfo) async {
    if (pageInfo == null || !pageInfo.hasNextPage) return const QLList.empty();
    return APIWrap.instance.userRepos(owner, nextCursor: pageInfo.endCursor);
  }

  Future<QLList<QLRepository>> _onRefreshData() async {
    // return const QLList.empty();
    return APIWrap.instance.userRepos(owner, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return APIFutureBuilder(
      future: APIWrap.instance.userRepos(owner),
      builder: (_, snapshot) => RepoListView(
          repos: snapshot, onLoading: _onLoadData, onRefresh: _onRefreshData),
    );
  }
}
