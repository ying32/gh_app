import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/pages/graphql_test.dart';
import 'package:gh_app/pages/home.dart';
import 'package:gh_app/pages/issues.dart';
import 'package:gh_app/pages/login.dart';
import 'package:gh_app/pages/pulls.dart';
import 'package:gh_app/pages/repos.dart';
import 'package:gh_app/pages/search.dart';
import 'package:gh_app/pages/settings.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
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

  ValueKey<String> key;
  String title;
  Widget icon;
  Widget body;
}

class _NavItemIconButton extends StatelessWidget {
  const _NavItemIconButton(
    this.item, {
    this.disabled = false,
  });

  final _NavItem item;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: IconButton(
            icon: item.icon,
            onPressed: disabled
                ? null
                : () {
                    context.read<TabViewModel>().addTab(
                        key: item.key,
                        item.body,
                        title: item.title,
                        icon: item.icon);
                  }),
      ),
    );
  }
}

class _UserHeadImageButton extends StatelessWidget {
  const _UserHeadImageButton();

  @override
  Widget build(BuildContext context) {
    return UserSelector(
      builder: (context, user) {
        if (user == null) {
          return const ApplicationIcon(size: 40);
        }
        return ActorHeadImage(
          user,
          imageSize: 40,
          tooltip: user.name.isEmpty ? user.login : user.name,
          onPressed: () {
            launchUrl(Uri.parse(user.url));
          },
        );
      },
    );
  }
}

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TabViewModel>(
        create: (_) => TabViewModel([
              Tab(
                key: const ValueKey(RouterTable.root),
                text: const Text('我的'),
                // semanticLabel: 'Document #$index',
                icon: const DefaultIcon.home(),
                body: const HomePage(),
                closeIcon: const SizedBox.shrink(),
                onClosed: null,
              )
            ]),
        child: const _InternalNavigationPage());
  }
}

class _LeftNav extends StatelessWidget {
  _LeftNav();

  /// 需要登录才能使用的
  final List<_NavItem> _currentUserItems = [
    _NavItem(
      key: const ValueKey("${RouterTable.issues}/viewer"),
      icon: const DefaultIcon.issues(size: 18),
      title: '问题',
      body: const IssuesPage(),
    ),
    _NavItem(
      key: const ValueKey("${RouterTable.pulls}/viewer"),
      icon: const DefaultIcon.pullRequest(size: 18),
      title: '合并请求',
      // body: const PullRequestPage(),
      body: const PullPage(),
    ),
    _NavItem(
      key: const ValueKey("${RouterTable.repos}/viewer"),
      icon: const DefaultIcon.repository(size: 18),
      title: '我的仓库',
      body: const ReposPage(),
    ),
    _NavItem(
      key: const ValueKey("${RouterTable.stars}/viewer"),
      icon: const DefaultIcon.star(size: 18),
      title: '我点赞的仓库',
      body: const ReposPage(isStarred: true),
    ),
  ];

  final List<_NavItem> _otherItems = [
    _NavItem(
      key: const ValueKey(RouterTable.search),
      icon: const DefaultIcon.search(size: 18),
      title: '搜索',
      body: const SearchPage(),
    ),
  ];

  // 底部的
  final List<_NavItem> _footerItems = [
    _NavItem(
      key: const ValueKey(RouterTable.settings),
      icon: const DefaultIcon.settings(size: 18),
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
        // if (Platform.isMacOS)
        const _UserHeadImageButton(),
        ..._currentUserItems.map((e) => _NavItemIconButton(e)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(),
        ),
        ..._otherItems.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _NavItemIconButton(e),
            )),
        if (kDebugMode) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: Divider(direction: Axis.horizontal),
          ),
          const OpenGraphQLIconButton(),
        ],
        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(),
        ),
        ..._footerItems.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _NavItemIconButton(e),
            )),
        const IconLinkButton.linkSource(appRepoUrl, message: '源代码'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(),
        ),
        const AppAboutButton(),
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
          child: SimplifySelector<TabViewModel, ({List<Tab> tabs, int index})>(
            selector: (model) => (tabs: model.tabs, index: model.currentIndex),
            builder: (_, value) => TabView(
              tabs: value.tabs,
              currentIndex: value.index,
              onChanged: (index) {
                context.read<TabViewModel>().currentIndex = index;
              },
              shortcutsEnabled: false,
              tabWidthBehavior: TabWidthBehavior.sizeToContent,
              closeButtonVisibility: CloseButtonVisibilityMode.always,
              showScrollButtons: false,
              onNewPressed: () {
                GoGithubDialog.show(context, onSuccess: (data) {
                  goMainTabView(context, data);
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
  // String? _lastClipboardText;

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
    // 获取当前user
    APIWrap.instance.currentUser(onSecondUpdate: (value) {
      context.read<CurrentUserModel>().user = value;
    }).then((data) {
      context.read<CurrentUserModel>().user = data;
    }).onError((e, s) {
      if (e is GitHubGraphQLError && e.isBadCredentials) {
        context.read<CurrentUserModel>().clearLogin();
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        height: Platform.isMacOS ? 30.0 : 40.0,
        // leading: !Platform.isMacOS
        //     ? const Center(child: _UserHeadImageButton())
        //     : null,
        automaticallyImplyLeading: false,
        title: Platform.isMacOS
            ? null
            : const DragToMoveArea(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    appTitle,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
        actions: Platform.isMacOS
            ? null
            : Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
                const WindowButtons(),
              ]),
      ),
      content: UserSelector(builder: (_, user) {
        return gitHubAPI.isAnonymous ? const LoginPage() : const _MainTabView();
      }),
    );
  }

  @override
  void onWindowClose() {
    ExitAppDialog.show(context);
  }
}
