import 'package:fluent_ui/fluent_ui.dart';
import 'package:github/github.dart';

class IssuesPage extends StatefulWidget {
  const IssuesPage({super.key});

  @override
  State<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  final List<Repository> _repos = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    _repos.clear();
    // github?.issues.listByRepo('').listen((repo) {
    //   if (mounted) {
    //     setState(() {
    //       _repos.add(repo);
    //     });
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('问题'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      content: ListView.separated(
        itemCount: _repos.length,
        // controller: scrollController,
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        itemBuilder: (context, index) {
          final item = _repos[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text(item.description),
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(size: 1, direction: Axis.horizontal),
      ),
    );
  }
}
