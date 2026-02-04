import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/foundation.dart';
import 'package:gh_app/utils/config.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

void main() async {
  if (!isDesktop) {
    // 不允许在非桌面情况下运行
    exit(1);
  }

  WidgetsFlutterBinding.ensureInitialized();

  // 加载配置
  await AppConfig.instance.init();
  createGithub(AppConfig.instance.auth);
  if (kDebugMode) {
    //print("AppConfig.instance.auth=${AppConfig.instance.auth.toJson()}");
  }

  // if (Platform.isWindows) {
  //   SystemTheme.accentColor.load();
  // }

  // 这个在macos下需要提前
  // 为解决macos下启动时黑屏问题
  // https://github.com/flutter/flutter/issues/142916
  await WindowManager.instance.ensureInitialized();
  final wSize =
      Platform.isWindows ? const Size(1280, 768) : const Size(1000, 720);

  /// 为解决启动时黑屏问题.还需要修改macos/Runner/MainFlutterWindow.swift里面的
  /// https://github.com/flutter/flutter/issues/142916
  ///```swift
  ///class MainFlutterWindow: NSWindow {
  ///   override func awakeFromNib() {
  ///     // ...
  ///     let flutterViewController = FlutterViewController()
  ///     // Add following two lines
  ///     self.backgroundColor = NSColor.clear
  ///     flutterViewController.backgroundColor = NSColor.clear
  ///     // ...
  ///   }
  /// }
  ///```
  if (Platform.isMacOS) {
    await windowManager.ensureInitialized();
    final option = WindowOptions(
        center: true, size: wSize, minimumSize: wSize, title: appTitle);
    windowManager.waitUntilReadyToShow(option, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
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
