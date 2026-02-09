part of '../repo.dart';

class _IssuesOrPullRequestsTabViewModel extends ChangeNotifier {
  _IssuesOrPullRequestsTabViewModel();

  int? _openCount;
  int? get openCount => _openCount;
  set openedCount(int? value) {
    if (value == _openCount) return;
    _openCount = value;
    notifyListeners();
  }

  int? _closedCount;
  int? get closedCount => _closedCount;
  set closedCount(int? value) {
    if (value == _closedCount) return;
    _closedCount = value;
    notifyListeners();
  }

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  set currentIndex(int value) {
    if (value == _currentIndex) return;
    _currentIndex = value;
    notifyListeners();
  }
}

class _IssueOrPullRequestListModel<T> extends ChangeNotifier {
  /// issues
  QLList<T>? _items;

  QLList<T>? get items => _items;

  set items(QLList<T>? value) {
    if (_items == value) return;
    _items = value;
    notifyListeners();
  }
}

class RepoIssuesOrPullRequestsCommon<T> extends StatelessWidget {
  const RepoIssuesOrPullRequestsCommon(
    this.repo, {
    super.key,
    required this.openWidget,
    required this.openIcon,
    required this.closedWidget,
    required this.closedIcon,
    required this.defaultOpenCount,
  });

  final QLRepository repo;
  final Widget openWidget;
  final DefaultIcon openIcon;
  final Widget closedWidget;
  final DefaultIcon closedIcon;
  final int defaultOpenCount;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _IssuesOrPullRequestsTabViewModel(),
      child: Selector<_IssuesOrPullRequestsTabViewModel, int>(
          selector: (_, model) => model.currentIndex,
          builder: (context, currentIndex, __) {
            return TabView(
              currentIndex: currentIndex,
              shortcutsEnabled: false,
              closeButtonVisibility: CloseButtonVisibilityMode.never,
              tabWidthBehavior: TabWidthBehavior.sizeToContent,
              tabs: [
                Tab(
                    icon: openIcon,
                    text: Text(
                        '打开的 (${(context.select<_IssuesOrPullRequestsTabViewModel, int?>((p) => p.openCount) ?? defaultOpenCount)})'),
                    body: ChangeNotifierProvider(
                        create: (_) => _IssueOrPullRequestListModel<T>(),
                        child: openWidget)),
                Tab(
                    icon: closedIcon,
                    text: Text(
                        '已关闭 (${(context.select<_IssuesOrPullRequestsTabViewModel, int?>((p) => p.closedCount) ?? 0)})'),
                    body: ChangeNotifierProvider(
                        create: (_) => _IssueOrPullRequestListModel<T>(),
                        child: closedWidget)),
              ],
              onChanged: (index) {
                context.read<_IssuesOrPullRequestsTabViewModel>().currentIndex =
                    index;
              },
            );
          }),
    );
  }
}
