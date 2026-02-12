import 'dart:convert';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_prism/flutter_prism.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/utils/github/graphql_querys.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/prism_themes/prism_coldark.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:gh_app/widgets/widgets.dart';

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
              context.mainTabView.addTab(
                  key: const ValueKey('/graphql/test'),
                  const GraphQLTest(),
                  title: 'GraphQL测试',
                  icon: const Icon(Remix.paragraph));
            }),
      ),
    );
  }
}

class _TreeVew extends StatelessWidget {
  const _TreeVew(this.nodes);

  final List<TreeViewItem> nodes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 350,
        height: double.infinity,
        child: Card(
            // TreeView是有bug么？，当items被清后他还显示也不更新了
            child: nodes.isEmpty
                ? const SizedBox.shrink()
                : TreeView(items: nodes)),
      ),
    );
  }
}

class GraphQLTest extends StatefulWidget {
  const GraphQLTest({super.key});

  @override
  State<GraphQLTest> createState() => _GraphQLTestState();
}

class _GraphQLTestState extends State<GraphQLTest>
    with AutomaticKeepAliveClientMixin {
  static const _apiURL = 'https://docs.github.com/zh/graphql';

  final _controller = TextEditingController();
  final _argsController = TextEditingController();
  final _opNamController = TextEditingController();
  String _resultText = "";
  bool _loading = false;
  final _treeNodes = <TreeViewItem>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _opNamController.dispose();
    _argsController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _parseParams() {
    Map<String, dynamic>? result;
    // 解析参数
    for (final line in const LineSplitter().convert(_argsController.text)) {
      if (line.isEmpty) continue;
      final idx = line.indexOf("=");
      if (idx == -1) continue;
      final argName = line.substring(0, idx).trim();
      final argValue = line.substring(idx + 1).trim();
      if (argName.isNotEmpty && argValue.isNotEmpty) {
        result ??= {};
        dynamic value;
        // String类型
        if (argValue == "null" || argValue.isEmpty) {
          value = null;
        } else if (argValue.startsWith('"') && argValue.endsWith('"')) {
          value = argValue.substring(1, argValue.length - 1);
        } else if (bool.tryParse(argValue) != null) {
          value = bool.parse(argValue);
        } else if (int.tryParse(argValue) != null) {
          value = int.parse(argValue);
        } else if (double.tryParse(argValue) != null) {
          value = double.parse(argValue);
        }
        result[argName] = value;
      }
    }
    return result;
  }

  String _decodeParams(QLQuery query) {
    if (query.variables != null && query.variables!.isNotEmpty) {
      final list = query.variables!.keys.map((key) {
        final val = query.variables![key];
        if (val is String) {
          return '$key="$val"';
        }
        return '$key=$val';
      });
      if (list.isNotEmpty) {
        return list.join("\n");
      }
    }
    return '';
  }

  void _doTest() {
    setState(() {
      _loading = true;
      _resultText = '';
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

    gitHubAPI
        .query(
            QLQuery(_controller.text,
                variables: _parseParams(), operationName: _opName),
            force: true)
        .then((e) {
      if (e is Map) {
        setState(() {
          _treeNodes.addAll(_buildTreeViewItems(e));
          _resultText = const JsonEncoder.withIndent('    ').convert(e);
        });
      } else {
        setState(() {
          _resultText = "${e.body}";
        });
      }
    }).onError((e, s) {
      setState(() {
        if (e is GitHubGraphQLError) {
          if (e.message is String) {
            _resultText = "$e";
          } else {
            _resultText =
                const JsonEncoder.withIndent('    ').convert(e.message);
          }
        } else {
          _resultText = "$e";
        }
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
        for (var i = 0; i < val.length; i++) {
          final item = val[i];
          final List<TreeViewItem> orders = [];
          orders.addAll(_buildTreeViewItems(item));

          subItems.add(TreeViewItem(
              content: Text("$i",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
              children: orders));
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

  String? get _opName {
    final text = _opNamController.text.trim();
    if (text.isEmpty) return null;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const style =
        TextStyle(fontFamily: 'monospace', fontSize: 16.0, height: 1.5);
    final prism = Prism(
        style: context.isDark
            ? const PrismColDarkStyle.dark()
            : const PrismColDarkStyle.light());
    final textSpans = prism.render(_resultText, 'json');
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
                    const Text('API参考：'),
                    const LinkButton(link: _apiURL),
                    const Spacer(),
                    DropDownButton(
                      title: const Text('选择查询语句'),
                      items: [
                        MenuFlyoutItem(
                            text: const Text('当前用户信息'),
                            onPressed: () {
                              final ql = QLQueries.queryViewer();
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        MenuFlyoutItem(
                            text: const Text('当前用户仓库列表'),
                            onPressed: () {
                              final ql = QLQueries.queryRepos();
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('其他用户或者组织信息'),
                            onPressed: () {
                              final ql = QLQueries.queryRepoOwner('ying32');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        MenuFlyoutItem(
                            text: const Text('查询followers的用户'),
                            onPressed: () {
                              final ql = QLQueries.queryFollowerUsers(
                                  name: '', isFollowers: true);
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        MenuFlyoutItem(
                            text: const Text('查询following的用户'),
                            onPressed: () {
                              final ql = QLQueries.queryFollowerUsers(
                                  name: '', isFollowers: false);
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('查询组织信息'),
                            onPressed: () {
                              final ql =
                                  QLQueries.queryRepoOwner('zed-industries');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('查询仓库所有者信息'),
                            onPressed: () {
                              final ql =
                                  QLQueries.queryRepoOwner('zed-industries');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库信息'),
                            onPressed: () {
                              final ql = QLQueries.queryRepo('ying32', 'govcl');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库Issues信息'),
                            onPressed: () {
                              final ql =
                                  QLQueries.queryRepoIssuesOrPullRequests(
                                      'ying32', 'govcl');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库指定Issue信息'),
                            onPressed: () {
                              final ql = QLQueries.queryIssueOrPullRequest(
                                  'ying32', 'govcl', 212);
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库指定Issue评论'),
                            onPressed: () {
                              final ql = QLQueries.queryIssueComments(
                                  'ying32', 'govcl', 212);
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库PullRequests信息'),
                            onPressed: () {
                              final ql =
                                  QLQueries.queryRepoIssuesOrPullRequests(
                                      'ying32', 'govcl',
                                      isIssues: false,
                                      states: ['CLOSED', 'MERGED']);
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库Releases'),
                            onPressed: () {
                              final ql = QLQueries.queryRepoReleases(
                                  'ying32', 'govcl');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库Releases Assets'),
                            onPressed: () {
                              final ql = QLQueries.queryRepoReleaseAssets(
                                  'ying32', 'govcl',
                                  tagName: 'v2.2.3');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('仓库文件列表'),
                            onPressed: () {
                              final ql = QLQueries.queryGitObject(
                                  'ying32', 'govcl',
                                  path: "", ref: "HEAD");
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库分支信息(refs, tags)'),
                            onPressed: () {
                              // 他这分支n多，方便测试哈
                              //https://github.com/zed-industries/zed
                              final ql = QLQueries.queryRepoRefs(
                                  'zed-industries', 'zed');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库commit信息'),
                            onPressed: () {
                              final ql = QLQueries.queryRepoCommits(
                                  'ying32', 'govcl',
                                  qualifiedName: 'master', count: 3);
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                        const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                            text: const Text('搜索仓库'),
                            onPressed: () {
                              final ql = QLQueries.search('govcl');
                              _controller.text = ql.document;
                              _argsController.text = _decodeParams(ql);
                            }),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        placeholder: 'GraphQL查询语句',
                        controller: _controller,
                        maxLines: null,
                        selectionHeightStyle: ui.BoxHeightStyle.max,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          const Row(children: [Text('参数：')]),
                          const SizedBox(height: 8),
                          Expanded(
                              child: TextBox(
                            placeholder:
                                '语法：\nname=value\n每一行一条\n\n例：\nstring="string"\nint=123\nbool=true\ndouble=1.23',
                            textAlignVertical: TextAlignVertical.top,
                            controller: _argsController,
                            maxLines: null,
                            selectionHeightStyle: ui.BoxHeightStyle.max,
                          )),
                          const SizedBox(height: 8),
                          const Row(children: [Text('操作名：')]),
                          const SizedBox(height: 8),
                          TextBox(
                            // placeholder: '',
                            textAlignVertical: TextAlignVertical.top,
                            controller: _opNamController,

                            selectionHeightStyle: ui.BoxHeightStyle.max,
                          )
                        ],
                      ),
                    ),
                  ],
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
        _TreeVew(_treeNodes),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
