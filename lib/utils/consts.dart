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

/// 不要修改或者移除这些定义
const githubUrl = 'https://github.com';
const myGithubUrl = '$githubUrl/ying32';
const appRepoUrl = '$myGithubUrl/gh_app';
const appVersion = '1.0.1';
const applicationLegalese = 'Copyright (c) 2026 ying32 All Rights Reserved';

/// 一个点
const dotChar = '·';

/// 默认每页的size数
const defaultPageSize = 15;
