import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/config.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:gh_app/widgets/page.dart';

const _authTypeStrings = ["匿名", "Access Token", "OAuth2", "帐户密码"];

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

  Future<void> _showLogging() async =>
      LoadingDialog.show(context, const Text('登录中...'));

  Future<void> _showInfo(String msg,
          {String? error, InfoBarSeverity? severity}) =>
      showInfoDialog(msg, context: context, error: error, severity: severity);

  Future<void> _closeDialog() async => closeDialog(context);

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
            await APIWrap.instance.currentUser;
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
        default:
          break;
      }
    } finally {
      _closeDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    // assert(debugCheckHasFluentTheme(context));
    // final theme = FluentTheme.of(context);
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 2.0,
        child: Card(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.0,
            runSpacing: 20.0,
            children: [
              const DefaultIcon.github(size: 60),
              subtitle(content: const Text('登录Github')),
              //   Text('CONTRIBUTORS', style: theme.typography.bodyStrong),
              InfoLabel(
                label: '登录方式',
                child: ComboBox(
                    value: _authType,
                    items: AuthType.values
                        .where((e) => e != AuthType.anonymous)
                        .map((e) => ComboBoxItem(
                              value: e,
                              child: Text(_authTypeStrings[e.index]),
                            ))
                        .toList(),
                    isExpanded: true,
                    onChanged: (v) {
                      if (v == _authType) return;
                      setState(() => _authType = v ?? AuthType.accessToken);
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
              const SizedBox(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
