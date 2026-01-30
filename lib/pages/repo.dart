import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/pages/releases.dart';
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/issues_widgets.dart';
import 'package:gh_app/widgets/markdown_plus.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';
import 'package:provider/provider.dart';

part 'repo/action.dart';
part 'repo/code.dart';
part 'repo/components/about.dart';
part 'repo/components/repo_readme.dart';
part 'repo/components/repo_releases.dart';
part 'repo/issues.dart';
part 'repo/pull_request.dart';
part 'repo/wiki.dart';

class _TabPages extends StatefulWidget {
  const _TabPages({super.key});

  @override
  State<_TabPages> createState() => _TabPagesState();
}

class _TabPagesState extends State<_TabPages> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return TabView(
      currentIndex: currentIndex,
      tabs: [
        Tab(
          text: const Text('代码'),
          icon: const Icon(Remix.code_line),
          closeIcon: null,
          body: RepoCodePage(repo),
        ),
        Tab(
          text: Text('问题 ${repo.openIssues ?? 0}'),
          icon: const Icon(Remix.issues_line),
          closeIcon: null,
          body: RepoIssuesPage(repo),
        ),
        Tab(
          text: const Text('合并请求 ${0}'),
          icon: const Icon(Remix.git_pull_request_line),
          closeIcon: null,
          body: RepoPullRequestPage(repo),
        ),
        Tab(
          text: const Text('Actions'),
          icon: const Icon(Remix.play_circle_line),
          closeIcon: null,
          body: RepoActionPage(repo),
        ),
        Tab(
          text: const Text('Wiki'),
          icon: const Icon(Remix.book_open_line),
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
  }
}

class RepoPage extends StatelessWidget {
  const RepoPage({super.key});

  static void createNewTab(BuildContext context, Repository repo) {
    context.read<TabviewModel>().addTab(
          ChangeNotifierProvider<RepoModel>(
            create: (_) => RepoModel(repo),
            child: const RepoPage(),
          ),
          key: ValueKey("${RouterTable.repo}/${repo.fullName}"),
          title: repo.fullName,
          // icon: Remix.git_repository_line,
        );
  }

  @override
  Widget build(BuildContext context) {
    // assert(debugCheckHasFluentTheme(context));
    // final theme = FluentTheme.of(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PathModel>(create: (_) => PathModel()),
        ChangeNotifierProvider<RepoBranchModel>(
            create: (_) => RepoBranchModel()),
      ],
      child: WrapInit(
        onInit: () {
          if (kDebugMode) {
            print("初始");
          }
        },
        child: Selector<RepoModel, Repository>(
          selector: (_, model) => model.repo,
          builder: (_, repo, __) {
            return ScaffoldPage(
              header: PageHeader(
                title: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon:
                            UserHeadImage(repo.owner?.avatarUrl, imageSize: 50),
                        onPressed: () {
                          // UserInfoPage.createNewTab(context, repo.owner!);
                        },
                      ),
                    ),
                    Text(repo.fullName),
                    if (repo.isPrivate)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Remix.git_repository_private_line),
                      ),
                    if (repo.archived)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: TagLabel.archived(),
                      ),
                    const Spacer(),
                    LinkAction(
                      icon: const Icon(FluentIcons.open_source, size: 18),
                      link: repo.htmlUrl,
                      message: '在浏览器中打开',
                    ),
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
        ),
      ),
    );
  }
}
