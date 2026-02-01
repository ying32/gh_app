part of '../repo.dart';

/// 分支列表
class _RepoBranches extends StatelessWidget {
  const _RepoBranches();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;

    return FutureBuilder(
      future: APIWrap.instance.repoRefs(repo),
      builder: (_, snapshot) {
        // if (!snapshotIsOk(snapshot, false, false)) {
        //   return DropDownButton(
        //     title: IconText(
        //         icon: Remix.git_branch_line, text: Text(repo.defaultBranch)),
        //     items: [
        //       MenuFlyoutItem(
        //           text: const Center(
        //             child: SizedBox(width: 100, child: ProgressRing()),
        //           ),
        //           onPressed: () {})
        //     ],
        //   );
        // }
        final refs =
            (snapshot.data?.data ?? [QLRef(name: repo.defaultBranchRef.name)]);
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
                        icon: Remix.git_branch_line,
                        text: Text(selectedBranch ?? defaultBranch)),
                    items: refs
                        .map((e) => MenuFlyoutItem(
                            leading: e.name == (selectedBranch ?? defaultBranch)
                                ? const Icon(Remix.check_line)
                                : null,
                            text: Text(e.name ?? ''),
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
            const SizedBox(width: 10.0),
            HyperlinkButton(
              onPressed: () {},
              child: IconText(
                  icon: Remix.git_branch_line, text: Text("${refs.length}")),
            ),
            const SizedBox(width: 10.0),
            HyperlinkButton(
              onPressed: () {},
              child:
                  const IconText(icon: Remix.price_tag_3_line, text: Text("0")),
            ),
          ],
        );
      },
    );
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
              icon: Remix.eye_line,
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
              icon: Remix.git_fork_line,
              text: Text('${repo.forksCount.toKiloString()} 分叉'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            onPressed: _onStar,
            child: IconText(
              icon: Remix.star_line,
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
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            // 这里可以使用Selector2来替代
                            child: RepoContentsListView(
                              path: context.watch<PathModel>().path,
                              ref: context
                                  .watch<RepoBranchModel>()
                                  .selectedBranch,
                              onPathChange: (value) {
                                context.read<PathModel>().path = value;
                              },
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          // readme，只有根目录下才显示README？或者文件中有就显示？
                          const RepoReadMe(),
                        ]),
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
