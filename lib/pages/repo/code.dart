part of '../repo.dart';

/// 分支列表
/// TODO: 这个要优化，下只在下拉的时候才加载其它分支信息
class _RepoBranches extends StatelessWidget {
  const _RepoBranches();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;

    return DropdownPanelButton(
      flyout: ChangeNotifierProvider.value(
        value: context.read<RepoBranchModel>(),
        child: FlyoutContent(
          constraints: const BoxConstraints(maxWidth: 300.0, maxHeight: 300),
          child: Selector<RepoBranchModel, QLList<QLRef>>(
            selector: (_, model) => model.refs,
            builder: (_, refs, __) {
              if (refs.isEmpty) {
                return const SizedBox(
                    height: 30,
                    width: 100,
                    child: Center(
                        child: SizedBox(
                            width: 30, height: 30, child: ProgressRing())));
              }
              return SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: refs.data
                        .map((e) => Tooltip(
                              message: e.name,
                              child: LinkButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    context
                                            .read<RepoBranchModel>()
                                            .selectedBranch =
                                        e.name == repo.defaultBranchRef.name
                                            ? null
                                            : e.name;
                                  },
                                  text: SizedBox(
                                    height: 30,
                                    child: Row(
                                      children: [
                                        if (e.name ==
                                            (context
                                                    .read<RepoBranchModel>()
                                                    .selectedBranch ??
                                                repo.defaultBranchRef.name))
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: DefaultIcon.check(),
                                          )
                                        else
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: SizedBox(width: 16),
                                          ),
                                        Expanded(
                                            child: Text(e.name,
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        if (e.name ==
                                            repo.defaultBranchRef.name)
                                          TagLabel.other('默认',
                                              color: context.isDark
                                                  ? Colors.white
                                                  : Colors.black),
                                      ],
                                    ),
                                  )),
                            ))
                        .toList()),
              );
            },
          ),
        ),
      ),
      onOpen: () {
        // 下拉时
        if (context.read<RepoBranchModel>().refs.isEmpty) {
          APIWrap.instance.repoRefs(repo).then((res) {
            context.read<RepoBranchModel>().refs = res;
          });
        }
      },
      title: SizedBox(
        height: 32,
        child: IconText(
          icon: DefaultIcons.branch,
          text: Selector<RepoBranchModel, String?>(
              selector: (_, model) => model.selectedBranch,
              builder: (_, selectedBranch, __) =>
                  Text(selectedBranch ?? repo.defaultBranchRef.name)),
        ),
      ),
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
                    // child: RepoContentsListView(
                    //   path: context.watch<PathModel>().path,
                    //   ref: context.watch<RepoBranchModel>().selectedBranch,
                    //   onPathChange: (value) {
                    //     context.read<PathModel>().path = value;
                    //   },
                    // ),
                    child: Selector2<RepoBranchModel, PathModel,
                            (String?, String)>(
                        selector: (_, ref, path) =>
                            (ref.selectedBranch, path.path),
                        builder: (_, value, __) {
                          return RepoContentsListView(
                            path: value.$2,
                            ref: value.$1,
                            onPathChange: (value) {
                              context.read<PathModel>().path = value;
                            },
                          );
                        }),
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
