import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/pages/issue_details.dart';
import 'package:gh_app/pages/releases.dart';
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/issues_widgets.dart';
import 'package:gh_app/widgets/markdown_plus.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

import 'pull_request_details.dart';

part 'repo/action.dart';
part 'repo/code.dart';
part 'repo/components/about.dart';
part 'repo/components/repo_readme.dart';
part 'repo/components/repo_releases.dart';
part 'repo/issues.dart';
part 'repo/pull_request.dart';
part 'repo/wiki.dart';

class _TabPages extends StatefulWidget {
  const _TabPages();

  @override
  State<_TabPages> createState() => _TabPagesState();
}

class _TabPagesState extends State<_TabPages> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Selector<RepoModel, QLRepository>(
        selector: (_, model) => model.repo,
        builder: (_, repo, __) {
          return TabView(
            currentIndex: currentIndex,
            tabs: [
              Tab(
                text: const Text('代码'),
                icon: const DefaultIcon.code(),
                closeIcon: null,
                body: RepoCodePage(repo),
              ),
              // issues
              if (repo.hasIssuesEnabled)
                Tab(
                  text: Text('问题 ${repo.openIssuesCount}'),
                  icon: const DefaultIcon.issues(),
                  closeIcon: null,
                  body: RepoIssuesPage(repo),
                ),

              Tab(
                text: Text('合并请求 ${repo.openPullRequestsCount}'),
                icon: const DefaultIcon.pullRequest(),
                closeIcon: null,
                body: RepoPullRequestPage(repo),
              ),
              Tab(
                text: const Text('Actions'),
                icon: const DefaultIcon.action(),
                closeIcon: null,
                body: RepoActionPage(repo),
              ),
              if (repo.hasWikiEnabled)
                Tab(
                  text: const Text('Wiki'),
                  icon: const DefaultIcon.wiki(),
                  closeIcon: null,
                  body: RepoWikiPage(repo),
                ),
            ],
            onChanged: (index) {
              setState(() => currentIndex = index);
            },
            tabWidthBehavior: TabWidthBehavior.sizeToContent,
            closeButtonVisibility: CloseButtonVisibilityMode.never,
          );
        });
  }
}

class RepoPage extends StatelessWidget {
  const RepoPage(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<RepoModel>(
              create: (_) => RepoModel(repo), child: const _InternalRepoPage()),
          ChangeNotifierProvider<PathModel>(create: (_) => PathModel()),
          ChangeNotifierProvider<RepoBranchModel>(
              create: (_) => RepoBranchModel()),
        ],
        child: WrapInit(
            onInit: (context) {
              APIWrap.instance.userRepo(repo).then((e) {
                context.read<RepoModel>().repo = e!;
              });
            },
            child: const _InternalRepoPage()));
  }

  /// 创建一个仓库页
  static void createNewTab(BuildContext context, QLRepository repo) {
    context.read<TabviewModel>().addTab(
          RepoPage(repo),
          key: ValueKey("${RouterTable.repo}/${repo.fullName}"),
          title: repo.fullName,
        );
  }
}

class _InternalRepoPage extends StatelessWidget {
  const _InternalRepoPage();

  @override
  Widget build(BuildContext context) {
    return Selector<RepoModel, QLRepository>(
      selector: (_, model) => model.repo,
      builder: (_, repo, __) {
        return ScaffoldPage(
          header: PageHeader(
            title: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: UserHeadImage(repo.owner?.avatarUrl, imageSize: 50),
                    onPressed: () {
                      if (repo.isInOrganization) {
                        //UserInfoPage.createNewTab(context, user)
                      } else {
                        //UserInfoPage.createNewTab(context, user);
                      }
                    },
                  ),
                ),
                Text(repo.fullName),
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
                IconLinkButton.linkSource(repo.url, message: '在浏览器中打开')
              ],
            ),
          ),
          content: Padding(
            padding: EdgeInsetsDirectional.only(
              bottom: kPageDefaultVerticalPadding,
              // start: PageHeader.horizontalPadding(context),
              end: PageHeader.horizontalPadding(context),
            ),
            child: const _TabPages(),
          ),
        );
      },
    );
  }
}
