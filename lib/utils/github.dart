import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';

/// 全局的github实例
GitHub? github;

/// 认证类型
enum AuthType {
  accessToken,
  oauth2,
  userPassword,
}

class AuthField {
  const AuthField(this.authType, this.tokenOrUserName, [this.password]);
  final AuthType authType;
  final String tokenOrUserName;
  final String? password;

  Map<String, dynamic> toJson() => {
        "auth_type": authType.name,
        "token_or_username": tokenOrUserName,
        if (password != null) "password": password,
      };

  AuthField.fromJson(Map<String, dynamic> json)
      : authType = enumFromStringValue(
            AuthType.values, json['auth_type'], AuthType.accessToken),
        tokenOrUserName = json['token_or_username'] ?? '',
        password = json['password'];
}

/// 创建github实例，根据配置的类型
bool createGithub(AuthField value) {
  // 其实不判断也没事，反正那啥一样
  if (value.tokenOrUserName.isEmpty) return false;
  github = switch (value.authType) {
    AuthType.accessToken =>
      GitHub(auth: Authentication.bearerToken(value.tokenOrUserName)),
    AuthType.oauth2 =>
      GitHub(auth: Authentication.withToken(value.tokenOrUserName)),
    AuthType.userPassword =>
      GitHub(auth: Authentication.basic(value.tokenOrUserName, value.password)),
  };
  return true;
}

void clearGithubInstance() {
  github = null;
}

/// 登录
// Future<bool> login(AuthField value) async {
//   return false;
// }
