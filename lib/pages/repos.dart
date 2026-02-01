import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/page.dart';
import 'package:gh_app/widgets/repo_widgets.dart';

class ReposPage extends StatelessWidget with PageMixin {
  const ReposPage({super.key, this.owner = ''});

  final String owner;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: APIWrap.instance.userRepos(owner),
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: ProgressRing());
        }
        if (snapshot.hasError) {
          return errorDescription(snapshot.error);
        }
        return RepoListView(repos: snapshot.data ?? const QLList.empty());
      },
    );
  }
}
