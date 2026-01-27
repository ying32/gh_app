import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/widgets/user_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
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

  int currentIndex = 0;
  List<Tab> tabs = [
    Tab(
      text: const Text('主页'),
      icon: const GitHubIcon(size: 20),
      closeIcon: null,
      body: Card(
        child: FutureBuilder(
          future: GithubCache.instance.currentUser,
          builder: (_, AsyncSnapshot<CurrentUser?> snapshot) {
            // if (snapshot.connectionState != ConnectionState.done) {
            //   return const Center(child: ProgressRing());
            // }
            return UserInfoPanel(user: snapshot.data);
          },
        ),
      ),
    )
  ];

  /// Creates a tab for the given index
  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      text: Text('Document $index'),
      semanticLabel: 'Document #$index',
      icon: const FlutterLogo(),
      body: Container(
        color:
            Colors.accentColors[Random().nextInt(Colors.accentColors.length)],
      ),
      onClosed: () {
        setState(() {
          tabs!.remove(tab);

          if (currentIndex > 0) currentIndex--;
        });
      },
    );
    return tab;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      content: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: kPageDefaultVerticalPadding,
          start: PageHeader.horizontalPadding(context),
          end: PageHeader.horizontalPadding(context),
        ),
        child: TabView(
          tabs: tabs,
          currentIndex: currentIndex,
          onChanged: (index) => setState(() => currentIndex = index),
          tabWidthBehavior: TabWidthBehavior.sizeToContent,
          closeButtonVisibility: CloseButtonVisibilityMode.always,
          // showScrollButtons: true,
          // wheelScroll: false,
          // onNewPressed: () {
          //   setState(() {
          //     final index = tabs.length + 1;
          //     final tab = generateTab(index);
          //     tabs.add(tab);
          //   });
          // },
          // onReorder: (oldIndex, newIndex) {
          //   setState(() {
          //     if (oldIndex < newIndex) {
          //       newIndex -= 1;
          //     }
          //     final item = tabs!.removeAt(oldIndex);
          //     tabs!.insert(newIndex, item);
          //
          //     if (currentIndex == newIndex) {
          //       currentIndex = oldIndex;
          //     } else if (currentIndex == oldIndex) {
          //       currentIndex = newIndex;
          //     }
          //   });
          // },
        ),
      ),
    );
  }
}
