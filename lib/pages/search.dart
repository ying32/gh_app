import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:gh_app/widgets/repo_widgets.dart';
import 'package:github/github.dart';

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

  final List<String> _suggests = ['搜索仓库', '搜索作者', '搜索组织'];
  final List<Repository> _repos = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _doSearch(String text) {
    if (text.isEmpty) {
      _showInfo('请输入一个要搜索的关键字', severity: InfoBarSeverity.info);
      return;
    }
    // StreamBuilder
    _repos.clear();
    setState(() {
      _searching = true;
    });
    gitHubAPI.restful.search.repositories(text, pages: 1).listen((data) {
      _repos.add(data);
    }, onDone: _doUpdate);
    // gitHubAPI.restful.search.users(query)
    // gitHubAPI.restful.search.issues(query)query)
    // gitHubAPI.restful.search.code(query)query)
    // setState(() {
    //
    // });
  }

  void _doUpdate() {
    _searching = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showInfo(String msg,
          {String? error, InfoBarSeverity? severity}) =>
      showInfoDialog(msg, context: context, error: error, severity: severity);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
        child: Column(children: [
      TextBox(
        controller: _controller,
        placeholder: '请输入一个要搜索的关键字',
        onEditingComplete: _searching
            ? null
            : () {
                _doSearch(_controller.text.trim());
              },
      ),
      const SizedBox(height: 8.0),
      Expanded(
          child: _searching
              ? const Center(child: ProgressRing())
              : RepoListView(repos: _repos)),
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
