import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/config.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/widgets/page.dart';
import 'package:remixicon/remixicon.dart';

const _authTypeStrings = ["Access Token", "OAuth2", "帐户密码"];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with PageMixin {
  AuthType _authType = AuthType.accessToken;
  final _tokenOrUserNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _tokenOrUserNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showLogging() async => showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const ContentDialog(
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
        ),
      );

  Future<void> _showInfo(String msg,
          {String? error, InfoBarSeverity? severity}) =>
      displayInfoBar(context, builder: (context, close) {
        return InfoBar(
          title: Text(msg),
          content: error != null ? Text(error) : null,
          severity: severity ?? InfoBarSeverity.success,
        );
      });

  Future<void> _closeDialog() async =>
      Navigator.of(context, rootNavigator: true).pop();

  Future<void> _onLogin() async {
    _showLogging();
    try {
      switch (_authType) {
        case AuthType.accessToken:
          final token = _tokenOrUserNameController.text.trim();
          final auth = AuthField(_authType, token);
          AppConfig.instance.auth = auth;
          createGithub(auth);
          try {
            await github?.users.getCurrentUser();
            _showInfo('登录成功');
          } catch (e) {
            clearGithubInstance();
            _showInfo('登录失败', error: "$e", severity: InfoBarSeverity.error);
          }
        case AuthType.oauth2:
          // var flow = OAuth2Flow('ClientID', 'ClientSecret');
          // var authUrl = flow.createAuthorizeUrl();
          // // 这里打开浏览器，并取得code
          // flow.exchange(code).then((response) {
          //   final auth = AuthField(_authType, response.token);
          //   AppConfig.instance.auth = auth;
          //   createGithub(auth);
          // });
          _showInfo('OAuth2 还没有实现哦', severity: InfoBarSeverity.error);

        case AuthType.userPassword:
          final password = _passwordController.text.trim();
          final auth = AuthField(
              _authType,
              _tokenOrUserNameController.text.trim(),
              password.isEmpty ? null : password);
          AppConfig.instance.auth = auth;
          createGithub(auth);
          break;
      }
    } finally {
      _closeDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      //resizeToAvoidBottomInset: false,
      // header: PageHeader(
      //   title: const Text('登录Github'),
      //   commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      //     Link(
      //       uri: Uri.parse('https://github.com/bdlukaa/fluent_ui'),
      //       builder: (context, open) => Semantics(
      //         link: true,
      //         child: Tooltip(
      //           message: 'Source code',
      //           child: IconButton(
      //             icon: const Icon(FluentIcons.open_source, size: 24.0),
      //             onPressed: open,
      //           ),
      //         ),
      //       ),
      //     ),
      //   ]),
      // ),
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2.0,
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Remix.github_fill, size: 60),
                Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10.0,
                    runSpacing: 20.0,
                    children: [
                      subtitle(content: const Text('登录Github')),
                      //   Text('CONTRIBUTORS', style: theme.typography.bodyStrong),
                      InfoLabel(
                        label: '登录方式',
                        child: ComboBox(
                            value: _authType,
                            items: AuthType.values
                                .map((e) => ComboBoxItem(
                                      value: e,
                                      child: Text(_authTypeStrings[e.index]),
                                    ))
                                .toList(),
                            isExpanded: true,
                            onChanged: (v) {
                              if (v == _authType) return;
                              setState(
                                  () => _authType = v ?? AuthType.accessToken);
                            }),
                      ),
                      if (_authType != AuthType.oauth2)
                        InfoLabel(
                          label: switch (_authType) {
                            AuthType.userPassword => '用户名',
                            _ => _authTypeStrings[_authType.index],
                          },
                          child: TextBox(
                            controller: _tokenOrUserNameController,
                          ),
                        ),
                      if (_authType == AuthType.userPassword)
                        InfoLabel(
                          label: '密码',
                          child: PasswordBox(
                              controller: _passwordController,
                              revealMode: PasswordRevealMode.peekAlways),
                        ),
                      InfoLabel(
                        label: '',
                        isHeader: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _onLogin,
                            child: _authType == AuthType.oauth2
                                ? const Text('点击去认证')
                                : const Text('登录'),
                          ),
                        ),
                      ),
                      // const SizedBox(height: 64),
                      // RepaintBoundary(
                      //   child: Padding(
                      //     padding: const EdgeInsetsDirectional.only(start: 4.0),
                      //     child: InfoLabel(
                      //       label: 'Progress',
                      //       child: const SizedBox(
                      //         height: 30,
                      //         width: 30,
                      //         child: ProgressRing(),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
