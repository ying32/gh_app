import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:github/github.dart';

class FollowingPage extends StatefulWidget {
  const FollowingPage({super.key});

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  final List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    _users.clear();
    github?.users.listCurrentUserFollowing().listen((user) {
      if (mounted) {
        setState(() {
          _users.add(user);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('我关注的人'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      content: ListView.builder(
        itemCount: _users.length,
        // controller: scrollController,
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        itemBuilder: (context, index) {
          final item = _users[index];
          return ListTile(title: UserHeadName(user: item));
        },
      ),
    );
  }
}
