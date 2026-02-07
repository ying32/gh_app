import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

/// 仓库列表，可以是当前用户的仓库/点赞的仓库或者其它用户的仓库/其它用户点赞的仓库
class ReposPage extends StatelessWidget {
  const ReposPage({
    super.key,
    this.owner = '',
    this.isStarred = false,
    this.isOrganization = false,
  });

  final String owner;
  final bool isStarred;
  final bool isOrganization;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RepoListModel(
          owner: owner, isStarred: isStarred, isOrganization: isOrganization),
      child: WantKeepAlive(
          onInit: (context) {
            APIWrap.instance.userRepos(owner,
                isStarred: isStarred,
                isOrganization: isOrganization, onSecondUpdate: (value) {
              context.read<RepoListModel>().repos = value;
            }).then((data) {
              context.read<RepoListModel>().repos = data;
            });
          },
          child: const _ReposPage()),
    );
  }

  /// 创建一个仓库列表页
  static void createNewTab(
      BuildContext context, QLUserOrOrganizationCommon user,
      {bool isStarred = false}) {
    final tabView = context.read<TabviewModel>();
    // 不会有叫viewer的用户吧？
    final isMy = context.read<CurrentUserModel>().user?.login == user.login;
    final tabKey = ValueKey(
        "${isStarred ? RouterTable.stars : RouterTable.repos}/${isMy ? 'viewer' : user.login}");
    final index = tabView.indexOf(tabKey);
    if (index != -1) {
      tabView.goToTab(index);
      return;
    }
    context.read<TabviewModel>().addTab(
          ReposPage(
              owner: isMy ? '' : user.login,
              isStarred: isStarred,
              isOrganization: user.isOrganization),
          key: tabKey,
          title: isMy
              ? '我的仓库'
              : "${user.name.isEmpty ? user.login : user.name} 的仓库",
          icon: const DefaultIcon.repository(),
        );
  }
}

class _ReposPage extends StatelessWidget {
  const _ReposPage();

  @override
  Widget build(BuildContext context) {
    return SelectorQLList<RepoListModel, QLRepository>(
      selector: (_, model) => model.repos,
      builder: (context, repos, __) {
        final model = context.read<RepoListModel>();
        return RepoListView(
            repos: repos,
            onLoading: (QLPageInfo? pageInfo) async {
              if (pageInfo == null || !pageInfo.hasNextPage) {
                return const QLList.empty();
              }
              return APIWrap.instance.userRepos(model.owner,
                  isStarred: model.isStarred,
                  nextCursor: pageInfo.endCursor,
                  isOrganization: model.isOrganization);
            },
            onRefresh: () async {
              return APIWrap.instance.userRepos(model.owner,
                  isStarred: model.isStarred,
                  force: true,
                  isOrganization: model.isOrganization);
            });
      },
    );
  }
}
