import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/models/user_model.dart';
import 'package:gh_app/utils/config.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const _authTypeStrings = ["匿名", "Access Token", "OAuth2"];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthType _authType = AuthType.accessToken;
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _showLogging() async =>
      LoadingDialog.show(context, text: const Text('登录中...'));

  Future<void> _showInfo(String msg,
          {String? error, InfoBarSeverity? severity}) =>
      showInfoDialog(msg, context: context, error: error, severity: severity);

  Future<void> _closeDialog() async => closeDialog(context);

  Future<void> _onLogin() async {
    _showLogging();
    try {
      switch (_authType) {
        case AuthType.accessToken:
          final token = _tokenController.text.trim();
          if (token.isEmpty) {
            _showInfo('AccessToken不能为空', severity: InfoBarSeverity.error);
            return;
          }
          final auth = AuthField(_authType, token);
          AppConfig.instance.auth = auth;
          createGithub(auth);
          try {
            final user = await APIWrap.instance.currentUser(force: true);
            if (mounted) {
              context.read<CurrentUserModel>().user = user;
            }
            _showInfo('登录成功');
          } on GitHubGraphQLError catch (e) {
            if (e.isBadCredentials) {
              clearGithubInstance();
              _showInfo('登录失败',
                  error: "需要认证信息", severity: InfoBarSeverity.error);
              return;
            }
            _showInfo('登录失败', error: "$e", severity: InfoBarSeverity.error);
          } catch (e) {
            _showInfo('登录失败', error: "$e", severity: InfoBarSeverity.error);
          }
        case AuthType.oauth2:
          _showInfo('OAuth2 还没有实现哦', severity: InfoBarSeverity.error);

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
                              .where((e) => e != AuthType.anonymous)
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
                                launchUrl(
                                    Uri.parse('$githubUrl/settings/tokens'));
                              }),
                        ),
                      )
                  ],
                ),
              ),
              if (_authType != AuthType.oauth2)
                TextBox(
                  placeholder: '你的 ${_authTypeStrings[_authType.index]}',
                  controller: _tokenController,
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
