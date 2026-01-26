import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/navigation.dart';
import 'package:gh_app/pages/followers.dart';
import 'package:gh_app/pages/following.dart';
import 'package:gh_app/pages/home.dart';
import 'package:gh_app/pages/issues.dart';
import 'package:gh_app/pages/login.dart';
import 'package:gh_app/pages/pulls.dart';
import 'package:gh_app/pages/repo.dart';
import 'package:gh_app/pages/repos.dart';
import 'package:gh_app/pages/settings.dart';
import 'package:github/github.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// push页面
void pushRoute(BuildContext context, String url, {Object? extra}) {
  if (GoRouterState.of(context).uri.toString() != url) {
    context.go(url, extra: extra);
  }
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
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(path: '/settings', builder: (context, state) => const Settings()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
          path: '/followers',
          builder: (context, state) => const FollowersPage()),
      GoRoute(
          path: '/following',
          builder: (context, state) => const FollowingPage()),
      GoRoute(path: '/issues', builder: (context, state) => const IssuesPage()),
      GoRoute(path: '/pulls', builder: (context, state) => const PullPage()),
      GoRoute(
          path: '/repos',
          builder: (context, state) => ReposPage(
                owner: state.extra != null && state.extra is String
                    ? state.extra as String
                    : '',
              )),
      GoRoute(
          path: '/repo',
          builder: (context, state) =>
              RepoPage(repo: state.extra as Repository)),
    ],
  ),
]);
