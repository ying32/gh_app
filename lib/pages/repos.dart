import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';

class ReposPage extends StatelessWidget {
  const ReposPage({super.key, this.owner = ''});

  final String owner;

  @override
  Widget build(BuildContext context) {
    return APIFutureBuilder(
      future: APIWrap.instance.userRepos(owner),
      builder: (_, snapshot) {
        return RepoListView(repos: snapshot);
      },
    );
  }
}
