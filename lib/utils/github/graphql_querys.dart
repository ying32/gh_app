import 'dart:convert';

import 'package:gh_app/utils/consts.dart';

///=============================================================================

/// GraphQL查询
class QLQuery {
  const QLQuery(
    this.document, {
    this.variables,
    this.operationName,
    this.isQuery = true,
  });

  /// ql语句（这东西貌似是称为document），不包含query{}或者mutation {}的主体
  final String document;

  /// 关于变量的定义
  ///
  /// ```
  ///   # 以 $ 开头的
  ///   #  $login: String  // 可为null的，但貌似需得有默认值？[variables]可不存在
  ///   #  $login: String = "ying32" // 允许为null的，而且指定了默认值[variables]可不存在
  ///   #  $login: String!  // 不允许为null，[variables]中必须要有
  ///   query($)
  /// ```
  ///
  /// [body]中使用的变量
  final Map<String, dynamic>? variables;

  /// 这个我也不知道干啥的（难道是有多个ql语句指定操作哪个的？？？，没研究过）
  final String? operationName;
  final bool isQuery;

  /// 编码后的graphql
  String get jsonText => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        //TODO: mutation 是不是这样操作呢？还没测试过，到时候测试了再说吧
        //"query": isQuery ? "query {\n $body \n}" : "mutation {\rn $body \n}",
        "query": document,
        if (variables != null) "variables": variables,
        if (operationName != null) "operationName": operationName,
      };
}

///NOTE: 当如果列表类型有多种时，需要使用 `... on TYPE`来选择记录，否则不需要使用这个，当然使用了也没问题
///比如：
///```json
///    pinnedItems(first: 6, types:REPOSITORY) {
///       nodes {
///         ... on Repository {
///           name
///           forkCount
///           stargazerCount
///           isPrivate
///           description
///           owner {
///             login
///           }
///           primaryLanguage {
///             color
///             name
///           }
///         }
///       }
///     }
///```
///
/// "nameWithOwner": "ying32/govcl",
///
///
///
/// 分页 https://docs.github.com/zh/graphql/guides/using-pagination-in-the-graphql-api
///
/// TODO: 正常来说时面的数据都要使用变量来传递，但是我懒得弄哈，以后再优化吧
class QLQueries {
  static const _repoLiteFieldsNoRef = '''
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
          updatedAt
          url
          forkCount
          isInOrganization
          stargazerCount
          isArchived
          isPrivate
          pushedAt
          isFork
          parent {
            #nameWithOwner 
            name 
            owner {
              login
              avatarUrl
            }
          }  ''';

  static const _repoLiteFields = '''
          $_repoLiteFieldsNoRef
          defaultBranchRef {
            name
          }     
 ''';

  static const _licAndTopics = '''
          licenseInfo {
             name 
          }      
          repositoryTopics(first: 20) {
             totalCount
             nodes {
               topic {
                 name
               }
             }
          }  
''';
  static const _repoLiteFields2NoRef = '''
         $_repoLiteFieldsNoRef
         $_licAndTopics
''';
  static const _repoLiteFields2 = '''
         $_repoLiteFields 
         $_licAndTopics 
''';

  static const _pinnedItemsQuery = '''
    pinnedItems(first: 6, types:REPOSITORY) {
      nodes {
        ... on Repository {
           $_repoLiteFields
        }
      } 
    }
''';

  /// 页面信息，也许会增加一个`totalCount`字段？？？
  static const _pageInfo = '''
      #totalCount
      pageInfo { 
        endCursor 
        # startCursor 
        hasNextPage 
        #hasPreviousPage 
     }''';

  static const _userFieldsFragment = '''
fragment userFields on User {
  login
  avatarUrl
  url
  name
  company
  bio
  email
  location
  twitterUsername
  isViewer 
  websiteUrl
  followers { totalCount }
  following { totalCount }
  repositories { totalCount }
  status { emoji emojiHTML message }
  $_pinnedItemsQuery
} 
''';

  static const _organizationFieldsFragment = '''
fragment organizationFields on Organization {
  login
  avatarUrl
  url
  name
  email
  location
  twitterUsername
  websiteUrl
  repositories { totalCount }
  $_pinnedItemsQuery
} 
''';

  /// 查询登录用户信息
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#user
  ///
  /// [name] 如果为空则查询当前登录的User信息，需要header中加入认证的
  static QLQuery queryViewer() {
    //TODO: 这里还缺个组织用户的
    return const QLQuery('''
query {  
  viewer {
    __typename
    ... on User {
      ...userFields
    }
  }
}
$_userFieldsFragment
''');
  }

  /// 查询用户信息
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#user
  ///
  /// [name] 如果为空则查询当前登录的User信息，需要header中加入认证的
//   static QLQuery queryUser([String name = '']) {
//     return QLQuery('''
// query(\$login: String!, \$isViewer: Boolean!) {
//   viewer @include(if: \$isViewer) {
//     __typename
//     ...userFields
//   }
//   user(login:\$login) @skip(if: \$isViewer) {
//     __typename
//     ...userFields
//   }
// }
// $_userFieldsFragment
// ''', variables: {"login": name, "isViewer": name.isEmpty});
//   }
//
//   /// 查询一个组织信息
//   static QLQuery queryOrganization(String name) {
//     return QLQuery('''query(\$login: String!) {
//   organization(login:\$login) {
//     ...organizationFields
//   }
// }
// $_organizationFieldsFragment
// ''', variables: {"login": name});
//   }

  /// 查询“我”关注的或者关注“我”的用户信息
  static QLQuery queryFollowerUsers(
      {String name = '',
      bool isFollowers = true,
      int? count,
      String? nextCursor}) {
    final func = isFollowers ? 'followers' : 'following';
    return QLQuery('''query(\$first:Int!, \$after:String) {  
    viewer {
    $func(first: \$first, after:\$after) {
      #totalCount
      $_pageInfo
      nodes {
        login name avatarUrl bio
      }
    }
  }
}''', variables: {
      "first": count ?? defaultPageSize,
      "after": nextCursor,
    });

//     return '''query($isFollowers: Boolean = true) {  viewer {
//     followers(first: 10) @include(if: $isFollowers) {
//       totalCount
//       nodes {
//          login name
//       }
//     }
//     following @skip(if: $isFollowers) {
//       totalCount
//     }
//   }
// }''';
  }

  /// 查询一个仓库信息
  /// [owner] 仓库所有者，User字段中的`login`
  ///
  /// [name] 仓库名称
  ///
  /// [refs] 取值为 `refs/heads/` 或 `refs/tags/`
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#repository
  static QLQuery queryRepo(String owner, String name) {
    /// 默认分支的最后一个提交，方法一
    ///      defaultBranchRef {
    ///         name
    ///         target {
    ///           ... on Commit {
    ///             history(first: 1){  edges { node { oid messageHeadline } } }
    ///           }
    ///         }
    ///       }

    /// 默认分支的最后一个提交，方法二
    /// 指定某分支，则替换为 ref(qualifiedName :"refs/heads/master")，可惜不能用HEAD
    ///       defaultBranchRef {
    ///          target {
    ///             ... on Commit {
    ///                oid
    ///                message
    ///                authoredDate
    ///                url
    ///                author   {  name avatarUrl   }
    ///             }
    ///          }
    ///      }
    ///
    /// 使用条件方式
    ///
    ///       defaultBranchRef {
    ///         name
    ///         target {
    ///           __typename
    ///           ... on Commit {
    ///             history(first: 1){  nodes {  oid messageHeadline  } }
    ///           }
    ///         }
    ///       }
    ///
    /// query($incTarget: Boolean = false) {
    ///   repository(owner: "ying32", name: "govcl") {
    ///       defaultBranchRef {
    ///          name
    ///          target @include(if: $incTarget) {
    ///             ... on Commit {
    ///                history(first: 1){  edges { node { oid messageHeadline } } }
    ///             }
    ///          }
    ///      }
    ///   }
    /// }
    ///

    return QLQuery('''query(\$owner:String!,\$name:String!) { 
    repository(owner:\$owner, name:\$name) {
          $_repoLiteFields2NoRef
          defaultBranchRef {
             name
             target {
               __typename
               ... on Commit {
                   abbreviatedOid 
                   author { name avatarUrl } 
                   committedDate 
                   message 
                   messageHeadline
                   #oid
                   #blame(path:"README.md") {
                   #     ranges { commit { author { name } committedDate  message }  }
                   #}
                }
             }
           }
          archivedAt
          diskUsage
          forkingAllowed
          hasIssuesEnabled
          hasProjectsEnabled
          hasSponsorshipsEnabled
          hasWikiEnabled
          homepageUrl
          isBlankIssuesEnabled
          isDisabled
          isEmpty
          isLocked
          isMirror
          isTemplate
          isSecurityPolicyEnabled
          viewerCanSubscribe
          viewerHasStarred
          viewerPermission
          viewerSubscription
          mirrorUrl
          languages(first: 40) {
            nodes {
              color
              name
            }
          }
          issues(states:OPEN) {
            totalCount
          }
          pullRequests(states:OPEN) {
            totalCount
          }
          watchers {
            totalCount
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
          tags: refs(refPrefix: "refs/tags/") {
            totalCount
          }
          releases {
            totalCount
          }
    }
   
}''', variables: {"owner": owner, "name": name});
  }

  /// 查询一个仓库信息的releases
  /// [owner] 仓库所有者，User字段中的`login`
  ///
  /// [name] 仓库名称
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#releaseconnection
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#release
  ///
  /// `CREATED_AT`和`NAME`
  static QLQuery queryRepoReleases(String owner, String name,
      {int? count, String? nextCursor}) {
    // 应该要按更新时间排，但是没有相应的值可选
    return QLQuery('''query(\$owner:String!, \$name:String!, \$first:Int!, \$after:String) { 
    repository(owner:\$owner, name:\$name) {
      releases(first:\$first, after: \$after, orderBy: {direction: DESC, field: CREATED_AT}) {
        #totalCount 
        $_pageInfo
        nodes {
          author { 
            login 
            name 
            avatarUrl
          }
          name
          tagName
          updatedAt
          url
          createdAt
          isDraft
          isLatest
          isPrerelease
          description
          tagCommit { 
            abbreviatedOid
          }
          releaseAssets {   
            totalCount 
          }
        }
      }
    }
}''', variables: {
      "owner": owner,
      "name": name,
      "first": count ?? defaultPageSize,
      "after": nextCursor
    });
  }

  /// 查询仓库指定Release的Assets
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#repository
  static QLQuery queryRepoReleaseAssets(String owner, String name,
      {required String tagName, int? count, String? nextCursor}) {
    // 应该要按更新时间排，但是没有相应的值可选
    return QLQuery('''query(\$owner:String!, \$name:String!, \$first:Int!, \$after:String, \$tagName:String!) {
    repository(owner:\$owner, name:\$name) {
      release(tagName:\$tagName) {
        releaseAssets(first:\$first, after: \$after) {   
          totalCount 
          $_pageInfo
          nodes {
            contentType
            createdAt
            downloadCount
            downloadUrl
            name
            size
            updatedAt
          }
        }
      }
    }
}''', variables: {
      "owner": owner,
      "name": name,
      "first": count ?? defaultPageSize,
      "after": nextCursor,
      "tagName": tagName,
    });
  }

  /// 查询User的仓库列表，只列出少量信息，具体到时候使用[queryRepo]来查询详细信息
  /// [owner] 仓库所有者，User字段中的`login`
  ///
  /// [count] 取条数
  ///
  /// [sortDirection] 排序，可取值`DESC`或`ASC`
  ///
  /// [sortField] 排序，可取值`CREATED_AT`、`NAME`、`PUSHED_AT`、`STARGAZERS`、`UPDATED_AT`
  static QLQuery queryRepos({
    String owner = '',
    int? count,
    bool isStarred = false,
    String? nextCursor,
    bool isOrganization = false,
  }) {
    final userFunc = owner.isEmpty
        ? 'viewer'
        : (isOrganization
            ? 'organization(login: "$owner")'
            : 'user(login: "$owner")');
    final func = isStarred ? 'starredRepositories' : 'repositories';
    final sortField = isStarred ? 'STARRED_AT' : 'STARGAZERS';
    //final fragmentType = isOrganization ? 'Organization' : 'User';
    final openIssueCount =
        isStarred ? '' : 'issues(states: OPEN) { totalCount }';

//     const starReposField = '''
//   # StarredRepositoryConnection
//   starredRepositories(first:\$first, after:\$after, orderBy: {direction:DESC, field:STARRED_AT}) @include(if: \$isStarred) {
//     totalCount
//     $_pageInfo
//     nodes {
//       ...RepoFields
//     }
//   }
// ''';
//
//     const viewerField = '''
// viewer @include(if: \$isViewer) {
//     ...RepoList
//   }
// ''';

    return QLQuery('''
query(\$first:Int!, \$after:String)  {
  $userFunc {
    $func(first:\$first, after:\$after, orderBy: {direction:DESC, field:$sortField})  {
      totalCount
      $_pageInfo
      nodes {
        ...RepoFields
        $openIssueCount
      }
    }
  }
}

fragment RepoFields on Repository {
 $_repoLiteFields2
}  
''', variables: {
      "first": count ?? defaultPageSize,
      "after": nextCursor,
    });

    // 贡献过的仓库 topRepositories
//     if (isStarred) {
//       // 只有这一个参数
//       sortField = 'STARRED_AT';
//     }
//     // 我的仓库按星数量排序
//     if (owner.isEmpty && !isStarred) {
//       sortField = 'STARGAZERS';
//     }
//
//     // 只查询user的仓库信息
//     return '''query {  ${owner.isEmpty ? 'viewer' : 'user(login: "$owner")'} {
//     ${isStarred ? 'starredRepositories' : 'repositories'}(first:${count ?? defaultPageSize}${_getNextCursor(nextCursor)}, orderBy: {direction: $sortDirection, field: $sortField}) {
//       totalCount
//       $_pageInfo
//       nodes {
//           $_repoLiteFields2
//           ${isStarred ? '' : 'issues(states: OPEN) { totalCount }'}
//         }
//       }
//   }
// }''';
  }

  /// 查询仓库issues或者pullRequests
  ///
  /// [owner] 仓库所有者User`login`字段的
  ///
  /// [name] 仓库中名
  ///
  /// [count] 取条数
  ///
  /// [states] 取值 `OPEN` 和 `CLOSED`，如果[isIssues=false]时可多取值`MERGED`
  ///
  /// [isIssues] 是查询issues还是pullRequests
  ///
  /// [sortDirection] 排序，可取值`DESC`或`ASC`
  ///
  /// [sortField] 排序，可取值`CREATED_AT`、`UPDATED_AT`，如果是[isIssues=true]或者多取值`COMMENTS`
  static QLQuery queryRepoIssuesOrPullRequests(
    String owner,
    String name, {
    int? count,
    String states = 'OPEN',
    bool isIssues = true,
    String sortDirection = "DESC",
    String sortField = "CREATED_AT",
    String? nextCursor,
  }) {
    // 查询一个仓库的issues信息
    //                   timeline(after: 10) {
    //                        totalCount
    //                        nodes {
    //                           ... on IssueTimelineItem {
    //
    //                           }
    //                        }
    //                     }
    // ${isIssues ? 'isPinned' : ''}
    // ${isIssues ? 'viewerCanDelete' : ''}
    //                milestone {
    //                   closed
    //                   closedAt
    //                   description
    //                 }
    //                 closed

    final func = isIssues ? 'issues' : 'pullRequests';
    final issueTypeField =
        isIssues ? 'issueType { color description isEnabled name  }' : '';

    return QLQuery('''
query(\$owner:String!, \$name:String!, \$first:Int!, \$after:String) { 
  repository(owner:\$owner, name:\$name) {
    $func(first: \$first, after:\$after, states:$states, orderBy: { direction:$sortDirection, field: $sortField} ) {
       totalCount
       $_pageInfo
       nodes {
          number 
          author {
             login avatarUrl
          }
          title 
          body
          #bodyHTML
          comments { totalCount }
          closedAt
          createdAt
          editor {
            login avatarUrl
          }
          $issueTypeField
          labels(first: 20, orderBy: { direction:ASC, field: NAME }) {
             nodes {
               name 
               color 
               description 
               isDefault 
             }
          }
          lastEditedAt 
          locked 
          state 
          updatedAt 
          viewerCanClose 
          viewerCanReopen 
       }
    }
  }      
}''', variables: {
      "owner": owner,
      "name": name,
      "first": count ?? defaultPageSize,
      "after": nextCursor,
    });
  }

  /// 查询文件
  ///
  //   repository(owner: "ying32", name: "govcl") {
  //     object(expression: "HEAD:") {
  //         ... on Tree {
  //
  //            entries {
  //               oid
  //               extension
  //               language { name }
  //               isGenerated
  //               lineCount
  //               name
  //               path
  //               size
  //               type
  //            }
  //         }
  //        ... on Blob {
  //            byteSize
  //            isBinary
  //            isTruncated
  //            text
  //         }
  //
  //        ... on Commit {
  //            additions
  //        }
  //
  //        ... on Tag {
  //
  //            message name oid
  //        }
  //     }
  //   }
  /// https://docs.github.com/zh/graphql/reference/objects#repository
  ///
  /// https://docs.github.com/zh/graphql/reference/interfaces#gitobject
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#tree
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#treeentry
  static QLQuery queryGitObject(String owner, String name,
      {String path = "", String? ref}) {
    // 不能获得二进制文件，可以使用REST API来获取，headers中添加 "Accept": "application/vnd.github.v3.raw"
    // 核心 REST 接口：GET /repos/{owner}/{repo}/contents/{path}（推荐）
    // 备选 REST 接口：GET /repos/{owner}/{repo}/git/blobs/{oid}（通过哈希 ID）

    // 根目录
    // expression: "master:" expression: "HEAD:"
    // 查询指定的
    // expression: "master:README.zh-CN.md"
    // entries
    // 用不上
    // entries {
    //   extension
    //   language { name }
    //   lineCount
    // }

    return QLQuery('''
query(\$owner:String!, \$name:String!, \$expression:String!) {
  repository(owner: \$owner, name: \$name) {
    object(expression: \$expression) {
        __typename
        ... on Tree {
           entries { 
              isGenerated 
              name 
              path 
              size 
              type 
              submodule {
                branch gitUrl name path 
              }
           }
        }
       ... on Blob {
           oid
           byteSize 
           isBinary 
           isTruncated 
           text 
        }
    }
  }    
}''', variables: {
      "owner": owner,
      "name": name,
      "expression": "${ref == null || ref.isEmpty ? 'HEAD' : ref}:$path"
    });
  }

  /// 搜索
  ///
  /// https://docs.github.com/zh/graphql/reference/queries#search
  ///
  /// 搜索结果
  /// https://docs.github.com/zh/graphql/reference/objects#searchresultitemconnection
  ///
  /// 可用对象
  /// https://docs.github.com/zh/graphql/reference/unions#searchresultitem
  ///
  /// [query] 查询条件，相关语法
  /// Searching on GitHub: https://docs.github.com/search-github/searching-on-github
  ///
  /// Understanding the search syntax: https://docs.github.com/search-github/getting-started-with-searching-on-github/understanding-the-search-syntax
  ///
  /// Sorting search results: https://docs.github.com/search-github/getting-started-with-searching-on-github/sorting-search-results
  ///
  /// [type] 要搜索的类型 https://docs.github.com/zh/graphql/reference/enums#searchtype
  ///
  ///  `DISCUSSION`、`ISSUE` `ISSUE_ADVANCED` `REPOSITORY` `USER`
  static QLQuery search(String query,
      {int? count, String type = 'REPOSITORY', String? nextCursor}) {
    /// ... on Discussion { }
    /// ... on Issue { }
    /// ... on Organization { }
    /// ... on Repository { }
    /// ... on User { }
    /// ... on PullRequest { }
    /// ... on MarketplaceListing { }
    /// ... on App { }

    /// codeCount
    /// discussionCount
    /// issueCount
    /// pageInfo
    /// repositoryCount
    /// userCount
    /// wikiCount
    ///

    return QLQuery('''
query(\$first:Int!, \$after:String, \$query:String!, \$type:SearchType=REPOSITORY) {
  search(first: \$first, after:\$after, query: \$query, type: \$type) {
    repositoryCount
    $_pageInfo
    nodes {
       ... on Repository {
             $_repoLiteFields2
          }
        }
      }
}
    ''', variables: {
      "first": count ?? defaultPageSize,
      "after": nextCursor,
      "query": query,
      "type": type
    });

//     return '''query {
//   search(first: ${count ?? defaultPageSize}${_getNextCursor(nextCursor)}, query: "$query", type: $type) {
//     repositoryCount
//     $_pageInfo
//     nodes {
//        ... on Repository {
//              $_repoLiteFields2
//           }
//         }
//       }
// }''';
  }

  /// 查询仓库指定Release的Assets
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#repository
  ///
  /// [refPrefix] 可取值： `refs/heads/`, `refs/tags/`
  static QLQuery queryRepoRefs(String owner, String name,
      {int? count, String refPrefix = 'refs/heads/', String? nextCursor}) {
    return QLQuery('''
query(\$owner:String!, \$name:String!, \$first:Int!, \$after:String, \$refPrefix:String!) {
    repository(owner:\$owner, name:\$name) {
       refs(first:\$first, after:\$after, refPrefix:\$refPrefix, orderBy: {direction: DESC, field: TAG_COMMIT_DATE}) {
          totalCount 
          $_pageInfo
          nodes { name prefix }
       }
    }
}
''', variables: {
      "owner": owner,
      "name": name,
      "first": count ?? defaultPageSize,
      "after": nextCursor,
      "refPrefix": refPrefix,
    });

//     // 排序的字段可取值： ALPHABETICAL  TAG_COMMIT_DATE
//     return '''query {
//     repository(owner:"$owner", name:"$name") {
//        refs(first: ${count ?? defaultPageSize}${_getNextCursor(nextCursor)}, refPrefix: "$refPrefix", orderBy: {direction : DESC, field: TAG_COMMIT_DATE}) {
//           totalCount
//           $_pageInfo
//           nodes  { name prefix }
//        }
//     }
// }''';
  }

  /// 提交的评论
  /// // , orderBy : {direction : DESC, field: UPDATED_AT}
  /// // https://docs.github.com/zh/graphql/reference/objects#issue
  static QLQuery queryIssueComments(String owner, String name, int number,
      {int? count, bool isIssues = true, String? nextCursor}) {
    // 排序的字段可取值： ALPHABETICAL  TAG_COMMIT_DATE

    final func = isIssues ? 'issue' : 'pullRequest';
    return QLQuery('''query(\$owner:String!, \$name:String!, \$number:Int!, \$first:Int!, \$after:String) { 
   repository(owner:\$owner, name:\$name) {
       $func(number: \$number) {
          comments  (first:\$first, after:\$after) {
               totalCount
               $_pageInfo
               nodes {
                  author { login avatarUrl }
                  body
                  #bodyHTML
                  createdAt 
                  editor { login avatarUrl  }
                  lastEditedAt 
                  publishedAt 
                  updatedAt 
                  isMinimized 
                  url 
                  viewerCanDelete
                  viewerCanUpdate 
                  viewerDidAuthor 
                }
          }   
       }
     }
}''', variables: {
      "owner": owner,
      "name": name,
      "number": number,
      "first": count ?? defaultPageSize,
      "after": nextCursor,
    });

//     return '''query {
//    repository(owner:"$owner", name:"$name") {
//        ${isIssues ? 'issue' : 'pullRequest'}(number: $number) {
//           comments  (first:${count ?? defaultPageSize}${_getNextCursor(nextCursor)}) {
//                totalCount
//                $_pageInfo
//                nodes {
//                   author { login avatarUrl }
//                   body
//                   #bodyHTML
//                   createdAt
//                   editor { login avatarUrl  }
//                   lastEditedAt
//                   publishedAt
//                   updatedAt
//                   isMinimized
//                   url
//                   viewerCanDelete
//                   viewerCanUpdate
//                   viewerDidAuthor
//                 }
//           }
//        }
//      }
// }''';
  }

  /// 查询指定issue或者pullRequest
  static QLQuery queryIssueOrPullRequest(
      String owner, String name, int number) {
    // 本想用  fragment 来利用字段，但怎么写都不成功

    return QLQuery('''
query(\$owner:String!, \$name:String!, \$number:Int!) { 
   repository(owner:\$owner, name:\$name) {
       issueOrPullRequest(number: \$number) {
              __typename
               ... on Issue {
                  number
                  author { login avatarUrl }
                  title  body  
               }
              ... on PullRequest {
                  number
                  author { login avatarUrl }
                  title  body  
              }
       }
     }
}    
''', variables: {
      "owner": owner,
      "name": name,
      "number": number,
    });

//     return '''query {
//    repository(owner:"$owner", name:"$name") {
//        issueOrPullRequest  (number: $number) {
//               __typename
//                ... on Issue {
//                   number
//                   author { login avatarUrl }
//                   title  body
//                }
//               ... on PullRequest {
//                   number
//                   author { login avatarUrl }
//                   title  body
//               }
//        }
//      }
// }''';
//     return '''query {
//    repository(owner:"$owner", name:"$name") {
//        ${isIssues ? 'issue' : 'pullRequest'}(number: $number) {
//                 number
//                 author {
//                    login avatarUrl
//                 }
//                 title  body
//        }
//      }
// }''';
  }

  /// 查询一个仓库的所有者信息，通过这个接口可以查询一个login的信息
  static QLQuery queryRepoOwner(String login) {
    return QLQuery('''
query(\$login:String!) { 
  repositoryOwner(login:\$login) {
    __typename  
    #login
    #url 
    #avatarUrl
    ... on User {
      ...userFields
    }
    ... on Organization {
      ...organizationFields
    }
  }
}
$_userFieldsFragment
$_organizationFieldsFragment
''', variables: {
      "login": login,
    });
  }
}

///issue timelines
///
/// https://docs.github.com/zh/graphql/reference/objects#issue
///
///https://docs.github.com/zh/graphql/reference/objects#issuetimelineconnection
///
///https://docs.github.com/zh/graphql/reference/unions#issuetimelineitem
///
///
/// IssueTimelineItem 可能的类型
/// AssignedEvent
/// ClosedEvent
/// Commit
/// CrossReferencedEvent
/// DemilestonedEvent
/// IssueComment
/// LabeledEvent
/// LockedEvent
/// MilestonedEvent
/// ReferencedEvent
/// RenamedTitleEvent
/// ReopenedEvent
/// SubscribedEvent
/// TransferredEvent
/// UnassignedEvent
/// UnlabeledEvent
/// UnlockedEvent
/// UnsubscribedEvent
/// UserBlockedEvent
//query {
//    repository(owner:"zed-industries", name:"zed") {
//        issue(number: 48231) {
//           timeline(first: 15) {
//             nodes {
//              __typename
//               ... on Commit { author { __typename name } message }
//               ... on IssueComment { author { login } body }
//               ... on AssignedEvent { actor  { login }   }
//               ... on ClosedEvent  { actor  { login }   }
//               ... on SubscribedEvent   { actor  { login }   }
//               ... on LabeledEvent    { actor  { __typename login } label { __typename color name  } }
//             }
//           }
//        }
//    }
// }
