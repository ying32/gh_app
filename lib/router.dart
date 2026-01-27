import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/navigation.dart';
import 'package:gh_app/pages/followers.dart';
import 'package:gh_app/pages/following.dart';
import 'package:gh_app/pages/home.dart';
import 'package:gh_app/pages/issues.dart';
import 'package:gh_app/pages/login.dart';
import 'package:gh_app/pages/pulls.dart';
import 'package:gh_app/pages/repo/repo.dart';
import 'package:gh_app/pages/repos.dart';
import 'package:gh_app/pages/settings.dart';
import 'package:github/github.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/repo_model.dart';

/// 跳由表
class RouterTable {
  static const root = "/";
  static const settings = "/settings";
  static const login = "/login";
  static const followers = "/followers";
  static const following = "/following";
  static const issues = "/issues";
  static const pulls = "/pulls";
  static const repos = "/repos";
  static const repo = "/repo";
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// push页面
void pushRoute(BuildContext context, String url, {Object? extra}) {
  if (GoRouterState.of(context).uri.toString() != url) {
    context.go(url, extra: extra);
  }
}

/// shell页面的
void pushShellRoute(String url, {Object? extra}) {
  final context = _shellNavigatorKey.currentContext!;
  // if (GoRouterState.of(context).uri.toString() != url) {
  if (context.canPop()) {
    context.pop();
  }
  context.go(url, extra: extra);
  // } else {
  //  rootNavigatorKey.currentContext!.go(url, extra: extra);
  // }
}

void openInNewView(BuildContext context, Widget child) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(FluentPageRoute(builder: (context) {
    return child;
  }));
}

final router = GoRouter(navigatorKey: rootNavigatorKey, routes: [
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) {
      return NavigationPage(
        shellContext: _shellNavigatorKey.currentContext,
        child: child,
      );
    },
    routes: [
      GoRoute(
          path: RouterTable.root,
          builder: (context, state) => const HomePage()),
      GoRoute(
          path: RouterTable.settings,
          builder: (context, state) => const Settings()),
      GoRoute(
          path: RouterTable.login,
          builder: (context, state) => const LoginPage()),
      GoRoute(
          path: RouterTable.followers,
          builder: (context, state) => const FollowersPage()),
      GoRoute(
          path: RouterTable.following,
          builder: (context, state) => const FollowingPage()),
      GoRoute(
          path: RouterTable.issues,
          builder: (context, state) => const IssuesPage()),
      GoRoute(
          path: RouterTable.pulls,
          builder: (context, state) => const PullPage()),
      GoRoute(
          path: RouterTable.repos,
          builder: (context, state) => ReposPage(
                owner: state.extra != null && state.extra is String
                    ? state.extra as String
                    : '',
              )),
      GoRoute(
        path: RouterTable.repo,
        //builder: (context, state) => RepoPage(repo: state.extra as Repository),
        builder: (context, state) => MultiProvider(
          providers: [
            ChangeNotifierProvider<RepoModel>(
              create: (_) => RepoModel(state.extra as Repository),
            ),
            ChangeNotifierProvider<PathModel>(
              create: (_) => PathModel("/"),
            )
          ],
          child: const RepoPage(),
        ),
      ),
    ],
  ),
]);
