part of '../repo.dart';

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
              LinkButton(
                style: TextStyle(color: context.textColor200),
                onPressed: () {},
                text: IconText(
                    icon: DefaultIcons.branch, text: Text("${repo.refsCount}")),
              ),
              const SizedBox(width: 10.0),
              LinkButton(
                style: TextStyle(color: context.textColor200),
                onPressed: () {},
                text: IconText(
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
            onPressed: repo.forkingAllowed == true ? _onFork : null,
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
  const RepoCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(size: 1),
        const _TopBar2(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Card(child: RepoBreadcrumbBar()),
        ),
        Expanded(
          //TODO: 待优化
          child: ListView(
            children: const [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 内容树
                  Expanded(child: RepoTreeEntriesView()),
                  SizedBox(height: 10.0),

                  // 右边
                  SizedBox(width: 300, child: _CodePageRight())
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
