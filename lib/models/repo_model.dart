import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/defines.dart';
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
      //_segmentedPaths.clear();
      _segmentedPaths = [''];
      if (_path.isEmpty || _path == "/") {
        //_segmentedPaths.add('');
      } else {
        //_segmentedPaths.addAll("/$_path".split("/"));
        _segmentedPaths = "/$_path".split("/");
      }
      notifyListeners();
    }
  }

  /// 如果使用Consumer来监听就不可以使用final了
  List<String> _segmentedPaths = [""];

  /// 已分割的路径
  List<String> get segmentedPaths => _segmentedPaths;
}
