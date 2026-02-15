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

  final List<QLComment> comments = [];
  QLPageInfo? pageInfo;
  bool loading = true;

  void add(QLList<QLComment> data, bool reAdd) {
    if (reAdd) {
      comments.clear();
      pageInfo = null;
    }
    loading = false;
    pageInfo = data.pageInfo;
    if (data.isNotEmpty) {
      comments.addAll(data.data);
    }
    notifyListeners();
  }
}

/// issues的评论显示
class _IssuesCommentsView extends StatelessWidget {
  const _IssuesCommentsView(
    this.item, {
    required this.repo,
  });

  final QLIssueOrPullRequest item;
  final QLRepository repo;

  @override
  Widget build(BuildContext context) {
    return EasyListViewRefresher(
      hideFooterWhenNotFull: true,
      onLoading: (controller) async {
        final model = context.read<_IssueOrPullRequestDetailsModel>();
        if (model.pageInfo == null || !model.pageInfo!.hasNextPage) {
          return controller.loadNoData();
        }
        try {
          final list = await APIWrap.instance.repoIssueOrPullRequestComments(
              repo,
              number: item.number,
              nextCursor: model.pageInfo!.endCursor);
          model.add(list, false);
          if (list.isEmpty) {
            controller.loadNoData();
          } else {
            controller.loadComplete();
          }
        } catch (e) {
          controller.loadFailed();
        }
      },
      // 不需要强制刷新吧？
      // onRefresh: () async {
      //   return APIWrap.instance
      //       .repoIssueOrPullRequestComments(repo,
      //           number: item.number, force: true);
      // },
      listview: ListView(
        children: [
          // 首条评论
          IssueCommentItem(
              item: item,
              owner: repo.owner.login,
              openAuthor: item.author?.login,
              isFirst: true),
          // 其余的项目
          Consumer<_IssueOrPullRequestDetailsModel>(builder: (_, model, __) {
            // TODO: 这里还要判断其它状态，如果加载完成就
            if (model.loading) {
              return const LoadingRing();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: model.comments
                  .map((e) => IssueCommentItem(
                      item: e,
                      owner: repo.owner.login,
                      openAuthor: e.author?.login))
                  .toList(),
            );
          }),
          // 评论回复
          if (item is QLIssue)
            Padding(
              padding: const EdgeInsets.only(left: 70.0),
              child: IssueCommentEditor(item, repo: repo),
            )
        ],
      ),
    );
  }
}

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

  IconData get _tagIcon {
    if (_isIssue) {
      return DefaultIcons.issues;
    } else if (_pull.isMerged) {
      return DefaultIcons.merged;
    } else if (_pull.isDraft) {
      return DefaultIcons.pullRequestDraft;
    } else if (_pull.isOpen) {
      return DefaultIcons.pullRequest;
    }
    return DefaultIcons.closePullRequest;
  }

  String get _tagTitle {
    if (_isPull) {
      if (item.isOpen && _pull.isDraft) {
        return '草稿';
      } else if (_pull.isMerged) {
        return '已合并';
      }
    }
    if (item.isOpen) {
      return '打开';
    }
    return '关闭';
  }

  Color get _tagColor {
    if (_isPull) {
      if (item.isOpen && _pull.isDraft) {
        return Colors.orange.lighter;
      } else if (_pull.isMerged) {
        return Colors.purple;
      }
    }
    if (item.isOpen) {
      return Colors.green.lighter;
    }
    return Colors.red.lighter;
  }

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
            TagLabel(
                opacity: 1,
                radius: 15,
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                text: IconText(
                  icon: _tagIcon,
                  iconColor: Colors.white,
                  spacing: 4,
                  text: Text(_tagTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ),
                color: _tagColor),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _IssueOrPullRequestDetailsModel(),
      child: WantKeepAlive(
        onInit: (context) {
          APIWrap.instance.repoIssueOrPullRequestComments(repo,
              number: item.number, isIssues: _isIssue, onSecondUpdate: (value) {
            context.read<_IssueOrPullRequestDetailsModel>().add(value, true);
          }).then((data) {
            context.read<_IssueOrPullRequestDetailsModel>().add(data, true);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
                  child: Divider(direction: Axis.horizontal),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _IssuesCommentsView(item, repo: repo)),
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
