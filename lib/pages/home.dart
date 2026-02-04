import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/pages/user_info.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: kPageDefaultVerticalPadding,
        // start: PageHeader.horizontalPadding(context),
        end: PageHeader.horizontalPadding(context),
      ),
      // 这里要做登录/登出监视，先不管了
      child: Card(
        child: Selector<CurrentUserModel, QLUser?>(
            selector: (_, model) => model.user,
            builder: (_, user, __) => EasyListViewRefresher(
                  onRefresh: (controller) async {
                    try {
                      final user = await APIWrap.instance.refreshCurrentUser();
                      if (user != null) {
                        //ignore: use_build_context_synchronously
                        context.read<CurrentUserModel>().user = user;
                      }
                      controller.refreshCompleted();
                    } on GitHubGraphQLError catch (e) {
                      if (e.isBadCredentials) {
                        //ignore: use_build_context_synchronously
                        context.read<CurrentUserModel>().clearLogin();
                      }
                      controller.refreshFailed();
                    } catch (e) {
                      controller.refreshFailed();
                    }
                  },
                  listview: ListView(
                    children: [
                      if (user != null) UserInfoPage(user),
                    ],
                  ),
                )),
      ),
    );
  }
}
