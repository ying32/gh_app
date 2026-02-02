import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/widgets/page.dart';
import 'package:gh_app/widgets/widgets.dart';

class FollowersPage extends StatelessWidget with PageMixin {
  const FollowersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('关注我的人'),
        commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
      ),
      content: APIFutureBuilder(
        future: APIWrap.instance.userFollowers(),
        builder: (_, snapshot) {
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
