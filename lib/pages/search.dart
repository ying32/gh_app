import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:gh_app/widgets/repo_widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();
  String? selectedCat;
  bool _searching = false;

  //final List<String> _suggests = ['搜索仓库', '搜索作者', '搜索组织'];
  QLList<QLRepository> _repos = const QLList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _doSearch(String text) {
    if (text.isEmpty) {
      _showInfo('请输入一个要搜索的仓库关键字', severity: InfoBarSeverity.info);
      return;
    }
    _repos = const QLList();
    setState(() {
      _searching = true;
    });
    APIWrap.instance.searchRepo(text, onSecondUpdate: (value) {
      _repos = value;
      _doUpdate();
    }).then((data) {
      _repos = data;
    }).whenComplete(_doUpdate);
  }

  void _doUpdate() {
    _searching = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<QLList<QLRepository>> _onLoadData(QLPageInfo? pageInfo) async {
    if (pageInfo == null || !pageInfo.hasNextPage) return const QLList();

    return APIWrap.instance
        .searchRepo(_controller.text.trim(), nextCursor: pageInfo.endCursor);
  }

  Future<void> _showInfo(String msg,
          {String? error, InfoBarSeverity? severity}) =>
      showInfoDialog(msg, context: context, error: error, severity: severity);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
        child: Column(children: [
      SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: TextBox(
            controller: _controller,
            placeholder: '请输入一个要搜索的仓库关键字，支持github搜索的表达式',
            onEditingComplete:
                _searching ? null : () => _doSearch(_controller.text.trim()),
            suffix: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: () => _controller.clear()),
          ),
        ),
      ),
      const SizedBox(height: 8.0),
      Expanded(
          child: _searching
              ? const Center(child: ProgressRing())
              : RepoListView(
                  repos: _repos,
                  showOpenIssues: false,
                  onLoading: _onLoadData)),
      // AutoSuggestBox(
      //   placeholder: '输入要搜索的',
      //   onChanged: (val, reason) {
      //     print("value=$val, res=$reason");
      //   },
      //   items: _suggests.map((e) {
      //     return AutoSuggestBoxItem(
      //         value: e,
      //         label: e,
      //         onFocusChange: (focused) {
      //           if (focused) {
      //             debugPrint('Focused $e');
      //           }
      //         });
      //   }).toList(),
      //   onSelected: (item) {
      //     // setState(() => selectedCat = item);
      //   },
      // ),
    ]));
  }

  @override
  bool get wantKeepAlive => true;
}
