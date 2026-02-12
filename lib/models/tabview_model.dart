import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:provider/provider.dart';

class TabViewModel extends ChangeNotifier {
  TabViewModel(this._tabs);

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

  int indexOf(Key? key) => tabs.indexWhere((e) => e.key == key);

  void goToTab(int index) {
    if (index >= 0 && index < tabs.length) {
      if (index == currentIndex) return;
      currentIndex = index;
      notifyListeners();
    }
  }

  /// 添加
  bool addTab(Widget child,
      {required ValueKey? key,
      required String title,
      Widget? icon,
      bool canClose = true}) {
    final index = indexOf(key);
    if (index != -1) {
      goToTab(index);
      return false;
    }
    late Tab tab;
    tab = Tab(
      key: key,
      text: Text(title),
      // semanticLabel: 'Document #$index',
      icon: icon ?? const DefaultIcon.repository(),
      body: child,
      closeIcon: canClose
          ? const Icon(FluentIcons.chrome_close)
          : const SizedBox(width: 24),
      onClosed: !canClose ? null : () => _doClose(tab),
    );
    tabs.add(tab);
    currentIndex = tabs.length - 1;
    notifyListeners();
    return true;
  }
}

extension TabViewContextHelper on BuildContext {
  TabViewModel get mainTabView => read<TabViewModel>();
}
