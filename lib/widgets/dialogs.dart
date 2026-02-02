import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:gh_app/pages/issue_details.dart';
import 'package:gh_app/pages/pull_request_details.dart';
import 'package:gh_app/pages/releases.dart';
import 'package:gh_app/pages/repo.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:url_launcher/url_launcher.dart';
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

/// 跳转github仓库
/// TODO: 这个先实现，后面再重构
bool goToRepoByUri(
  Uri uri, {
  required BuildContext context,
  required ValueChanged<dynamic> onSuccess,
  ValueChanged<dynamic>? onFailed,
  VoidCallback? onComplete,
  bool useDialog = true,
}) {
  final res = APIWrap.instance.tryParseGithubUrl(uri);
  if (res == null) {
    if (useDialog) {
      launchUrl(uri);
    }
    return false;
  }
  if (useDialog) {
    LoadingDialog.show(context);
  }
  if (res is QLRepository) {
    APIWrap.instance.userRepo(res).then((e) {
      onSuccess(e!);
    }).onError((e, s) {
      onFailed?.call(e);
    }).whenComplete(() {
      if (useDialog) {
        closeDialog(context);
      }
      onComplete?.call();
    });
    return true;
  } else if (res is QLIssueWrap) {
    APIWrap.instance.repoIssue(res.repo, number: res.issue.number).then((e) {
      onSuccess(res.copyWith(issue: e));
    }).onError((e, s) {
      onFailed?.call(e);
    }).whenComplete(() {
      if (useDialog) {
        closeDialog(context);
      }
      onComplete?.call();
    });
    return true;
  } else if (res is QLPullRequestWrap) {
    APIWrap.instance
        .repoPullRequest(res.repo, number: res.pull.number)
        .then((e) {
      onSuccess(res.copyWith(pull: e));
    }).onError((e, s) {
      onFailed?.call(e);
    }).whenComplete(() {
      if (useDialog) {
        closeDialog(context);
      }
      onComplete?.call();
    });
    return true;
  } else if (res is QLReleaseWrap) {
    if (useDialog) {
      closeDialog(context);
    }
    onSuccess(res);
    onComplete?.call();
    return true;
  } else {
    if (useDialog) {
      closeDialog(context);
      launchUrl(uri);
    }
  }
  onComplete?.call();
  return false;
}

void goMainTabView(BuildContext context, dynamic value) {
  if (value is QLRepository) {
    RepoPage.createNewTab(context, value);
  } else if (value is QLIssueWrap) {
    IssueDetailsPage.createNewTab(context, value.repo, value.issue);
  } else if (value is QLPullRequestWrap) {
    PullRequestDetails.createNewTab(context, value.repo, value.pull);
  } else if (value is QLReleaseWrap) {
    ReleasesPage.createNewTab(context, value.repo);
  }
}

/// 一个默认的跳转
void onDefaultLinkAction(BuildContext context, String link) {
  final uri = Uri.tryParse(link);
  if (uri == null) return;
  goToRepoByUri(uri, context: context, onSuccess: (value) {
    goMainTabView(context, value);
  });
}

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

  void _close() => closeDialog(context);

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
    if (u.host != "github.com") {
      showInfoDialog('请输入一个github仓库链接',
          context: context, severity: InfoBarSeverity.error);
      return;
    }
    final segments = u.pathSegments.where((e) => e.isNotEmpty).toList();
    if (segments.length < 2) {
      showInfoDialog('请输入一个github仓库链接',
          context: context, severity: InfoBarSeverity.error);
      return;
    }
    if (kDebugMode) {
      print("segments=$segments");
    }
    setState(() => _loading = true);
    goToRepoByUri(u, useDialog: false, context: context, onSuccess: (value) {
      _close();
      widget.onSuccess?.call(value);
    }, onFailed: (e) {
      showInfoDialog("错误",
          context: context, error: "$e", severity: InfoBarSeverity.error);
    }, onComplete: () {
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('输入github的链接'),
      // style: ContentDialogThemeData(padding: EdgeInsets.zero),
      constraints: const BoxConstraints(maxWidth: 700),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextBox(
            controller: _controller,
            //maxLines: null,
            placeholder: '输入一个github仓库、用户等页面链接',
            expands: false,
            onEditingComplete: _onGoTo,
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
    this.text,
  });

  final Widget? text;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      // style: ContentDialogThemeData(padding: EdgeInsets.zero),
      constraints: const BoxConstraints(maxWidth: 600),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProgressRing(),
          if (text != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: text!, //Text('登录中...'),
            )
        ],
      ),
    );
  }

  static Future<void> show(BuildContext context, {Widget? text}) async =>
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

  static void show(BuildContext context, bool mounted) {
    windowManager.isPreventClose().then((isPreventClose) {
      if (isPreventClose && mounted) {
        showDialog(context: context, builder: (_) => const ExitAppDialog());
      }
    });
  }
}
