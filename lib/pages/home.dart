import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/pages/user_info.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:provider/provider.dart';

import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget _buildBody() {
    return Selector<CurrentUserModel, QLUser?>(
      selector: (_, model) => model.user,
      builder: (context, user, __) {
        if (user == null) return const SizedBox.shrink();
        return UserInfoPage(user);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // assert(debugCheckHasFluentTheme(context));
    // final theme = FluentTheme.of(context);
    // padding: EdgeInsetsDirectional.only(
    //   bottom: kPageDefaultVerticalPadding,
    //   start: PageHeader.horizontalPadding(context),
    //   end: PageHeader.horizontalPadding(context),
    // ),
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: kPageDefaultVerticalPadding,
        // start: PageHeader.horizontalPadding(context),
        end: PageHeader.horizontalPadding(context),
      ),
      // 这里要做登录/登出监视，先不管了
      child: gitHubAPI.isAnonymous ? const LoginPage() : _buildBody(),
    );
  }
}
