import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/config.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/dialogs.dart';

const _authTypeStrings = ["匿名", "Access Token", "OAuth2", "帐户密码"];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
          if (token.isEmpty) {
            _showInfo('AccessToken不能为空', severity: InfoBarSeverity.error);
            return;
          }
          //TODO: 这里还要处理状态，先不管了，以后再弄吧
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
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(top: 14.0, bottom: 2.0),
                child: DefaultTextStyle(
                  style: FluentTheme.of(context).typography.subtitle!,
                  child: const Text('登录Github'),
                ),
              ),
              InfoLabel(
                label: '登录方式',
                child: Row(
                  children: [
                    Expanded(
                      child: ComboBox(
                          value: _authType,
                          items: AuthType.values
                              //TODO: 这里过滤掉匿名和使用帐号密码登录方式
                              .where((e) =>
                                  e != AuthType.anonymous &&
                                  e != AuthType.userPassword)
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
                    // 这里如果是使用accessToken认证的，则显示一个提示按钮，用于指示创建accessToken
                    if (_authType == AuthType.accessToken)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Tooltip(
                          message: '跳转到github去创建accessToken',
                          child: IconButton(
                              icon: const Icon(Remix.token_swap_line),
                              onPressed: () {
                                //
                                _showInfo('还没写呢！',
                                    severity: InfoBarSeverity.error);
                              }),
                        ),
                      )
                  ],
                ),
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
