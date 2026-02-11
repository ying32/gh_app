import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/utils/github/github.dart';
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/issues_widgets.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

class _IssueOrPullRequestDetailsModel extends ChangeNotifier {
  _IssueOrPullRequestDetailsModel();

  QLList<QLComment>? _comments;

  QLList<QLComment>? get comments => _comments;

  set comments(QLList<QLComment>? value) {
    if (_comments == value) return;
    _comments = value;
    notifyListeners();
  }
}

/// issues的评论显示
// class IssuesCommentsView extends StatelessWidget {
//   const IssuesCommentsView(
//     this.data, {
//     super.key,
//     required this.repo,
//     required this.first,
//   });
//
//   final QLRepository repo;
//   final QLIssueOrPullRequest data;
//   final Widget first;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         first,
//         APIFutureBuilder(
//             noDataWidget: const SizedBox.shrink(),
//             future: APIWrap.instance.repoIssueOrPullRequestComments(repo,
//                 number: data.number, isIssues: data is QLIssue),
//             builder: (_, snapshot) {
//               return Column(
//                 children: snapshot.data
//                     .map((e) => IssueCommentItem(
//                           item: e,
//                           owner: repo.owner.login,
//                           openAuthor: data.author?.login,
//                         ))
//                     .toList(),
//               );
//             }),
//       ],
//     );
//   }
// }

class IssueOrPullRequestDetailsPage extends StatelessWidget {
  const IssueOrPullRequestDetailsPage(
    this.item, {
    super.key,
    required this.repo,
  });

  final QLRepository repo;
  final QLIssueOrPullRequest item;

  bool get _isIssue => item is QLIssue;
  QLIssue get _issue => (item as QLIssue);
  bool get _isPull => item is QLPullRequest;
  QLPullRequest get _pull => (item as QLPullRequest);

  Widget _buildTitle() {
    return Wrap(
      runAlignment: WrapAlignment.start,
      runSpacing: 10,
      spacing: 10,
      children: [
        SelectableText.rich(
          TextSpan(
              text: item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              children: [
                TextSpan(
                  text: ' # ${item.number}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 20),
                )
              ]),
          selectionHeightStyle: ui.BoxHeightStyle.max,
          // style: TextStyle(fontFamily: appTheme.fontFamily),
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: TagLabel(
                  opacity: 1,
                  radius: 15,
                  text: IconText(
                    icon: DefaultIcons.issues,
                    iconColor: Colors.white,
                    spacing: 4,
                    text: Text(item.isOpen ? '打开' : '关闭',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                  color:
                      item.isOpen ? Colors.green.lighter : Colors.red.lighter),
            ),
            if (_isPull && _pull.isMerged)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TagLabel(
                    opacity: 1,
                    radius: 15,
                    text: const IconText(
                        spacing: 4,
                        icon: DefaultIcons.merged,
                        iconColor: Colors.white,
                        text: Text('已合并',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500))),
                    color: Colors.purple),
              ),
            if (_isIssue && _issue.issueType != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: IssueTypeLabel(_issue.issueType!, fontSize: 14),
              ),
            //TODO: 这里还差一个合并的标签
            const Spacer(),
            IconLinkButton.linkSource(
              "$githubUrl/${repo.fullName}/${_isIssue ? 'issues' : 'pull'}/${item.number}",
              //message: '在浏览器中打开',
            ),
          ],
        )
      ],
    );
  }

  Widget _buildRight() {
    return ListView(
      children: [
        // const Text('Assignees'),
        // const SizedBox(height: 10),
        // const Text('No one assigned'),
        // const Padding(
        //   padding: EdgeInsets.symmetric(vertical: 8.0),
        //   child: Divider(),
        // ),
        //
        const Text('标签'),
        const SizedBox(height: 10),
        if (item.labels.isNotEmpty)
          IssueLabels(labels: item.labels)
        else
          const Text('没有标签'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(),
        ),
        if (_isIssue && _issue.issueType != null) ...[
          const Text('类型'),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: IssueTypeLabel(_issue.issueType!),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
        ],
        //
        // const Text('Projects'),
        // const SizedBox(height: 10),
        // const Text('No projects'),
        // const Padding(
        //   padding: EdgeInsets.symmetric(vertical: 8.0),
        //   child: Divider(),
        // ),
        // //
        // const Text('Milestone'),
        // const SizedBox(height: 10),
        // const Text('No milestone'),
        // const Padding(
        //   padding: EdgeInsets.symmetric(vertical: 8.0),
        //   child: Divider(),
        // ),
        // //
        // const Text('Relationships'),
        // const SizedBox(height: 10),
        // const Text('None yet'),
        // const Padding(
        //   padding: EdgeInsets.symmetric(vertical: 8.0),
        //   child: Divider(),
        // ),
        // //
        // const Text('Development'),
        // const SizedBox(height: 10),
        // const Text('No branches or pull requests'),
        // const Padding(
        //   padding: EdgeInsets.symmetric(vertical: 8.0),
        //   child: Divider(),
        // ),
        // //
        // const Text('Participants'),
        // const SizedBox(height: 10),
        // const Text('参与者的头像'),
        // const Padding(
        //   padding: EdgeInsets.symmetric(vertical: 8.0),
        //   child: Divider(),
        // ),
      ],
    );
  }

  Widget _buildDefaultItem() {
    return IssueCommentItem(
        item: item,
        owner: repo.owner.login,
        openAuthor: item.author?.login,
        isFirst: true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _IssueOrPullRequestDetailsModel(),
      child: WantKeepAlive(
        onInit: (context) {
          APIWrap.instance.repoIssueOrPullRequestComments(repo,
              number: item.number, isIssues: _isIssue, onSecondUpdate: (value) {
            context.read<_IssueOrPullRequestDetailsModel>().comments = value;
          }).then((data) {
            context.read<_IssueOrPullRequestDetailsModel>().comments = data;
          });
        },
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: kPageDefaultVerticalPadding / 2.0,
            // start: PageHeader.horizontalPadding(context),
            //end: PageHeader.horizontalPadding(context),
            // end: kPageDefaultVerticalPadding / 2.0,
          ),
          child: Card(
            child: Column(
              children: [
                _buildTitle(),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
                  child: Divider(direction: Axis.horizontal),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectorQLList<_IssueOrPullRequestDetailsModel,
                            QLComment>(
                          selector: (_, model) => model.comments,
                          builder: (_, comments, __) {
                            return ListViewRefresher(
                              initData: comments,
                              itemBuilder: (context, item, index) {
                                Widget itemChild = IssueCommentItem(
                                    item: item,
                                    owner: repo.owner.login,
                                    openAuthor: item.author?.login);
                                if (index == 0) {
                                  itemChild = Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        _buildDefaultItem(),
                                        itemChild
                                      ]);
                                }
                                return itemChild;
                              },
                              onLoading: (QLPageInfo? pageInfo) async {
                                if (pageInfo == null || !pageInfo.hasNextPage) {
                                  return const QLList();
                                }
                                return APIWrap.instance
                                    .repoIssueOrPullRequestComments(
                                  repo,
                                  number: item.number,
                                  nextCursor: pageInfo.endCursor,
                                );
                              },
                              // 不需要强制刷新吧？
                              // onRefresh: () async {
                              //   return APIWrap.instance
                              //       .repoIssueOrPullRequestComments(repo,
                              //           number: item.number, force: true);
                              // },
                            );
                          },
                          defaultChild:
                              ListView(children: [_buildDefaultItem()]),
                        ),
                      ),
                      const SizedBox(width: 15),
                      SizedBox(width: 200, child: _buildRight())
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
