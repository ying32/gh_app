import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:window_manager/window_manager.dart';

mixin DialogClose {}

/// 关闭对话框，Root路由
void closeDialog<T extends Object?>(BuildContext context, [T? result]) =>
    Navigator.of(context, rootNavigator: true).pop(result);

/// 显示信息
Future<void> showInfoDialog(String msg,
        {required BuildContext context,
        String? error,
        InfoBarSeverity? severity}) =>
    displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(msg),
        content: error != null ? Text(error) : null,
        severity: severity ?? InfoBarSeverity.success,
      );
    });

/// 跳转解析github对话框，Root路由
class GoGithubDialog extends StatefulWidget {
  const GoGithubDialog({
    super.key,
    this.onSuccess,
  });

  final ValueChanged<dynamic>? onSuccess;

  @override
  State<GoGithubDialog> createState() => _GoGithubDialogState();

  static Future<void> show(
    BuildContext context, {
    bool barrierDismissible = true,
    ValueChanged? onSuccess,
  }) async =>
      showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (_) => GoGithubDialog(onSuccess: onSuccess),
      );
}

class _GoGithubDialogState extends State<GoGithubDialog> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _controller.text = "https://github.com/ying32/gh_app";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _doUserRepo(String owner, String name) {
    GithubCache.instance.userRepo(owner, name).then((repo) {
      closeDialog(context);
      if (widget.onSuccess != null) {
        widget.onSuccess!.call(repo!);
        return;
      }
      // pushShellRoute(RouterTable.repo, extra: repo);
      // github.repositories.listTags(slug)
    }).onError((e, s) {
      // print(e);
      // print(s);
      showInfoDialog("错误",
          context: context, error: "$e", severity: InfoBarSeverity.error);
    }).whenComplete(() {
      setState(() => _loading = false);
    });
  }

  void _doUserInfo(String name) {
    GithubCache.instance.userInfo(name).then((user) {
      closeDialog(context);
      if (widget.onSuccess != null) {
        widget.onSuccess!.call(user!);
        return;
      }
      // pushShellRoute(RouterTable.repo, extra: repo);
      // github.repositories.listTags(slug)
    }).onError((e, s) {
      // print(e);
      // print(s);
      showInfoDialog("错误",
          context: context, error: "$e", severity: InfoBarSeverity.error);
    }).whenComplete(() {
      setState(() => _loading = false);
    });
  }

  void _onGoTo() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      showInfoDialog('请输入一个URL',
          context: context, severity: InfoBarSeverity.error);
    }
    // 这解析不靠谱？？？
    final u = Uri.tryParse(text);
    if (u == null) {
      showInfoDialog('请输入一个合法的github仓库链接',
          context: context, severity: InfoBarSeverity.error);
      return;
    }
    if ((u.host != "github.com" && u.host != "www.github.com")) {
      showInfoDialog('请输入一个github仓库链接',
          context: context, severity: InfoBarSeverity.error);
      return;
    }
    final segments = u.pathSegments.where((e) => e.isNotEmpty).toList();
    if (kDebugMode) {
      print("segments=$segments");
    }
    setState(() => _loading = true);
    switch (segments.length) {
      case 1:
        _doUserInfo(segments[0]);
        break;
      case 2:
        _doUserRepo(segments[0], segments[1]);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('输入github的链接'),
      // style: ContentDialogThemeData(padding: EdgeInsets.zero),
      constraints: const BoxConstraints(maxWidth: 600),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextBox(
            controller: _controller,
            maxLines: null,
            placeholder: '输入一个github仓库、用户等页面链接',
            expands: false,
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            if (_loading)
              const SizedBox(
                  width: 25,
                  height: 25,
                  child: ProgressRing(backgroundColor: Colors.transparent)),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _onGoTo,
              child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text('前往')),
            ),
          ],
        ),
      ],
    );
  }
}

/// 提示框
class LoadingDialog extends StatelessWidget with DialogClose {
  const LoadingDialog({
    super.key,
    required this.text,
  });

  final Widget text;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      // style: ContentDialogThemeData(padding: EdgeInsets.zero),
      constraints: const BoxConstraints(maxWidth: 600),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProgressRing(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: text, //Text('登录中...'),
          )
        ],
      ),
    );
  }

  static Future<void> show(BuildContext context, Widget text) async =>
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => LoadingDialog(text: text),
      );
}

class ExitAppDialog extends StatelessWidget {
  const ExitAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('退出提示'),
      content: const Text('是否真的要退出$appTitle？'),
      actions: [
        FilledButton(
          child: const Text('是'),
          onPressed: () {
            Navigator.pop(context);
            windowManager.destroy();
          },
        ),
        Button(
          child: const Text('否'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  static void show(BuildContext context, bool mounted) async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose && mounted) {
      showDialog(context: context, builder: (_) => const ExitAppDialog());
    }
  }
}
