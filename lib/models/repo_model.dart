import 'package:fluent_ui/fluent_ui.dart';
import 'package:github/github.dart';

/// 仓库模型
class RepoModel extends ChangeNotifier {
  RepoModel(this._repo);

  /// 当前仓库信息
  Repository _repo;
  Repository get repo => _repo;
  set repo(Repository value) {
    if (value != _repo) {
      _repo = value;
      notifyListeners();
    }
  }

  String? _selectedBranch;
  String get selectedBranch => _selectedBranch ?? _repo.defaultBranch;
  set selectedBranch(String? value) {
    if (_selectedBranch != value) {
      _selectedBranch = value;
      notifyListeners();
    }
  }
}

class PathModel extends ChangeNotifier {
  PathModel(this._path);

  /// 当前仓库信息
  String _path;
  String get path => _path;
  set path(String value) {
    if (value != _path) {
      _path = value;
      notifyListeners();
    }
  }

  List<String> get segmentedPaths {
    if (_path.isEmpty || _path == "/") return [""];
    final arr = _path.split("/");
    return arr;
  }
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
