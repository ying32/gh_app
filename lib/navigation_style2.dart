import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/pages/login.dart';
import 'package:gh_app/router.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:gh_app/widgets/window_buttons.dart';
import 'package:github/github.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';
import 'package:window_manager/window_manager.dart';

class NavigationStyle2Page extends StatefulWidget {
  const NavigationStyle2Page({
    super.key,
    required this.child,
    required this.shellContext,
  });

  final Widget child;
  final BuildContext? shellContext;

  @override
  State<NavigationStyle2Page> createState() => _NavigationStyle2PageState();
}

class _PaneItemIcon extends StatelessWidget {
  const _PaneItemIcon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 18);
  }
}

class _NavigationStyle2PageState extends State<NavigationStyle2Page>
    with WindowListener {
  bool value = false;

  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  final searchKey = GlobalKey(debugLabel: 'Search Bar Key');
  final searchFocusNode = FocusNode();
  final searchController = TextEditingController();

  late final List<NavigationPaneItem> originalItems = [
    PaneItem(
      key: const ValueKey(RouterTable.root),
      icon: const _PaneItemIcon(Remix.home_line),
      title: const Text('主页'),
      body: const SizedBox.shrink(),
    ),
    PaneItem(
      key: const ValueKey(RouterTable.issues),
      icon: const _PaneItemIcon(Remix.issues_line),
      title: const Text('问题'),
      body: const SizedBox.shrink(),
    ),
    PaneItem(
      key: const ValueKey(RouterTable.pulls),
      icon: const _PaneItemIcon(Remix.git_pull_request_line),
      title: const Text('合并请求'),
      body: const SizedBox.shrink(),
    ),
    PaneItem(
      key: const ValueKey(RouterTable.repos),
      icon: const _PaneItemIcon(Remix.git_repository_line),
      title: const Text('仓库'),
      body: const SizedBox.shrink(),
    ),
  ].map<NavigationPaneItem>((e) {
    return PaneItem(
      key: e.key,
      icon: e.icon,
      title: e.title,
      body: e.body,
      onTap: () {
        pushRoute(context, (e.key as ValueKey).value);
        e.onTap?.call();
      },
    );
  }).toList();
  // 底部的
  late final List<NavigationPaneItem> footerItems = [
    PaneItemSeparator(),
    PaneItem(
      key: const ValueKey(RouterTable.settings),
      icon: const _PaneItemIcon(Remix.settings_line),
      title: const Text('设置'),
      body: const SizedBox.shrink(),
      onTap: () {
        pushRoute(context, RouterTable.settings);
      },
    ),
    _LinkPaneItemAction(
      icon: const _PaneItemIcon(FluentIcons.open_source),
      title: const Text('源代码'),
      link: 'https://github.com/ying32/gh_app',
      body: const SizedBox.shrink(),
    ),
  ];

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
    // 获取当前user
    GithubCache.instance.currentUser.then((e) {
      context.read<CurrentUserModel>().user = e;
      if (mounted) {}
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int indexOriginal = originalItems
        .where((item) => item.key != null)
        .toList()
        .indexWhere((item) => item.key == Key(location));

    if (indexOriginal == -1) {
      int indexFooter = footerItems
          .where((element) => element.key != null)
          .toList()
          .indexWhere((element) => element.key == Key(location));
      if (indexFooter == -1) {
        return 0;
      }
      return originalItems
              .where((element) => element.key != null)
              .toList()
              .length +
          indexFooter;
    } else {
      return indexOriginal;
    }
  }

  void _onGoToRepo() {
    GoGithubDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = FluentLocalizations.of(context);

    final appTheme = context.watch<AppTheme>();
    final theme = FluentTheme.of(context);
    if (widget.shellContext != null) {
      if (router.canPop() == false) {
        setState(() {});
      }
    }

    return NavigationView(
      key: viewKey,
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        // leading: () {
        //   final enabled = widget.shellContext != null && router.canPop();
        //
        //   final onPressed = enabled
        //       ? () {
        //           if (router.canPop()) {
        //             context.pop();
        //             setState(() {});
        //           }
        //         }
        //       : null;
        //   return NavigationPaneTheme(
        //     data: NavigationPaneTheme.of(context).merge(NavigationPaneThemeData(
        //       unselectedIconColor: ButtonState.resolveWith((states) {
        //         if (states.isDisabled) {
        //           return ButtonThemeData.buttonColor(context, states);
        //         }
        //         return ButtonThemeData.uncheckedInputColor(
        //           FluentTheme.of(context),
        //           states,
        //         ).basedOnLuminance();
        //       }),
        //     )),
        //     child: Builder(
        //       builder: (context) => PaneItem(
        //         icon: const Center(child: Icon(FluentIcons.back, size: 12.0)),
        //         title: Text(localizations.backButtonTooltip),
        //         body: const SizedBox.shrink(),
        //         enabled: enabled,
        //       ).build(
        //         context,
        //         false,
        //         onPressed,
        //         displayMode: PaneDisplayMode.compact,
        //       ),
        //     ),
        //   );
        // }(),
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
          Selector<CurrentUserModel, CurrentUser?>(
            selector: (_, model) => model.user,
            builder: (context, user, __) {
              return const SizedBox
                  .shrink(); // UserHeadImageName(user, imageSize: 48, onlyNickName: true);
            },
          ),
          const SizedBox(width: 10),
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
          IconPopupMenu(
            icon: const Icon(Remix.menu_line, size: 18),
            tooltip: '菜单',
            items: [
              MenuFlyoutItem(text: const Text('跳转仓库'), onPressed: _onGoToRepo),
              // MenuFlyoutSeparator(),
            ],
          ),
          const SizedBox(width: 10),
          const WindowButtons(),
        ]),
      ),
      paneBodyBuilder: (item, child) {
        final name =
            item?.key is ValueKey ? (item!.key as ValueKey).value : null;
        return FocusTraversalGroup(
          key: ValueKey('body$name'),
          child: widget.child,
        );
      },
      content: gitHubAPI.isAnonymous ? const LoginPage() : null,
      pane: gitHubAPI.isAnonymous
          ? null
          : NavigationPane(
              selected: _calculateSelectedIndex(context),
              header: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: GitHubIcon(size: 32),
              ),
              // header: UserInfoPanel(user: _currentUser),
              // displayMode: PaneDisplayMode.minimal, // appTheme.displayMode,
              displayMode: PaneDisplayMode.compact, // appTheme.displayMode,
              //indicator: const StickyNavigationIndicator(),

              items: originalItems,
              // autoSuggestBox: Builder(builder: (context) {
              //   return AutoSuggestBox(
              //     key: searchKey,
              //     focusNode: searchFocusNode,
              //     controller: searchController,
              //     unfocusedColor: Colors.transparent,
              //     items: <PaneItem>[].map((item) {
              //       assert(item.title is Text);
              //       final text = (item.title as Text).data!;
              //       return AutoSuggestBoxItem(
              //         label: text,
              //         value: text,
              //         onSelected: () {
              //           item.onTap?.call();
              //           searchController.clear();
              //           searchFocusNode.unfocus();
              //           final view = NavigationView.of(context);
              //           if (view.compactOverlayOpen) {
              //             view.compactOverlayOpen = false;
              //           } else if (view.minimalPaneOpen) {
              //             view.minimalPaneOpen = false;
              //           }
              //         },
              //       );
              //     }).toList(),
              //     trailingIcon: IgnorePointer(
              //       child: IconButton(
              //         onPressed: () {},
              //         icon: const Icon(FluentIcons.search),
              //       ),
              //     ),
              //     placeholder: '搜索',
              //   );
              // }),
              // autoSuggestBoxReplacement: const Icon(FluentIcons.search),
              footerItems: footerItems,
            ),
      onOpenSearch: searchFocusNode.requestFocus,
    );
  }

  @override
  void onWindowClose() {
    ExitAppDialog.show(context, mounted);
  }
}

class _LinkPaneItemAction extends PaneItem {
  _LinkPaneItemAction({
    required super.icon,
    required this.link,
    required super.body,
    super.title,
  });

  final String link;

  @override
  Widget build(
    BuildContext context,
    bool selected,
    VoidCallback? onPressed, {
    PaneDisplayMode? displayMode,
    bool showTextOnTop = true,
    bool? autofocus,
    int? itemIndex,
  }) {
    return Link(
      uri: Uri.parse(link),
      builder: (context, followLink) => Semantics(
        link: true,
        child: super.build(
          context,
          selected,
          followLink,
          displayMode: displayMode,
          showTextOnTop: showTextOnTop,
          itemIndex: itemIndex,
          autofocus: autofocus,
        ),
      ),
    );
  }
}
