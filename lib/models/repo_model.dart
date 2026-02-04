import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/defines.dart';
import 'package:gh_app/utils/github/graphql.dart';

/// 仓库模型
class RepoModel extends ChangeNotifier {
  RepoModel(this._repo, {this.subPage, this.ref});

  /// 当前仓库信息
  QLRepository _repo;
  QLRepository get repo => _repo;
  set repo(QLRepository value) {
    if (value != _repo) {
      _repo = value;
      notifyListeners();
    }
  }

  final RepoSubPage? subPage;
  final String? ref;
}

class PathModel extends ChangeNotifier {
  PathModel([String path = '']) {
    this.path = path;
  }

  /// 当前仓库信息
  String _path = '';
  String get path => _path;
  set path(String value) {
    if (value != _path) {
      _path = value;
      _segmentedPaths.clear();
      if (_path.isEmpty || _path == "/") {
        _segmentedPaths.add('');
      } else {
        _segmentedPaths.addAll("/$_path".split("/"));
      }
      notifyListeners();
    }
  }

  /// 如果使用Consumer来监听就不可以使用final了
  final List<String> _segmentedPaths = [""];

  /// 已分割的路径
  List<String> get segmentedPaths => _segmentedPaths;
}

class ReadMeModel extends ChangeNotifier {
  /// readme文件内容
  String? _readMeContent;
  String? get readMeContent => _readMeContent; // ?? _repo.readMe?.content;
  set readMeContent(String? value) {
    if (_readMeContent != value) {
      _readMeContent = value;
      notifyListeners();
    }
  }
}

///
class RepoBranchModel extends ChangeNotifier {
  RepoBranchModel(this._selectedBranch);
  String? _selectedBranch;
  String? get selectedBranch => _selectedBranch;
  set selectedBranch(String? value) {
    if (_selectedBranch == value) return;
    _selectedBranch = value;
    notifyListeners();
  }

  QLList<QLRef> _refs = const QLList.empty();
  QLList<QLRef> get refs => _refs;
  set refs(QLList<QLRef> value) {
    if (value == _refs) return;
    _refs = value;
    notifyListeners();
  }
}
