import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:provider/provider.dart';

/// 导航指示器
class RepoBreadcrumbBar extends StatelessWidget {
  const RepoBreadcrumbBar({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RepoModel>().repo;
    return Selector<PathModel, List<String>>(
      selector: (_, model) => model.segmentedPaths,
      builder: (context, segmentedPaths, __) {
        return BreadcrumbBar(
          items: segmentedPaths
              .map((e) => BreadcrumbItem(
                  label: Text(e.isEmpty ? repo.name : e), value: e))
              .toList(),
          onItemPressed: (item) {
            final key = "/${item.value}";
            final model = context.read<PathModel>();
            final pos = model.path.indexOf(key);
            if (pos != -1) {
              model.path = model.path.substring(0, pos + key.length);
            }
          },
        );
      },
    );
  }
}
