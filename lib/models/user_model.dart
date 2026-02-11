import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/widgets.dart';

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

  /// 我的仓库
  /// 我星的仓库
}

// ---------------------------------------------------------------------------
/// 用户模型简化
class UserModelSelector<S> extends SimplifySelector<CurrentUserModel, S> {
  UserModelSelector({
    super.key,
    required Widget Function(BuildContext, S value) builder,
    required S Function(CurrentUserModel) selector,
    super.shouldRebuild,
  }) : super(
            selector: (model) => selector(model),
            builder: (context, S value) => builder(context, value));
}

/// 用户选择器
class UserSelector extends UserModelSelector<QLUser?> {
  UserSelector({
    super.key,
    required Widget Function(BuildContext, QLUser? value) builder,
    super.shouldRebuild,
  }) : super(
            selector: (model) => model.user,
            builder: (context, QLUser? value) => builder(context, value));
}
