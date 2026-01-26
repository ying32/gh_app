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

class GithubCache {
  GithubCache._();

  static GithubCache? _instance;
  static GithubCache get instance => _instance ??= GithubCache._();

  CurrentUser? _currentUser;

  /// 仓库列表缓存，key=owner
  final Map<String, List<Repository>> _repos = {};

  /// README缓存 key=owner/name
  final Map<String, GitHubFile> _readmes = {};

  /// 目录结构缓存 key=owner/name/path
  final Map<String, RepositoryContents> _contents = {};

  /// 当前user信息
  Future<CurrentUser?> get currentUser async =>
      _currentUser ??= await github?.users.getCurrentUser();

  /// 获取仓库列表信息
  Future<List<Repository>?> userRepos(String owner) async {
    if (_repos.containsKey(owner)) {
      return _repos[owner];
    }
    final stream = owner.isEmpty
        ? github?.repositories.listRepositories()
        : github?.repositories.listUserRepositories(owner);
    if (stream != null) {
      final list = await stream.toList();
      _repos[owner] = list;
      return list;
    }
    return null;
  }

  /// README缓存
  Future<GitHubFile?> repoReadMe(Repository repo) async {
    final slug = RepositorySlug(repo.owner!.login, repo.name);
    if (_readmes.containsKey(slug.fullName)) {
      return _readmes[slug.fullName];
    }
    final file = await github?.repositories.getReadme(slug);
    if (file != null) {
      _readmes[slug.fullName] = file;
      return file;
    }
    return null;
  }

  /// 目录内容缓存
  Future<RepositoryContents?> repoContents(Repository repo, String path) async {
    final slug = RepositorySlug(repo.owner!.login, repo.name);
    final key = "${slug.fullName}$path";
    if (_contents.containsKey(key)) {
      return _contents[key];
    }
    final content = await github?.repositories.getContents(slug, path);
    if (content != null) {
      _contents[key] = content;
      return content;
    }
    return null;
  }
}

/// 登录
// Future<bool> login(AuthField value) async {
//   return false;
// }
