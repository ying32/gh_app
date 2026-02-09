import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gh_app/pages/issue_details.dart';
import 'package:gh_app/pages/pull_request_details.dart';
import 'package:gh_app/pages/releases.dart';
import 'package:gh_app/pages/repo.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/widgets/widgets.dart';
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

/// 显示图片对话框
void showImageDialog(BuildContext context, String? imageURL) {
  if (imageURL == null || imageURL.isEmpty) return;
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => closeDialog(context),
          child: Center(child: CachedNetworkImageEx(imageURL)),
        );
      });
}

/// 跳转github仓库
/// TODO: 这个先实现，后面再重构
bool goToRepoPageByUri(
  Uri uri, {
  required BuildContext context,
  required ValueChanged<dynamic> onSuccess,
  ValueChanged<dynamic>? onFailed,
  VoidCallback? onComplete,
  bool useLoading = true,
}) {
  final res = APIWrap.instance.tryParseGithubUrl(uri);
  if (res == null) {
    if (useLoading) {
      launchUrl(uri);
    }
    return false;
  }
  if (useLoading) {
    LoadingDialog.show(context);
  }
  if (res is QLRepositoryWrap) {
    APIWrap.instance.userRepo(res.repo).then((e) {
      onSuccess(res.copyWith(repo: e));
    }).onError((e, s) {
      onFailed?.call(e);
    }).whenComplete(() {
      if (useLoading) {
        closeDialog(context);
      }
      onComplete?.call();
    });
    return true;
  } else if (res is QLIssueWrap) {
    APIWrap.instance.repoIssue(res.repo, number: res.issue.number).then((e) {
      onSuccess(res.copyWith(issue: e));
    }).onError((e, s) {
      if (kDebugMode) {
        print("$e");
        print("$s");
      }
      onFailed?.call(e);
    }).whenComplete(() {
      if (useLoading) {
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
      if (useLoading) {
        closeDialog(context);
      }
      onComplete?.call();
    });
    return true;
  } else if (res is QLReleaseWrap) {
    if (useLoading) {
      closeDialog(context);
    }
    onSuccess(res);
    onComplete?.call();
    return true;
  } else {
    if (useLoading) {
      closeDialog(context);
      launchUrl(uri);
    }
  }
  onComplete?.call();
  return false;
}

void goMainTabView(BuildContext context, dynamic value) {
  if (value is QLRepositoryWrap) {
    RepoPage.createNewTab(context, value.repo,
        subPage: value.subPage, ref: value.ref, path: value.path);
  } else if (value is QLIssueWrap) {
    IssueDetailsPage.createNewTab(context, value.repo, value.issue);
  } else if (value is QLPullRequestWrap) {
    PullRequestDetailsPage.createNewTab(context, value.repo, value.pull);
  } else if (value is QLReleaseWrap) {
    ReleasesPage.createNewTab(context, value.repo);
  }
}

/// 一个默认的跳转
void onDefaultLinkAction(BuildContext context, String link) {
  final uri = Uri.tryParse(link);
  if (uri == null) return;
  goToRepoPageByUri(uri, context: context, onSuccess: (value) {
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
      _controller.text = "$githubUrl/ying32/gh_app";
    }
    Clipboard.getData('text/plain').then((e) {
      if (e == null || e.text == null || e.text!.isEmpty) return;
      final u = Uri.tryParse(e.text!);
      if (u == null) return;
      if (u.host != githubHost) return;
      _controller.text = e.text!;
    });
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
    if (u.host != githubHost) {
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
    goToRepoPageByUri(u, useLoading: false, context: context,
        onSuccess: (value) {
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
            placeholder: '可以输入一个github仓库、issues、pull requests、releases页面链接',
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
            //注：在使用不知道哪个版本开始的（window_manager-0.4.3）后，
            //windowManager.destroy();会卡住一会儿，这里使用这种方式就可以正常了
            windowManager.setPreventClose(false).then((_) {
              windowManager.close();
            });
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

  static void show(BuildContext context) {
    windowManager.isPreventClose().then((isPreventClose) {
      if (isPreventClose) {
        showDialog(context: context, builder: (_) => const ExitAppDialog());
      }
    });
  }
}
