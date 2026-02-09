part of '../../repo.dart';

/// 分支列表
/// TODO: 这个要优化，下只在下拉的时候才加载其它分支信息
class _RepoBranches extends StatelessWidget {
  const _RepoBranches();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;

    return DropdownPanelButton(
      flyout: ChangeNotifierProvider.value(
        value: context.read<RepoModel>(),
        child: FlyoutContent(
          constraints: const BoxConstraints(maxWidth: 240.0, maxHeight: 300),
          child: Selector<RepoModel, QLList<QLRef>>(
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
                              child: MaterialStyleButton(
                                  //style: TextStyle(color: context.textColor200),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    context.read<RepoModel>().ref =
                                        e.name == repo.defaultBranchRef.name
                                            ? null
                                            : e.name;
                                  },
                                  child: SizedBox(
                                    height: 30,
                                    child: Row(
                                      children: [
                                        if (e.name ==
                                            (context.read<RepoModel>().ref ??
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
        if (context.read<RepoModel>().refs.isEmpty) {
          APIWrap.instance.repoRefs(repo).then((res) {
            context.read<RepoModel>().refs = res;
          });
        }
      },
      title: SizedBox(
        height: 32,
        child: IconText(
          icon: DefaultIcons.branch,
          // text: Text(context.select<RepoModel, String?>((RepoModel model) {
          //       print("=========更新");
          //       return model.ref;
          //     }) ??
          //     repo.defaultBranchRef.name),
          // 实际测试使用Selector可以比context.select要少些刷新次数
          text: Selector<RepoModel, String?>(
              selector: (_, model) => model.ref,
              builder: (_, ref, __) {
                //print("=========更新");
                //print("ref=$ref, default=${repo.defaultBranchRef.name}");
                return Text(ref ?? repo.defaultBranchRef.name);
              }),
        ),
      ),
    );
  }
}
