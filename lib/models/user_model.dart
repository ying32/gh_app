import 'package:fluent_ui/fluent_ui.dart';
import 'package:github/github.dart';

class CurrentUserModel extends ChangeNotifier {
  CurrentUserModel(this._user);

  /// 当前仓库信息
  CurrentUser? _user;
  CurrentUser? get user => _user;
  set user(CurrentUser? value) {
    if (value != _user) {
      _user = value;
      notifyListeners();
    }
  }
}
