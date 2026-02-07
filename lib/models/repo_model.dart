import 'package:flutter/foundation.dart';
import 'package:gh_app/utils/defines.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';

/// 仓库模型
class RepoModel extends ChangeNotifier {
  RepoModel(this._repo, {this.subPage, String? ref, String? path})
      : _ref = ref {
    this.path = path ?? '';
  }

  ///===========================当前仓库信息=============================
  QLRepository _repo;

  QLRepository get repo => _repo;

  set repo(QLRepository value) {
    if (value != _repo) {
      _repo = value;
      notifyListeners();
      updateFileObject();
      _ref = _repo.defaultBranchRef.name;
    }
  }

  final RepoSubPage? subPage;

  ///===========================分支=============================
  String? _ref;

  String? get ref => _ref;

  set ref(String? value) {
    if (_ref == value) return;
    _ref = value;
    notifyListeners();
    updateFileObject();
  }

  /// 分支列表
  QLList<QLRef> _refs = const QLList.empty();

  QLList<QLRef> get refs => _refs;

  set refs(QLList<QLRef> value) {
    if (value == _refs) return;
    _refs = value;
    notifyListeners();
  }

  ///===========================仓库文件路径=============================
  /// 当前仓库信息
  String _path = '';

  String get path => _path;

  set path(String value) {
    if (value != _path) {
      _path = value;
      // 改变路径，此时也需要置空对象

      //_segmentedPaths.clear();
      _segmentedPaths = [''];
      if (_path.isEmpty || _path == "/") {
        //_segmentedPaths.add('');
      } else {
        //_segmentedPaths.addAll("/$_path".split("/"));
        _segmentedPaths = "/$_path".split("/");
      }
      notifyListeners();
      updateFileObject();
    }
  }

  /// 更新内容对象
  void updateFileObject() {
    object = null; // 更新前先置null，通知接收的
    readmeContent = '';
    APIWrap.instance.repoContents(repo, path, ref: ref).then((e) {
      object = e;
      // 更新readme
      if (_path.isEmpty && object != null) {
        // 找readme文件，仅限根目录下，其实按情况其它的目录也可以查找下。
        final readmeFile = path.isEmpty ? _getReadMeFile(object!) : '';
        if (readmeFile.isNotEmpty) {
          APIWrap.instance.repoReadMe(repo, readmeFile, ref: ref).then((data) {
            readmeContent = data;
          }).onError((e, s) {
            readmeContent = '';
          });
        }
      }
    }).onError((e, _) {
      QLGitObject.error(e);
    });
  }

  QLTreeEntry _matchReadMeFile(QLGitObject object, RegExp regex) {
    return object.tree!.entries.lastWhere(
        (e) => regex.firstMatch(e.name.replaceAll("_", "-")) != null,
        orElse: () => const QLTreeEntry());
  }

  String _getReadMeFile(QLGitObject object) {
    if (object.isFile) return '';
    // 优先匹配本地化的
    // var tree = _matchReadMeFile(
    //     object,
    //     RegExp(
    //         r'^README[\.|-|_]?' +
    //             Localizations.localeOf(context).toLanguageTag() +
    //             r'[\s\S]*?\.?(?:md|markdown)$',
    //         caseSensitive: false));
    // if (tree.name.isNotEmpty) {
    //   return tree.name;
    // }
    // 没有则匹配默认的
    var tree = _matchReadMeFile(
        object,
        RegExp(r'^README[\.|-|_]?[\s\S]*?\.?(?:md|markdown)$',
            caseSensitive: false));
    if (tree.name.isNotEmpty) {
      return tree.name;
    }
    // 如果没有，匹配下txt的README文件
    tree = _matchReadMeFile(
        object,
        RegExp(r'^README[\.|-|_]?[\s\S]*?\.?txt$', //|txt
            caseSensitive: false));
    if (tree.name.isNotEmpty) {
      return tree.name;
    }
    return '';
  }

  /// readme
  String _readmeContent = '';

  String get readmeContent => _readmeContent;

  set readmeContent(String value) {
    if (_readmeContent == value) return;
    _readmeContent = value;
    notifyListeners();
  }

  /// 如果使用Consumer来监听就不可以使用final了
  List<String> _segmentedPaths = [""];

  /// 已分割的路径
  List<String> get segmentedPaths => _segmentedPaths;

  ///========================object=================================
  QLGitObject? _object;

  QLGitObject? get object => _object;

  set object(QLGitObject? value) {
    if (_object == value) return;
    _object = value;
    notifyListeners();
  }

  /// issues
  QLList<QLIssue>? _issues;

  QLList<QLIssue>? get issues => _issues;

  set issues(QLList<QLIssue>? value) {
    if (_issues == value) return;
    _issues = value;
    notifyListeners();
  }

  /// pullRequests
  QLList<QLPullRequest>? _pullRequests;

  QLList<QLPullRequest>? get pullRequests => _pullRequests;

  set pullRequests(QLList<QLPullRequest>? value) {
    if (_pullRequests == value) return;
    _pullRequests = value;
    notifyListeners();
  }

  /// releases
  QLList<QLRelease>? _releases;

  QLList<QLRelease>? get releases => _releases;

  set releases(QLList<QLRelease>? value) {
    if (_releases == value) return;
    _releases = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print("dispose RepoModel");
    }
    super.dispose();
  }
}

/// 仓库列表
class RepoListModel extends ChangeNotifier {
  RepoListModel(
      {this.isStarred = false,
      this.owner = '',
      this.isOrganization = false,
      QLList<QLRepository>? repos})
      : _repos = repos;

  final String owner;
  final bool isStarred;
  final bool isOrganization;
  QLList<QLRepository>? _repos;

  QLList<QLRepository>? get repos => _repos;

  set repos(QLList<QLRepository>? value) {
    if (_repos == value) return;
    _repos = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print("dispose RepoListModel: owner=$owner, isStarred=$isStarred");
    }
    super.dispose();
  }
}
