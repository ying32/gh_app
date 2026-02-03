import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as mat;
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/pages/user_info.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:provider/provider.dart';

import 'login.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildBody(BuildContext context, QLUser? user) {
    return mat.RefreshIndicator(
      onRefresh: () async {
        final user = await APIWrap.instance.refreshCurrentUser();
        if (user != null) {
          //ignore: use_build_context_synchronously
          context.read<CurrentUserModel>().user = user;
        }
      },
      child: ListView(
        children: [
          if (user != null) UserInfoPage(user),
        ],
      ),
    );
  }

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
            builder: (_, user, __) => gitHubAPI.isAnonymous
                ? const LoginPage()
                : _buildBody(context, user)),
      ),
    );
  }
}
