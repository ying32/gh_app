import 'package:fluent_ui/fluent_ui.dart';

class PullPage extends StatelessWidget {
  const PullPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('没写哈'));
    // return ListView.separated(
    //   itemCount: _repos.length,
    //   // controller: scrollController,
    //   padding: EdgeInsetsDirectional.only(
    //     bottom: kPageDefaultVerticalPadding,
    //     // start: PageHeader.horizontalPadding(context),
    //     end: PageHeader.horizontalPadding(context),
    //   ),
    //   itemBuilder: (context, index) {
    //     final item = _repos[index];
    //     return ListTile(
    //       title: Text(item.name),
    //       subtitle: Text(item.description),
    //     );
    //   },
    //   separatorBuilder: (BuildContext context, int index) =>
    //   const Divider(size: 1, direction: Axis.horizontal),
    // );
  }
}
