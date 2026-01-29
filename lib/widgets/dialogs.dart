import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/router.dart';
import 'package:gh_app/utils/github.dart';

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

/// 跳转仓库对话框，Root路由
class GoRepoDialog extends StatefulWidget {
  const GoRepoDialog({super.key});

  @override
  State<GoRepoDialog> createState() => _GoRepoDialogState();

  static Future<void> showEditor(
    BuildContext context, {
    bool barrierDismissible = true,
  }) async =>
      showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (_) => const GoRepoDialog(),
      );
}

class _GoRepoDialogState extends State<GoRepoDialog> {
  final TextEditingController _controller =
      TextEditingController(text: "https://github.com/ying32/git_app");

  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    if ((u.host != "github.com" && u.host != "www.github.com") ||
        u.pathSegments.length < 2) {
      showInfoDialog('请输入一个github仓库链接',
          context: context, severity: InfoBarSeverity.error);
      return;
    }
    final segments = u.pathSegments;
    setState(() => _loading = true);
    GithubCache.instance.userRepo(segments[0], segments[1]).then((repo) {
      //print("e=${e.toJson()}");
      closeDialog(context);
      pushShellRoute(RouterTable.repo, extra: repo);
      // github.repositories.listTags(slug)
    }).onError((e, s) {
      print(e);
      print(s);
      showInfoDialog("错误",
          context: context, error: "$e", severity: InfoBarSeverity.error);
    }).whenComplete(() {
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('输入github仓库链接'),
      // style: ContentDialogThemeData(padding: EdgeInsets.zero),
      constraints: const BoxConstraints(maxWidth: 600),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextBox(
            controller: _controller,
            maxLines: null,
            placeholder: '例如：https://github.com/ying32/gh_app',
            expands: false,
          ),
          const SizedBox(height: 8.0),
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
      ),
    );
  }
}

/// 登录提示框
class LoggingDialog extends StatelessWidget with DialogClose {
  const LoggingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentDialog(
      // style: ContentDialogThemeData(padding: EdgeInsets.zero),
      constraints: BoxConstraints(maxWidth: 600),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(),
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('登录中...'),
          )
        ],
      ),
    );
  }

  static Future<void> showLogging(BuildContext context) async => showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const LoggingDialog(),
      );
}
