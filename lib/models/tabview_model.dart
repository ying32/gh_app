import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';

class TabviewModel extends ChangeNotifier {
  TabviewModel(this._tabs);

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  set currentIndex(int value) {
    if (value == _currentIndex) return;
    _currentIndex = value;
    notifyListeners();
  }

  /// 当前仓库信息
  final List<Tab> _tabs;
  List<Tab> get tabs => _tabs;

  void _doClose(Tab tab) {
    if (tabs.remove(tab) && (currentIndex > 0)) {
      currentIndex--;
      notifyListeners();
    }
  }

  /// 添加
  void addTab(Widget child,
      {required ValueKey? key,
      required String title,
      IconData? icon,
      bool canClose = true}) {
    final index = tabs.indexWhere((e) => e.key == key);
    if (index != -1) {
      if (index == currentIndex) return;
      currentIndex = index;
      notifyListeners();
      return;
    }
    late Tab tab;
    tab = Tab(
      key: key,
      text: Text(title),
      // semanticLabel: 'Document #$index',
      icon: Icon(icon ?? Remix.git_repository_line),
      body: child,
      closeIcon: canClose ? FluentIcons.chrome_close : null,
      onClosed: !canClose ? null : () => _doClose(tab),
    );
    tabs.add(tab);
    currentIndex = tabs.length - 1;
    notifyListeners();
  }
}
