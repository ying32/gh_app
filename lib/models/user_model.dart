import 'package:fluent_ui/fluent_ui.dart';

class CurrentUserModel extends ChangeNotifier {
  CurrentUserModel(this._user);

  /// 当前仓库信息
  String _user;
  String get user => _user;
  set path(String value) {
    if (value != _user) {
      _user = value;
      notifyListeners();
    }
  }
}
