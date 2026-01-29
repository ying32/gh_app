import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:github/github.dart';
import 'package:provider/provider.dart';

import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
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
    return ScaffoldPage(
      content: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          // start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        // 这里要做登录/登出监视，先不管了
        child: gitHubAPI.isAnonymous
            ? const LoginPage()
            : Card(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Selector<CurrentUserModel, CurrentUser?>(
                      selector: (_, model) => model.user,
                      builder: (context, user, __) {
                        if (user == null) return const SizedBox.shrink();
                        return UserInfoPanel(user);
                      },
                    ),
                    Expanded(
                      child: FutureBuilder(
                        future: GithubCache.instance.currentUserNotifications,
                        builder: (_, snapshot) {
                          if (!snapshotIsOk(snapshot)) {
                            return const SizedBox.shrink();
                          }
                          return ListView.separated(
                            itemCount: snapshot.data?.length ?? 0,
                            itemBuilder: (BuildContext context, int index) {
                              final item = snapshot.data![index];
                              return ListTile(
                                title: Text("${item.reason}"),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(size: 1),
                          );
                          //
                        },
                      ),
                    ),
                    //
                    if (kDebugMode)
                      Button(
                          child: const Text('GraphQl测试'),
                          onPressed: () {
                            if (kDebugMode) {
                              print("开始测试");
                              // 查询: { "query": "query { viewer { login }" }
                              // 返回数据：
                              // {"data":{"viewer":{"login":"ying32"}}}
                              const test1 = 'query { viewer { login } }';
                              // ={"data":{"organization":{"membersWithRole":{"edges":[{"node":{"name":"Matt Todd","avatarUrl
                              const test2 = '''query {
            organization(login:"github") {
            membersWithRole(first: 100) {
              edges {
        node {
          name
          avatarUrl
        }
              }
            }
          }
        }''';
                              gitHubAPI.graphql
                                  .query(test1, statusCode: 200)
                                  .then((e) {
                                if (e is Map) {
                                  print("返回结果=状态=$e");
                                } else {
                                  print("返回结果=状态=${e.statusCode}, ${e.body}");
                                }
                              }).onError((e, s) {
                                print("错误=$e");
                              });
                            }
                          }),
                  ],
                ),
              ),
      ),
    );
  }
}
