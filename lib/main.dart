import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:gh_app/utils/config.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载配置
  await AppConfig.instance.init();
  createGithub(AppConfig.instance.auth);
  if (kDebugMode) {
    //print("AppConfig.instance.auth=${AppConfig.instance.auth.toJson()}");
  }

  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop) {
    // 这个在macos下需要提前
    await WindowManager.instance.ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      // 这个只能windows下使用，否则会有问题
      await flutter_acrylic.Window.initialize();
      await flutter_acrylic.Window.hideWindowControls();
    }

    // WindowOptions windowOptions = const WindowOptions(
    //   title: 'GitHub桌面板',
    //   size: Size(1200, 720),
    //   minimumSize: Size(500, 600),
    //   center: true,
    //   backgroundColor: Colors.transparent,
    //   skipTaskbar: false,
    //   titleBarStyle: TitleBarStyle.hidden,
    //   windowButtonVisibility: false,
    // );
    // windowManager.waitUntilReadyToShow(windowOptions, () async {
    //   await windowManager.show();
    //   await windowManager.focus();
    //   await windowManager.setPreventClose(true);
    // });
    final wSize =
        Platform.isWindows ? const Size(1280, 768) : const Size(1000, 720);
    await windowManager.setTitle(appTitle);
    await windowManager.setSize(wSize);
    await windowManager.setMinimumSize(wSize);
    await windowManager.center();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
          windowButtonVisibility: false);
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }

  runApp(const GithubApp());
}
