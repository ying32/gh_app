import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:github/github.dart';

class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    _users.clear();
    github?.users.listCurrentUserFollowers().listen((user) {
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
        title: Text('关注我的人'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      content: ListView.separated(
        itemCount: _users.length,
        // controller: scrollController,
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        itemBuilder: (context, index) {
          final item = _users[index];
          return ListTile(
            title: UserHeadName(user: item),
            subtitle: Text(item.bio ?? ' '),
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(size: 1, direction: Axis.horizontal),
      ),
    );
  }
}
