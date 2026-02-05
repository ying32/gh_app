part of '../../repo.dart';

/// 仓库路径导航指示条
class RepoBreadcrumbBar extends StatelessWidget {
  const RepoBreadcrumbBar({super.key, this.repo});

  final QLRepository? repo;

  @override
  Widget build(BuildContext context) {
    //return Consumer<RepoModel>(
    return Selector<RepoModel, List<String>>(
      selector: (_, model) => model.segmentedPaths,
      builder: (context, segmentedPaths, __) {
        final r = repo ?? context.read<RepoModel>().repo;
        return BreadcrumbBar(
          items: segmentedPaths
              .map((e) => BreadcrumbItem(
                  label: Text(e.isEmpty ? r.name : e,
                      style: TextStyle(color: Colors.blue)),
                  value: e))
              .toList(),
          onItemPressed: (item) {
            final key = "/${item.value}";
            final model = context.read<RepoModel>();
            final path = "/${model.path}";
            final pos = path.indexOf(key);
            if (pos != -1) {
              model.path = path.substring(1, pos + key.length);
            } else {
              model.path = "";
            }
          },
        );
      },
    );
  }
}
