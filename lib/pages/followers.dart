import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/user_widgets.dart';

class FollowersPage extends StatelessWidget {
  const FollowersPage({super.key});

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('关注我的人'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      content: FutureBuilder(
        future: GithubCache.instance.userFollowers(),
        builder: (_, snapshot) {
          if (!snapshotIsOk(snapshot, false, false)) {
            return const Center(
              child: ProgressRing(),
            );
          }
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('没有数据'),
            );
          }
          return ListView.separated(
            itemCount: snapshot.data!.length,
            // controller: scrollController,
            padding: EdgeInsetsDirectional.only(
              bottom: kPageDefaultVerticalPadding,
              start: PageHeader.horizontalPadding(context),
              end: PageHeader.horizontalPadding(context),
            ),
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return ListTile(title: UserHeadName(user: item));
            },
            separatorBuilder: (context, index) {
              return const Divider(size: 1);
            },
          );
        },
      ),
    );
  }
}
