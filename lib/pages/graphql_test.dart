import 'dart:convert';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_prism/flutter_prism.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/github/graphql_querys.dart';
import 'package:gh_app/utils/prism_themes/prism_coldark_cold.dart';
import 'package:gh_app/utils/prism_themes/prism_coldark_dark.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenGraphQLIconButton extends StatelessWidget {
  const OpenGraphQLIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'GraphQL测试',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: IconButton(
            icon: const Icon(Remix.paragraph, size: 18),
            onPressed: () {
              context.read<TabviewModel>().addTab(
                  key: const ValueKey('/graphql/test'),
                  const GraphQLTest(),
                  title: 'GraphQL测试',
                  icon: const Icon(Remix.paragraph));
            }),
      ),
    );
  }
}

class GraphQLTest extends StatefulWidget {
  const GraphQLTest({super.key});

  @override
  State<GraphQLTest> createState() => _GraphQLTestState();
}

class _GraphQLTestState extends State<GraphQLTest> {
  static const _apiURL = 'https://docs.github.com/zh/graphql';

  final _controller = TextEditingController();
  String _bodyText = "";
  bool _loading = false;
  final _treeNodes = <TreeViewItem>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _doTest() {
    setState(() {
      _loading = true;
      _bodyText = '';
      _treeNodes.clear();
    });
    if (_controller.text.isEmpty) {
      setState(() {
        _loading = false;
      });
      showInfoDialog('GraphQL语句不能为空',
          context: context, severity: InfoBarSeverity.error);
      return;
    }
    gitHubAPI.query(QLQuery(_controller.text)).then((e) {
      if (e is Map) {
        setState(() {
          _treeNodes.addAll(_buildTreeViewItems(e));
          _bodyText = const JsonEncoder.withIndent('\t').convert(e);
        });
      } else {
        setState(() {
          _bodyText = "${e.body}";
        });
      }
    }).onError((e, s) {
      setState(() {
        _bodyText = "$e";
      });
    }).whenComplete(() {
      setState(() {
        _loading = false;
      });
    });
  }

  List<TreeViewItem> _buildTreeViewItems(Map data) {
    List<TreeViewItem> res = [];
    for (final key in data.keys) {
      final val = data[key];
      final List<TreeViewItem> subItems = [];
      if (val is Map) {
        subItems.addAll(_buildTreeViewItems(val));
      } else if (val is List) {
        for (final item in val) {
          subItems.addAll(_buildTreeViewItems(item));
        }
      } else {
        subItems.add(TreeViewItem(
            content: Text(
          "$val",
          style: TextStyle(color: val == null ? Colors.red : Colors.green),
        )));
      }
      final item = TreeViewItem(
          content: Text(
            "$key<${val is Map ? 'Map' : (val is List ? 'List' : val.runtimeType)}>",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          children: subItems);
      res.add(item);
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        // fontFamily: 'Courier New',
        fontFamily: 'monospace',
        fontSize: 16.0,
        height: 1.5);
    final prism = Prism(
        style: context.isDark
            ? const PrismColdarkDarkStyle()
            : const PrismColdarkColdStyle());
    final textSpans = prism.render(_bodyText, 'json');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    LinkButton(
                        text: const Text("API参考：$_apiURL"),
                        onPressed: () {
                          launchUrl(Uri.parse(_apiURL));
                        }),
                    const Spacer(),
                    DropDownButton(
                      title: const Text('选择查询语句'),
                      items: [
                        MenuFlyoutItem(
                            text: const Text('当前用户信息'),
                            onPressed: () {
                              _controller.text = QLQueries.queryUser();
                            }),
                        MenuFlyoutItem(
                            text: const Text('当前用户仓库列表'),
                            onPressed: () {
                              _controller.text = QLQueries.queryRepos();
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('其他用户信息'),
                            onPressed: () {
                              _controller.text = QLQueries.queryUser('ying32');
                            }),
                        MenuFlyoutItem(
                            text: const Text('查询followers的用户'),
                            onPressed: () {
                              _controller.text = QLQueries.queryFollowerUsers(
                                  name: '', isFollowers: true);
                            }),
                        MenuFlyoutItem(
                            text: const Text('查询following的用户'),
                            onPressed: () {
                              _controller.text = QLQueries.queryFollowerUsers(
                                  name: '', isFollowers: false);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('查询组织信息'),
                            onPressed: () {
                              _controller.text =
                                  QLQueries.queryOrganization('zed-industries');
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库信息'),
                            onPressed: () {
                              _controller.text =
                                  QLQueries.queryRepo('ying32', 'govcl');
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库Issues信息'),
                            onPressed: () {
                              _controller.text =
                                  QLQueries.queryRepoIssuesOrPullRequests(
                                      'ying32', 'govcl');
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库指定Issue评论'),
                            onPressed: () {
                              _controller.text = QLQueries.queryIssueComments(
                                  'ying32', 'govcl', 212);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库PullRequests信息'),
                            onPressed: () {
                              _controller.text =
                                  QLQueries.queryRepoIssuesOrPullRequests(
                                      'ying32', 'govcl',
                                      isIssues: false);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库Releases'),
                            onPressed: () {
                              _controller.text = QLQueries.queryRepoReleases(
                                  'ying32', 'govcl');
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库Releases Assets'),
                            onPressed: () {
                              _controller.text =
                                  QLQueries.queryRepoReleaseAssets(
                                      'ying32', 'govcl',
                                      tagName: 'v2.2.3');
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库文件列表'),
                            onPressed: () {
                              _controller.text = QLQueries.queryObject(
                                  'ying32', 'govcl',
                                  path: "", ref: "HEAD");
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库分支信息'),
                            onPressed: () {
                              _controller.text =
                                  QLQueries.queryRepoRefs('ying32', 'govcl');
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('搜索仓库'),
                            onPressed: () {
                              _controller.text = QLQueries.search('govcl');
                            }),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: TextBox(
                  controller: _controller,
                  maxLines: null,
                  selectionHeightStyle: ui.BoxHeightStyle.max,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  children: [
                    _loading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child: Center(
                              child: ProgressRing(
                                backgroundColor: Colors.transparent,
                              ),
                            ))
                        : const Text('结果:'),
                    const Spacer(),
                    Button(
                        onPressed: _loading ? null : _doTest,
                        child: const IconText(
                            icon: Remix.send_plane_line, text: Text('发送'))),
                  ],
                ),
              ),
              Card(
                child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: SelectableText.rich(
                      TextSpan(style: style, children: textSpans),
                      // contextMenuBuilder: _defaultContextMenuBuilder,
                      selectionHeightStyle: ui.BoxHeightStyle.max,
                    )),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            width: 350,
            height: double.infinity,
            child: Card(
                // TreeView是有bug么？，当items被清后他还显示也不更新了
                child: _treeNodes.isEmpty
                    ? const SizedBox.shrink()
                    : TreeView(items: _treeNodes)),
          ),
        ),
      ],
    );
  }
}
