import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

class CurrentUserModel extends ChangeNotifier {
  CurrentUserModel(this._user);

  /// 当前仓库信息
  QLUserOrOrganizationCommon? _user;
  QLUserOrOrganizationCommon? get user => _user;
  set user(QLUserOrOrganizationCommon? value) {
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
class UserSelector extends UserModelSelector<QLUserOrOrganizationCommon?> {
  UserSelector({
    super.key,
    required Widget Function(BuildContext, QLUserOrOrganizationCommon? value)
        builder,
    super.shouldRebuild,
  }) : super(
            selector: (model) => model.user,
            builder: (context, QLUserOrOrganizationCommon? value) =>
                builder(context, value));
}

extension CurUserContextHelper on BuildContext {
  CurrentUserModel get curUser => read<CurrentUserModel>();
}
