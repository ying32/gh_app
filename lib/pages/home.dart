import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/pages/user_info.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _onRefresh(BuildContext context, RefreshController controller) async {
    try {
      final user = await APIWrap.instance.currentUser(force: true);
      if (user != null) {
        //ignore: use_build_context_synchronously
        context.curUser.user = user;
      }
      controller.refreshCompleted();
      controller.resetNoData();
    } on GitHubGraphQLError catch (e) {
      if (e.isBadCredentials) {
        //ignore: use_build_context_synchronously
        context.curUser.clearLogin();
      }
      controller.refreshFailed();
    } catch (e) {
      controller.refreshFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: kPageDefaultVerticalPadding,
        // start: PageHeader.horizontalPadding(context),
        end: PageHeader.horizontalPadding(context),
      ),
      child: Card(
        child: UserSelector(
            builder: (_, user) => user == null
                ? const LoadingRing()
                : EasyListViewRefresher(
                    onRefresh: (controller) => _onRefresh(context, controller),
                    listview: ListView(
                      children: [UserInfoPage(user)],
                    ),
                  )),
      ),
    );
  }
}
