part of '../repo.dart';

/// 分支列表
class _RepoBranches extends StatelessWidget {
  const _RepoBranches();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;

    return APIFutureBuilder(
      future: APIWrap.instance.repoRefs(repo),
      builder: (_, snapshot) {
        // if (!snapshotIsOk(snapshot, false, false)) {
        //   return DropDownButton(
        //     title: IconText(
        //         icon: DefaultIcons.branch, text: Text(repo.defaultBranch)),
        //     items: [
        //       MenuFlyoutItem(
        //           text: const Center(
        //             child: SizedBox(width: 100, child: ProgressRing()),
        //           ),
        //           onPressed: () {})
        //     ],
        //   );
        // }
        final refs = snapshot.isEmpty
            ? [QLRef(name: repo.defaultBranchRef.name)]
            : snapshot.data;
        return Row(
          children: [
            Selector2<RepoModel, RepoBranchModel, (QLRepository, String?)>(
              selector: (_, model, model2) =>
                  (model.repo, model2.selectedBranch),
              builder: (_, model, __) {
                final defaultBranch = model.$1.defaultBranchRef.name;
                final selectedBranch = model.$2;

                return DropDownButton(
                    title: IconText(
                        icon: DefaultIcons.branch,
                        text: Text(selectedBranch ?? defaultBranch)),
                    items: refs
                        .map((e) => MenuFlyoutItem(
                            leading: e.name == (selectedBranch ?? defaultBranch)
                                ? const DefaultIcon.check()
                                : null,
                            text: Text(e.name),
                            trailing: e.name == defaultBranch
                                ? TagLabel.other('默认',
                                    color: context.isDark
                                        ? Colors.white
                                        : Colors.black)
                                : null,
                            onPressed: () {
                              context.read<RepoBranchModel>().selectedBranch =
                                  e.name == defaultBranch ? null : e.name;
                            }))
                        .toList());
              },
            ),
          ],
        );
      },
    );
  }
}

/// 分支和标签总数显示
class _BranchAndTagsCount extends StatelessWidget {
  const _BranchAndTagsCount();

  @override
  Widget build(BuildContext context) {
    return Selector<RepoModel, QLRepository>(
        selector: (_, model) => model.repo,
        builder: (_, repo, __) {
          return Row(
            children: [
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: DefaultIcons.branch, text: Text("${repo.refsCount}")),
              ),
              const SizedBox(width: 10.0),
              HyperlinkButton(
                onPressed: () {},
                child: IconText(
                    icon: DefaultIcons.tags, text: Text("${repo.tagsCount}")),
              ),
            ],
          );
        });
  }
}

/// 顶部条1
class _TopBar1 extends StatelessWidget {
  const _TopBar1({this.useCard = true});

  final bool useCard;

  void _onFork() {
    // showInfoDialog("", context: )
  }

  void _onStar() {}

  void _onWatch() {}

  Widget _buildChild(QLRepository repo) {
    Widget child = Row(
      children: [
        // Title(
        //     color: appTheme.color.lightest, child: Text(_repo.name)),
        // const Spacer(),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 4),
        //   child: Button(
        //     child: const IconText(
        //       icon: Remix.layout_top_fill,
        //       text:  Text('Pin/UnPin'),
        //     ),
        //     onPressed: () => debugPrint('pressed button'),
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            onPressed: _onWatch,
            child: IconText(
              icon: DefaultIcons.watch,
              text: Text('${repo.watchersCount.toKiloString()} 关注'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            onPressed:
                repo.forkingAllowed == true && !repo.isFork ? _onFork : null,
            child: IconText(
              icon: DefaultIcons.fork,
              text: Text('${repo.forksCount.toKiloString()} 分叉'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            onPressed: _onStar,
            child: IconText(
              icon: DefaultIcons.star,
              text: Text('${repo.stargazersCount.toKiloString()} 点赞'),
            ),
          ),
        ),
      ],
    );
    if (useCard) {
      child = Card(child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<RepoModel, QLRepository>(
      selector: (_, model) => model.repo,
      builder: (_, repo, __) => _buildChild(repo),
    );
  }
}

class _TopBar2 extends StatelessWidget {
  const _TopBar2();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Row(
        children: [
          _RepoBranches(),
          SizedBox(width: 10.0),
          _BranchAndTagsCount(),
          SizedBox(width: 10.0),
          Spacer(),
          _TopBar1(useCard: false),
          SizedBox(width: 10.0),
        ],
      ),
    );
  }
}

/// 关于/Release信息等
class _CodePageRight extends StatelessWidget {
  const _CodePageRight();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: double.infinity, child: Card(child: RepoAbout())),
        SizedBox(height: 2),
        SizedBox(width: double.infinity, child: RepoReleases()),
      ],
    );
  }
}

/// 代码页面
class RepoCodePage extends StatelessWidget {
  const RepoCodePage(this.repo, {super.key});

  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(size: 1),
        // const Padding(
        //   padding: EdgeInsets.symmetric(vertical: 8.0),
        //   child: _TopBar1(),
        // ),
        const _TopBar2(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Card(child: RepoBreadcrumbBar()),
        ),
        Expanded(
          child: ListView(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RepoContentsListView(
                      path: context.watch<PathModel>().path,
                      ref: context.watch<RepoBranchModel>().selectedBranch,
                      onPathChange: (value) {
                        context.read<PathModel>().path = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // 右边
                  const SizedBox(width: 300, child: _CodePageRight())
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
