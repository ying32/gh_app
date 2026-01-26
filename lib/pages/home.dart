import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:github/github.dart';

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
      // header: const PageHeader(
      //   title: Text('仪表盘（Dashboard）'),
      //   commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      // ),
      children: [
        // const Card(child: Text('hello')),
        Card(
          child: FutureBuilder(
            future: GithubCache.instance.currentUser,
            builder: (_, AsyncSnapshot<CurrentUser?> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: ProgressRing());
              }
              return UserInfoPanel(user: snapshot.data);
            },
          ),
        ),
        const SizedBox(height: 22.0),
      ],
    );
  }
}
