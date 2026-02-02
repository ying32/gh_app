import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:provider/provider.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage(this.user, {super.key});

  final QLUser? user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          SizedBox(width: 240, child: UserInfoPanel(user)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
            child: Divider(
              direction: Axis.vertical,
            ),
          ),
          if (user != null && (user!.pinnedItems?.isNotEmpty ?? false))
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '置顶的', //Pinned
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    // child: Row(
                    //   children: [
                    //     Text(
                    //       'Pinned',
                    //       style: TextStyle(
                    //           fontWeight: FontWeight.w500, fontSize: 16),
                    //     ),
                    //     Spacer(),
                    //     Text('自定义你的Pins'),
                    //   ],
                    // ),
                  ),
                  Wrap(
                    children: (user as QLUser)
                        .pinnedItems!
                        .map((e) => SizedBox(
                            width: 300,
                            child: RepoListItem(e, isPinStyle: true)))
                        .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static void createNewTab(BuildContext context, QLUser user) {
    context.read<TabviewModel>().addTab(
          UserInfoPage(user),
          key: ValueKey("${RouterTable.user}/${user.login}"),
          title: user.name,
          icon: const DefaultIcon.user(),
        );
  }
}
