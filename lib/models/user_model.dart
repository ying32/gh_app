import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';

class CurrentUserModel extends ChangeNotifier {
  CurrentUserModel(this._user);

  /// 当前仓库信息
  QLUser? _user;
  QLUser? get user => _user;
  set user(QLUser? value) {
    if (value != _user) {
      _user = value;
      notifyListeners();
    }
  }

  void clearLogin() {
    _user = null;
    clearGithubInstance();
    notifyListeners();
  }
}
