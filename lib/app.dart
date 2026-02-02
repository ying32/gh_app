import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:provider/provider.dart';

import 'models/user_model.dart';
import 'navigation.dart';

///  用于pc端下支持手势的
class CustomMaterialScrollBehavior extends FluentScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class AppProvider extends StatelessWidget {
  const AppProvider({super.key, this.child, this.builder});

  final Widget? child;
  final TransitionBuilder? builder;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentUserModel>(
          create: (_) => CurrentUserModel(null),
        ),
        ChangeNotifierProvider<AppTheme>(
          create: (_) => appTheme,
        ),
      ],
      builder: builder,
      child: child,
    );
  }
}

class GithubApp extends StatelessWidget {
  const GithubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProvider(
      builder: (context, child) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          darkTheme: FluentThemeData(
            fontFamily: appTheme.fontFamily,
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            selectionColor: Colors.blue.lightest.withOpacity(0.5),
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
            resources: const ResourceDictionary.dark(
                // cardBackgroundFillColorDefault: Color(0xd2000000),
                ),
          ),
          theme: FluentThemeData(
            fontFamily: appTheme.fontFamily,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            selectionColor: Colors.blue.lightest.withOpacity(0.5),
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
            // flutter\packages\flutter\lib\src\material\desktop_text_selection_toolbar.dart
            // _defaultToolbarBuilder, 发现他上下文菜单使用了card的背景色，过于透明，效果反而不好
            resources: const ResourceDictionary.light(
                // cardBackgroundFillColorDefault: Color(0xd2ffffff),
                ),
          ),
          locale: appTheme.locale,
          scrollBehavior: CustomMaterialScrollBehavior(),
          home: const NavigationPage(),
        );
      },
    );
  }
}
