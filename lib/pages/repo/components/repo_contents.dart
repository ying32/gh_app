import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';
import 'package:provider/provider.dart';

import 'content_view.dart';

/// 仓库目录列表
class RepoContents extends StatelessWidget {
  const RepoContents({
    super.key,
    this.path = "",
    this.ref,
    required this.onPathChange,
  });

  final String path;
  final String? ref;
  final ValueChanged<String> onPathChange;

  Widget _buildItem(GitHubFile file) {
    final isFile = file.type == "file";
    return ListTile(
      leading: SizedBox(
        width: 24,
        child: isFile
            ? FileIcon(file.name ?? '', size: 24)
            : Icon(Remix.folder_fill, color: Colors.blue.lighter),
      ),
      title: Text(file.name ?? ''),
      //trailing: const SizedBox.shrink(),
      onPressed: () {
        onPathChange.call(file.path ?? '');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return SizedBox(
      width: double.infinity,
      child: FutureBuilder(
        future: GithubCache.instance.repoContents(repo, path, ref: ref),
        builder: (_, snapshot) {
          if (!snapshotIsOk(snapshot, false)) {
            return const Center(child: ProgressRing());
          }
          final contents = snapshot.data;
          if (contents == null) {
            return const SizedBox.shrink();
          }
          // 如果数据是文件，则显示内容
          if (contents.isFile) {
            print(
                "file encoding=${contents.file?.encoding}, type=${contents.file?.type}");
            return ContentView(contents.file!);
          }
          if (!contents.isDirectory || contents.tree == null) {
            return const SizedBox.shrink();
          }
          // 返回目录结构
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...contents.tree!
                  .where((e) => e.type == "dir")
                  .map((e) => _buildItem(e)),
              ...contents.tree!
                  .where((e) => e.type == "file")
                  .map((e) => _buildItem(e)),
            ],
          );
        },
      ),
    );
  }
}
