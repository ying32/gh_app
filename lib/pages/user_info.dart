import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:provider/provider.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage(this.user, {super.key});

  final QLUserOrOrganizationCommon? user;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 240,
            child:
                user == null ? const SizedBox.shrink() : UserInfoPanel(user!)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
          child: Divider(
            direction: Axis.vertical,
          ),
        ),
        if (user?.pinnedItems.isNotEmpty ?? false)
          Expanded(
            child: UserPinned(user!.pinnedItems),
          ),
      ],
    );
  }

  static void createNewTab(
      BuildContext context, QLUserOrOrganizationCommon user) {
    context.read<TabViewModel>().addTab(
          UserInfoPage(user),
          key: ValueKey("${RouterTable.user}/${user.login}"),
          title: user.name,
          icon: const DefaultIcon.user(),
        );
  }
}
