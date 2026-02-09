part of '../../repo.dart';

/// 仓库目录列表
class RepoTreeEntriesView extends StatelessWidget {
  const RepoTreeEntriesView({
    super.key,
  });

  Widget _buildItem(BuildContext context, QLTreeEntry tree) {
    return ListTile(
      leading: SizedBox(
        width: 24,
        child: tree.isFile
            ? FileIcon(tree.name, size: 24)
            : tree.isSubmodule
                ? const DefaultIcon.submodule(color: Colors.grey)
                : DefaultIcon.folder(color: Colors.blue.lighter),
      ),
      title: Text(tree.name),
      onPressed: () {
        if (tree.isSubmodule) {
          showInfoDialog('当前为一个子模块，暂不能跳转',
              context: context, severity: InfoBarSeverity.warning);
          //TODO: 这里考虑下是不是跳到仓库去
          //print('object=${file.submodule?.gitUrl}');
          return;
        }
        context.read<RepoModel>().path = tree.path;
      },
    );
  }

  // 构建目录，这个还可以再优化的，不使用Column，暂时先这样吧
  Widget _buildTree(BuildContext context, List<QLTreeEntry> entries) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...entries
              .where((e) => e.isDir || e.isSubmodule)
              .map((e) => _buildItem(context, e)),
          ...entries.where((e) => e.isFile).map((e) => _buildItem(context, e)),
        ],
      );

  Widget _buildContent(
      BuildContext context, QLGitObject object, QLRepository repo) {
    // 如果数据是文件，则显示内容
    if (object.isFile) {
      if (kDebugMode) {
        print("file isBinary =${object.blob?.isBinary}");
      }
      // blob不为null时
      if (object.blob != null && object.blob!.text != null) {
        return SizedBox(
          width: double.infinity,
          child: RepoFileContentView(
            object.blob!,
            filename: p.basename(context.read<RepoModel>().path),
          ),
        );
      }
      //TODO: 这里待完善
      return const Text('还没做内容的哈');
      //return RepoContentView(contents.file!);
    }
    if (object.tree?.entries == null) {
      return const SizedBox.shrink();
    }
    // 返回目录结构
    return _buildTree(context, object.tree!.entries);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        // 监视文件对象改变
        Selector<RepoModel, QLGitObject?>(
            selector: (_, model) => model.object,
            builder: (_, object, __) {
              if (object == null) {
                return SizedBox(
                    height: MediaQuery.of(context).size.height / 2,
                    child: const LoadingRing());
              }
              return _buildContent(
                  context, object, context.read<RepoModel>().repo);
            }),
      ],
    );
  }
}
