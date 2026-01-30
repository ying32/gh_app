import 'dart:convert';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_prism/flutter_prism.dart';
import 'package:gh_app/models/tabview_model.dart';
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:gh_app/utils/github.dart';
import 'package:gh_app/utils/prism_themes/prism_coldark_cold.dart';
import 'package:gh_app/utils/prism_themes/prism_coldark_dark.dart';
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
                  icon: Remix.paragraph);
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
  Map _json = {};
  bool _loading = false;

  // 查询User
  // viewer 换成   user(login:"ying32") 可以查其它用户的
  final String _apiUser = '''query {
  viewer {
    login
    name
    avatarUrl
    company
    bio
    email
    location
    twitterUsername
    url
    websiteUrl
    followers  {
      totalCount
    }
    following {
      totalCount
    }
    pinnedItems(first: 6, types:REPOSITORY) {
      nodes {
        ... on Repository {
          name
          forkCount
          stargazerCount
          isPrivate
          description
          owner {
            login
          }
          primaryLanguage {
            color
            name
          }
        }
      } 
    }
  }
}''';

  // 只查询user的仓库信息
  final String _apiRepos = '''query {
  viewer {
    repositories(first:1) {
      nodes {
        ... on Repository {
          name
          owner {
            login
            avatarUrl
          }
          description
          primaryLanguage {
            color
            name
          }
          archivedAt
          updatedAt
          url
          diskUsage
          forkCount
          forkingAllowed
          stargazerCount
          hasIssuesEnabled
          hasProjectsEnabled
          hasSponsorshipsEnabled
          hasWikiEnabled
          homepageUrl
          isArchived
          isBlankIssuesEnabled
          isDisabled
          isEmpty
          isFork
          isInOrganization
          isLocked
          isMirror
          isPrivate
          isTemplate
          isSecurityPolicyEnabled
          pushedAt
          viewerCanSubscribe 
          viewerHasStarred 
          languages(first: 10) {
            nodes {
              ...on Language {
                color
                name
              }
            }
          }
          defaultBranchRef {
            name
          }
          issues {
            totalCount
          }
          pullRequests {
            totalCount
          }
          licenseInfo {
             name 
          }
          latestRelease {
            author {
               login
               name
            }
            createdAt
            isDraft
            isLatest
            isPrerelease
          }
          refs(refPrefix: "refs/heads/") {
            totalCount  
          }
          releases {
            totalCount 
          }
          repositoryTopics(first: 10) {
             nodes {
                ... on RepositoryTopic {
                   topic {
                     name
                   }
                }
             }
          }
        }
      } 
    }
  }
}''';

  // 查询一个仓库信息
  final String _apiRepoInfo = '''query {
 
    repository(owner:"ying32", name:"govcl") {
 
          name
          owner {
            login
            avatarUrl
          }
          description
          primaryLanguage {
            color
            name
          }
          archivedAt
          updatedAt
          url
          diskUsage
          forkCount
          forkingAllowed
          stargazerCount
          hasIssuesEnabled
          hasProjectsEnabled
          hasSponsorshipsEnabled
          hasWikiEnabled
          homepageUrl
          isArchived
          isBlankIssuesEnabled
          isDisabled
          isEmpty
          isFork
          isInOrganization
          isLocked
          isMirror
          isPrivate
          isTemplate
          isSecurityPolicyEnabled
          pushedAt
          viewerCanSubscribe 
          viewerHasStarred 
          mirrorUrl
          languages(first: 10) {
            nodes {
              ...on Language {
                color
                name
              }
            }
          }
          defaultBranchRef {
            name
          }
          issues(states:OPEN) {
            totalCount
          }
          pullRequests(states:OPEN) {
            totalCount
          }
          licenseInfo {
             name 
          }
          latestRelease {
            author {
               login
               name
            }
            name 
            tagName 
            updatedAt 
            url 
            createdAt
            isDraft
            isLatest
            isPrerelease
          }
          refs(refPrefix: "refs/heads/") {
            totalCount  
          }
          releases {
            totalCount 
          }
          repositoryTopics(first: 20) {
             nodes {
                ... on RepositoryTopic {
                   topic {
                     name
                   }
                }
             }
          }
        }
 
}''';

  // 查询一个仓库的issues信息
  //                   timeline(after: 10) {
  //                        totalCount
  //                        nodes {
  //                           ... on IssueTimelineItem {
  //
  //                           }
  //                        }
  //                     }
  final _apiRepoIssues = '''query {

    repository(owner:"ying32", name:"govcl") {
          issues(first: 1, states:OPEN) {
             totalCount
             nodes {
                 ... on Issue {
                    number 
                    isPinned 
                    author {
                       login avatarUrl
                    }
                    title 
                    body
                    closed
                    closedAt
                    createdAt
                    editor {
                      login avatarUrl
                    }
                    labels(first: 20) {
                       totalCount 
                       nodes {
                         ... on Label {
                           name 
                           color 
                           description 
                           isDefault 
                         }
                       }
                    }
                    lastEditedAt 
                    locked 
             
                    milestone {
                      closed 
                      closedAt 
                      description 
                    }
                    state 
 
                    updatedAt 
                    viewerCanClose 
                    viewerCanDelete 
                    viewerCanReopen 
                 }
              }
          }
    }      
}''';

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
      _json = {};
    });
    if (_controller.text.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }
    gitHubAPI.graphql.query(_controller.text, statusCode: 200).then((e) {
      if (e is Map) {
        // print("返回结果=状态=$e");
        setState(() {
          _json = e;
          _bodyText = const JsonEncoder.withIndent('\t').convert(e);
        });
      } else {
        // print("返回结果=状态=${e.statusCode}, ${e.body}");
        setState(() {
          _json = {};
          _bodyText = "${e.body}";
        });
      }
    }).onError((e, s) {
      //print("错误=$e");

      setState(() {
        _json = {};
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
                    LinkStyleButton(
                        text: const Text("API参考：$_apiURL"),
                        onPressed: () {
                          launchUrl(Uri.parse(_apiURL));
                        }),
                    const Spacer(),
                    DropDownButton(
                      title: const Text('API选择'),
                      items: [
                        MenuFlyoutItem(
                            text: const Text('当前用户信息'),
                            onPressed: () {
                              _controller.text = _apiUser;
                            }),
                        MenuFlyoutItem(
                            text: const Text('当前用户仓库列表'),
                            onPressed: () {
                              _controller.text = _apiRepos;
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库信息'),
                            onPressed: () {
                              _controller.text = _apiRepoInfo;
                            }),
                        MenuFlyoutItem(
                            text: const Text('仓库Issues信息'),
                            onPressed: () {
                              _controller.text = _apiRepoIssues;
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
                    Button(onPressed: _doTest, child: const Text('GraphQL测试')),
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
            child: Card(child: TreeView(items: _buildTreeViewItems(_json))),
          ),
        ),
      ],
    );
  }
}
