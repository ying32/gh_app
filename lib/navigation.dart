import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/pages/graphql_test.dart';
import 'package:gh_app/pages/home.dart';
import 'package:gh_app/pages/issues.dart';
import 'package:gh_app/pages/pulls.dart';
import 'package:gh_app/pages/repo.dart';
import 'package:gh_app/pages/repos.dart';
import 'package:gh_app/pages/search.dart';
import 'package:gh_app/pages/settings.dart';
import 'package:gh_app/pages/user_info.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

class _NavItem {
  _NavItem({
    required this.key,
    required this.title,
    required this.icon,
    required this.body,
  });
  ValueKey key;
  String title;
  IconData icon;
  Widget body;
}

class _NavItemIconButton extends StatelessWidget {
  const _NavItemIconButton(this.item);

  final _NavItem item;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: IconButton(
            icon: Icon(item.icon, size: 18),
            onPressed: () {
              context.read<TabviewModel>().addTab(
                  key: item.key, item.body, title: item.title, icon: item.icon);
            }),
      ),
    );
  }
}

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TabviewModel>(
        create: (_) => TabviewModel([
              Tab(
                  key: const ValueKey(RouterTable.root),
                  text: const Text('我的'),
                  // semanticLabel: 'Document #$index',
                  icon: const Icon(Remix.home_line),
                  body: const HomePage(),
                  closeIcon: FluentIcons.emoji,
                  onClosed: null)
            ]),
        child: const _InternalNavigationPage());
  }
}

class _LeftNav extends StatelessWidget {
  _LeftNav();

  final List<_NavItem> originalItems = [
    _NavItem(
      key: const ValueKey(RouterTable.issues),
      icon: Remix.issues_line,
      title: '问题',
      body: const IssuesPage(),
    ),
    _NavItem(
      key: const ValueKey(RouterTable.pulls),
      icon: Remix.git_pull_request_line,
      title: '合并请求',
      // body: const PullRequestPage(),
      body: const PullPage(),
    ),
    _NavItem(
      key: const ValueKey(RouterTable.repos),
      icon: Remix.git_repository_line,
      title: '我的仓库',
      body: const ReposPage(),
    ),
    // todo: 还没写哈
    _NavItem(
      key: const ValueKey(RouterTable.repos),
      icon: Remix.star_line,
      title: '我收藏的仓库',
      //body: const ReposPage(),
      body: const SizedBox.shrink(),
    ),
    _NavItem(
      key: const ValueKey(RouterTable.search),
      icon: Remix.search_line,
      title: '搜索',
      body: const SearchPage(),
    ),
  ];
  // 底部的
  final List<_NavItem> footerItems = [
    _NavItem(
      key: const ValueKey(RouterTable.settings),
      icon: Remix.settings_line,
      title: '设置',
      body: const SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...originalItems.map((e) => _NavItemIconButton(e)),
        if (kDebugMode) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(direction: Axis.horizontal),
          ),
          const OpenGraphQLIconButton(),
        ],
        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(direction: Axis.horizontal),
        ),
        ...footerItems.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _NavItemIconButton(e),
            )),
        const LinkAction(
          message: '源代码',
          icon: Icon(FluentIcons.open_source, size: 18),
          link: appRepoUrl,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MainTabView extends StatelessWidget {
  const _MainTabView();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 50, child: _LeftNav()),
        Expanded(
          child: Selector<TabviewModel, ({List<Tab> tabs, int index})>(
            selector: (_, model) =>
                (tabs: model.tabs, index: model.currentIndex),
            builder: (_, value, __) => TabView(
              tabs: value.tabs,
              currentIndex: value.index,
              onChanged: (index) {
                context.read<TabviewModel>().currentIndex = index;
              },
              tabWidthBehavior: TabWidthBehavior.sizeToContent,
              closeButtonVisibility: CloseButtonVisibilityMode.always,
              showScrollButtons: false,
              onNewPressed: () {
                GoGithubDialog.show(context, onSuccess: (data) {
                  if (data is QLRepository) {
                    RepoPage.createNewTab(context, data);
                  } else if (data is QLUser) {
                    // 创建User页面
                    UserInfoPage.createNewTab(context, data);
                  }
                });
              },
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
        ),
      ],
    );
  }
}

class _InternalNavigationPage extends StatefulWidget {
  const _InternalNavigationPage();

  @override
  State<_InternalNavigationPage> createState() =>
      _InternalNavigationPageState();
}

class _InternalNavigationPageState extends State<_InternalNavigationPage>
    with WindowListener {
  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');

  String? _lastClipboardText;

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
    // 获取当前user
    APIWrap.instance.currentUser.then((e) {
      context.read<CurrentUserModel>().user = e;
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final localizations = FluentLocalizations.of(context);

    // final appTheme = context.watch<AppTheme>();
    // final theme = FluentTheme.of(context);
    // if (widget.shellContext != null) {
    //   if (router.canPop() == false) {
    //     setState(() {});
    //   }
    // }
//  ChangeNotifierProvider<CurrentUserModel>(
//           create: (_) => CurrentUserModel(null),
//         ),
    return NavigationView(
      key: viewKey,
      appBar: NavigationAppBar(
        leading: const GitHubIcon(size: 32),
        automaticallyImplyLeading: false,
        title: () {
          return const DragToMoveArea(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                appTitle,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }(),
        actions: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Selector<CurrentUserModel, QLUser?>(
            selector: (_, model) => model.user,
            builder: (context, user, __) {
              if (user == null) return const SizedBox.shrink();
              return Row(
                children: [
                  UserHeadImage(user.avatarUrl, imageSize: 40),
                  const SizedBox(width: 8.0),
                  LinkStyleButton(
                    text: UserNameWidget(user, onlyNickName: true),
                    onPressed: () {
                      launchUrl(Uri.parse(user.url));
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
          if (kDebugMode)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: ToggleSwitch(
                  content: const Text('深色模式'),
                  checked: FluentTheme.of(context).brightness.isDark,
                  onChanged: (v) {
                    if (v) {
                      appTheme.mode = ThemeMode.dark;
                    } else {
                      appTheme.mode = ThemeMode.light;
                    }
                  },
                ),
              ),
            ),
          const SizedBox(width: 10),
          const WindowButtons(),
        ]),
      ),
      content: const _MainTabView(),
    );
  }

  @override
  void onWindowClose() {
    ExitAppDialog.show(context, mounted);
  }

  @override
  void onWindowFocus() {
    Clipboard.getData('text/plain').then((e) {
      if (_lastClipboardText != e?.text) {
        _lastClipboardText = e?.text;
        // TODO: 待写。这里检测，当解析出来的是github链接，弹出跳转提示
        if (kDebugMode) {
          print("_lastClipboardText=$_lastClipboardText");
        }
      }
    });
  }
}
