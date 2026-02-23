part of '../repo.dart';

/// 分支和标签总数显示
class _BranchAndTagsCount extends StatelessWidget {
  const _BranchAndTagsCount();

  @override
  Widget build(BuildContext context) {
    return RepoSelector(builder: (_, repo) {
      return Row(
        children: [
          // HyperlinkButton(
          //   //style: TextStyle(color: context.textColor200),
          //   onPressed: () {},
          //   child:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconText(
                icon: DefaultIcons.branch, text: Text("${repo.refsCount}")),
          ),
          // ),
          const SizedBox(width: 10.0),
          // HyperlinkButton(
          //   //style: TextStyle(color: context.textColor200),
          //   onPressed: () {},
          //   child:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconText(
                icon: DefaultIcons.tags, text: Text("${repo.tagsCount}")),
          ),
          // ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            onPressed: repo.viewerCanSubscribe ? _onWatch : null,
            child: IconText(
              icon: repo.viewerHasSubscribed
                  ? DefaultIcons.watchFill
                  : DefaultIcons.watch,
              iconColor: repo.viewerHasSubscribed ? Colors.green : null,
              text: Text(
                  '${repo.watchersCount.toKiloString()} ${repo.viewerHasSubscribed ? '取消' : ''}关注'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            // 这样对么？感觉不太对的啊
            onPressed: repo.forkingAllowed == true &&
                    repo.permission != QLRepositoryPermission.admin
                ? _onFork
                : null,
            child: IconText(
              icon: DefaultIcons.fork,
              text: Text('${repo.forksCount.toKiloString()} 派生'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Button(
            onPressed: _onStar,
            child: IconText(
              icon: repo.viewerHasStarred
                  ? DefaultIcons.starFill
                  : DefaultIcons.star,
              iconColor: repo.viewerHasStarred ? Colors.yellow : null,
              text: Text(
                  '${repo.stargazersCount.toKiloString()} ${repo.viewerHasStarred ? '取消' : ''}点赞'),
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
    return RepoSelector(builder: (_, repo) => _buildChild(repo));
  }
}

class _TopBar2 extends StatelessWidget {
  const _TopBar2();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _RepoBranches(),
        SizedBox(width: 10.0),
        _BranchAndTagsCount(),
        SizedBox(width: 10.0),
        Spacer(),
        // _TopBar1(useCard: false),
      ],
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
        SizedBox(height: 2),
        SizedBox(width: double.infinity, child: RepoLanguages()),
      ],
    );
  }
}

/// 鼠标导航
class _MouseNavigation extends StatelessWidget {
  const _MouseNavigation({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
        onPointerDown: (event) {
          //print("event.buttons=${event.buttons}");
          switch (event.buttons) {
            case 0x8: // 后退键(扩展键1)
              context.curRepo.pathMouseBack();
            case 0x10: // 前进键(扩展键2)
              context.curRepo.pathMouseForward();
          }
        },
        child: child);
  }
}

//TODO: 这个还没完善，只能列出默认分支的
class _LastRepoCommitBar extends StatelessWidget {
  const _LastRepoCommitBar();

  @override
  Widget build(BuildContext context) {
    return RepoModelSelector<QLCommit?>(
      selector: (model) => model.commit,
      builder: (_, commit) {
        if (commit == null) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            if (commit.author != null)
              GitActorHeadImage(commit.author, imageSize: 24),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: ' '),
                  TextSpan(
                      text: commit.author?.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' '),
                  TextSpan(text: commit.messageHeadline),
                ]),
                style: TextStyle(color: Colors.grey.withOpacity(0.8)),
              ),
            ),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: commit.abbreviatedOid),
                const TextSpan(text: ' $dotChar '),
                TextSpan(text: commit.committedDate?.toLabel),
                const TextSpan(text: '  '),
                const WidgetSpan(child: DefaultIcon.history()),
                const TextSpan(text: ' '),
                const TextSpan(text: '0'),
                const TextSpan(text: ' 个提交'),
              ]),
              style: TextStyle(color: Colors.grey.withOpacity(0.8)),
            )
          ],
        );
      },
    );
  }
}

/// 内容组合
class _ContentWidget extends StatelessWidget {
  const _ContentWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // Divider(
        //     direction: Axis.horizontal,
        //     style: DividerThemeData(
        //         verticalMargin: EdgeInsets.zero,
        //         horizontalMargin: EdgeInsets.zero)),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: _LastRepoCommitBar()),
        Divider(
            direction: Axis.horizontal,
            style: DividerThemeData(
                verticalMargin: EdgeInsets.zero,
                horizontalMargin: EdgeInsets.zero)),
        RepoTreeEntriesView(),
      ],
    );
  }
}

/// 代码页面
class RepoCodePage extends StatelessWidget {
  const RepoCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _MouseNavigation(
      child: Column(
        children: [
          const Card(child: _TopBar2()),
          const SizedBox(height: 2.0),
          // 导航指示
          const Card(child: RepoBreadcrumbBar()),
          const SizedBox(height: 2.0),
          Expanded(
            //TODO: 待优化
            child: ListView(
              children: const [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 内容树
                    Expanded(
                        child: Column(
                      children: [
                        // 导航指示
                        Card(child: _ContentWidget()),
                        // readme
                        SizedBox(height: 8.0),
                        RepoReadMe(),
                      ],
                    )),
                    SizedBox(width: 10.0),

                    // 右边
                    SizedBox(width: 300, child: _CodePageRight())
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
