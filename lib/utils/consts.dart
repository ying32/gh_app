const String appTitle = 'GitHub桌面板';

/// 皮肤对应的颜色
const themeModeStrings = ['跟随系统', '浅色模式', '深色模式'];

/// 跳由表
class RouterTable {
  static const root = "/";
  static const settings = "/settings";
  static const login = "/login";
  static const followers = "/followers";
  static const following = "/following";
  static const issues = "/issues";
  static const pulls = "/pulls";
  static const repos = "/repos";
  static const stars = "/stars";
  static const repo = "/repo";
  static const search = "/search";
  static const user = "/user";
  static const release = "/release";
}

/// 项目url
const appRepoUrl = 'https://github.com/ying32/gh_app';

/// 一个点
const dotChar = '·';

/// 默认每页的size数
const defaultPageSize = 15;
