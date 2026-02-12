import 'dart:math' as math;

import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/pages/releases.dart';
import 'package:gh_app/pages/user_info.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/defines.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:gh_app/widgets/highlight_plus.dart';
import 'package:gh_app/widgets/issues_widgets.dart';
import 'package:gh_app/widgets/markdown_plus.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

part 'repo/action.dart';
part 'repo/code.dart';
part 'repo/components/about.dart';
part 'repo/components/breadcrumb_bar.dart';
part 'repo/components/file_content_view.dart';
part 'repo/components/languages.dart';
part 'repo/components/readme.dart';
part 'repo/components/refs.dart';
part 'repo/components/releases.dart';
part 'repo/components/tree_entries_view.dart';
part 'repo/issues.dart';
part 'repo/issues_or_pull_requests.dart';
part 'repo/pull_request.dart';
part 'repo/wiki.dart';

class _TabPages extends StatefulWidget {
  const _TabPages();

  @override
  State<_TabPages> createState() => _TabPagesState();
}

class _TabPagesState extends State<_TabPages> {
  /// 当前页面
  int currentIndex = 0;

  Key _getKey(QLRepository repo, RepoSubPage key) =>
      ValueKey("${RouterTable.repo}/${repo.fullName}/$key");

  @override
  Widget build(BuildContext context) {
    return RepoSelector(builder: (_, repo) {
      return TabView(
        currentIndex: currentIndex,
        tabs: [
          Tab(
            key: _getKey(repo, RepoSubPage.code),
            text: const Text('代码'),
            icon: const DefaultIcon.code(),
            closeIcon: null,
            body: const RepoCodePage(),
          ),
          // issues
          if (repo.hasIssuesEnabled)
            Tab(
              key: _getKey(repo, RepoSubPage.issues),
              text: Row(
                children: [
                  const Text('问题 '),
                  RepoOpenIssueCountSelector(),
                ],
              ),
              icon: const DefaultIcon.issues(),
              closeIcon: null,
              body: RepoIssuesPage(repo),
            ),

          Tab(
            key: _getKey(repo, RepoSubPage.pullRequests),
            text: Row(
              children: [
                const Text('合并请求'),
                RepoOpenPullRequestCountSelector(),
              ],
            ),
            icon: const DefaultIcon.pullRequest(),
            closeIcon: null,
            body: RepoPullRequestPage(repo),
          ),
          Tab(
            key: _getKey(repo, RepoSubPage.actions),
            text: const Text('Actions'),
            icon: const DefaultIcon.action(),
            closeIcon: null,
            body: RepoActionPage(repo),
          ),
          if (repo.hasWikiEnabled)
            Tab(
              key: _getKey(repo, RepoSubPage.wiki),
              text: const Text('Wiki'),
              icon: const DefaultIcon.wiki(),
              closeIcon: null,
              body: RepoWikiPage(repo),
            ),
        ],
        onChanged: (index) {
          setState(() => currentIndex = index);
        },
        shortcutsEnabled: false,
        tabWidthBehavior: TabWidthBehavior.sizeToContent,
        closeButtonVisibility: CloseButtonVisibilityMode.never,
      );
    });
  }
}

class RepoPage extends StatelessWidget {
  const RepoPage(
    this.repo, {
    super.key,
    this.subPage,
    this.ref,
    this.path,
  });

  final QLRepository repo;
  final RepoSubPage? subPage;
  final String? ref;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RepoModel>(
        create: (_) => RepoModel(repo, subPage: subPage, ref: ref, path: path),
        child: WantKeepAlive(
            onInit: (context) {
              APIWrap.instance.userRepo(repo).then((e) {
                context.curRepo.repo = e!;
              });
            },
            child: const _InternalRepoPage()));
  }

  /// 创建一个仓库页
  static void createNewTab(BuildContext context, QLRepository repo,
      {RepoSubPage? subPage, String? ref, String? path}) {
    // TODO: subPage待实现
    if (kDebugMode) {
      print("subPage=$subPage, ref=$ref, path=$path");
    }
    //TODO: 这里还要优化下？
    final tabView = context.mainTabView;
    final tabKey = ValueKey("${RouterTable.repo}/${repo.fullName}");
    final index = tabView.indexOf(tabKey);
    if (index != -1) {
      tabView.goToTab(index);
      return;
    }
    context.mainTabView.addTab(
      RepoPage(repo, subPage: subPage, ref: ref, path: path),
      key: tabKey,
      title: repo.fullName,
    );
  }
}

class _InternalRepoPage extends StatelessWidget {
  const _InternalRepoPage();

  Widget _buildHeader(BuildContext context, QLRepository repo) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            ActorHeadImage(
              repo.owner,
              imageSize: 45,
              onPressed: () {
                // showImageDialog(context, repo.owner!.avatarUrl);
                // 随便整的，先简单整下
                LoadingDialog.show(context);

                // final future = repo.isInOrganization
                //     ? APIWrap.instance.organizationInfo(repo.owner.login)
                //     : APIWrap.instance.userInfo(repo.owner.login);
                APIWrap.instance.ownerInfo(repo.owner.login).then((user) {
                  closeDialog(context); //???
                  if (user == null) return;
                  UserInfoPage.createNewTab(context, user);
                }).onError((e, s) {
                  closeDialog(context);
                  // showInfoDialog('msg', context: context)
                });
              },
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectableText(repo.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20)),
                if (repo.isFork && repo.parent != null) RepoItemForkInfo(repo),
              ],
            ),
            if (repo.isPrivate)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: DefaultIcon.repositoryPrivate(),
              ),
            if (repo.isArchived)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: TagLabel.archived(),
              ),
            const Spacer(),
            const _TopBar1(useCard: false),
            // 这东西竟然会引起一堆问题？？？
            IconLinkButton.linkSource(repo.url, message: '在浏览器中打开')
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return EasyListViewRefresher(
      onRefresh: (controller) {
        APIWrap.instance.userRepo(context.curRepo.repo).then((e) {
          context.curRepo.repo = e!;

          controller.refreshCompleted();
        }).onError((e, s) {
          controller.refreshFailed();
        });
      },
      listview: RepoSelector(
        builder: (_, repo) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: kPageDefaultVerticalPadding / 2.0,
              // start: PageHeader.horizontalPadding(context),
              end: kPageDefaultVerticalPadding / 2.0,
            ),
            child: Column(
              children: [
                _buildHeader(context, repo),
                const Divider(
                  direction: Axis.horizontal,
                  style: DividerThemeData(horizontalMargin: EdgeInsets.zero),
                ),
                const SizedBox(height: 8.0),
                const Expanded(child: _TabPages()),
              ],
            ),
          );
        },
      ),
    );
  }
}
