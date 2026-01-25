import 'package:fluent_ui/fluent_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('仪表盘（Dashboard）'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      children: const [
        Card(
          child: Text('hello'),
        ),
        SizedBox(height: 22.0),
      ],
    );
  }
}
