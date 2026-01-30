import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:github/github.dart';
import 'package:provider/provider.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage(this.user, {super.key});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return UserInfoPanel(user);
  }

  static void createNewTab(BuildContext context, User user) {
    context.read<TabviewModel>().addTab(
          // ChangeNotifierProvider<RepoModel>(
          //   create: (_) => RepoModel(repo),
          //   child: const RepoPage(),
          // ),
          UserInfoPage(user),
          key: ValueKey("${RouterTable.user}/${user.login ?? ''}"),
          title: user.name ?? user.login ?? '未知',
          icon: Remix.user_line,
        );
  }
}
