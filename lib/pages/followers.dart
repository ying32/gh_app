import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:gh_app/widgets/page.dart';

class FollowersPage extends StatelessWidget with PageMixin {
  const FollowersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('关注我的人'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      content: FutureBuilder(
        future: APIWrap.instance.userFollowers(),
        builder: (_, snapshot) {
          if (!snapshotIsOk(snapshot, false, false)) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return errorDescription(snapshot.error);
          }
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('没有数据'),
            );
          }
          return const Center(child: Text('没写'));
          // return ListView.separated(
          //   itemCount: snapshot.data!.length,
          //   // controller: scrollController,
          //   padding: EdgeInsetsDirectional.only(
          //     bottom: kPageDefaultVerticalPadding,
          //     start: PageHeader.horizontalPadding(context),
          //     end: PageHeader.horizontalPadding(context),
          //   ),
          //   itemBuilder: (context, index) {
          //     final item = snapshot.data![index];
          //     return ListTile(
          //         leading: UserHeadImage(item.avatarUrl),
          //         title: UserNameWidget(item));
          //   },
          //   separatorBuilder: (context, index) {
          //     return const Divider(size: 1);
          //   },
          // );
        },
      ),
    );
  }
}
