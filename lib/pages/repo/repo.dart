import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/fonts/remix_icon.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

import 'action_page.dart';
import 'code_page.dart';
import 'issues_page.dart';
import 'pull_request_page.dart';
import 'wiki_page.dart';

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
          body: CodePage(repo),
        ),
        Tab(
          text: Text('问题 ${repo.openIssues ?? 0}'),
          icon: const Icon(Remix.issues_line),
          closeIcon: null,
          body: IssuesPage(repo),
        ),
        Tab(
          text: const Text('合并请求 ${0}'),
          icon: const Icon(Remix.git_pull_request_line),
          closeIcon: null,
          body: PullRequestPage(repo),
        ),
        Tab(
          text: const Text('Actions'),
          icon: const Icon(Remix.play_circle_line),
          closeIcon: null,
          body: ActionPage(repo),
        ),
        Tab(
          text: const Text('Wiki'),
          icon: const Icon(Remix.book_open_line),
          closeIcon: null,
          body: WikiPage(repo),
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

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    final model = context.watch<RepoModel>();
    final repo = model.repo;

    return ScaffoldPage(
      header: PageHeader(
        title: Row(
          children: [
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
            ),
          ],
        ),
      ),
      content: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        child: const _TabPages(),
      ),
    );
  }
}
