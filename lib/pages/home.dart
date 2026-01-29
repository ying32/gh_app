import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:github/github.dart';
import 'package:provider/provider.dart';

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

  int currentIndex = 0;
  List<Tab> tabs = [
    Tab(
      text: const Text('主页'),
      icon: const GitHubIcon(size: 20),
      closeIcon: null,
      body: Card(
        child: Column(
          children: [
            Selector<CurrentUserModel, CurrentUser?>(
              selector: (_, model) => model.user,
              builder: (context, user, __) {
                return UserInfoPanel(user);
              },
            ),
            //
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

                    gitHubAPI.graphql.query(test1, statusCode: 200).then((e) {
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
    )
  ];

  /// Creates a tab for the given index
  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      text: Text('Document $index'),
      semanticLabel: 'Document #$index',
      icon: const FlutterLogo(),
      body: Container(
        color:
            Colors.accentColors[Random().nextInt(Colors.accentColors.length)],
      ),
      onClosed: () {
        setState(() {
          tabs.remove(tab);
          if (currentIndex > 0) currentIndex--;
        });
      },
    );
    return tab;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      content: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        child: TabView(
          tabs: tabs,
          currentIndex: currentIndex,
          onChanged: (index) => setState(() => currentIndex = index),
          tabWidthBehavior: TabWidthBehavior.sizeToContent,
          closeButtonVisibility: CloseButtonVisibilityMode.always,
          // showScrollButtons: true,
          // wheelScroll: false,
          // onNewPressed: () {
          //   setState(() {
          //     final index = tabs.length + 1;
          //     final tab = generateTab(index);
          //     tabs.add(tab);
          //   });
          // },
          // onReorder: (oldIndex, newIndex) {
          //   setState(() {
          //     if (oldIndex < newIndex) {
          //       newIndex -= 1;
          //     }
          //     final item = tabs!.removeAt(oldIndex);
          //     tabs!.insert(newIndex, item);
          //
          //     if (currentIndex == newIndex) {
          //       currentIndex = oldIndex;
          //     } else if (currentIndex == oldIndex) {
          //       currentIndex = newIndex;
          //     }
          //   });
          // },
        ),
      ),
    );
  }
}
