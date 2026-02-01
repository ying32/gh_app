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
/// 分页 https://docs.github.com/zh/graphql/guides/using-pagination-in-the-graphql-api
///
///
class QLQueries {
  /// 查询用户信息
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#user
  ///
  /// [name] 如果为空则查询当前登录的User信息，需要header中加入认证的
  static String queryUser([String name = '']) {
    return '''  ${name.isEmpty ? 'viewer' : 'user(login:"$name")'} {
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
          isInOrganization
          owner {
            login
            avatarUrl
          }
          primaryLanguage {
            color
            name
          }
        }
      } 
    }
  }
''';
  }

  /// 查询一个组织信息
  static String queryOrganization(String name) {
    return '''  organization(login:"$name") {
    login
    name
    avatarUrl
    email
    location
    url
    websiteUrl
    pinnedItems(first: 6, types:REPOSITORY) {
      nodes {
        ... on Repository {
          name
          forkCount
          stargazerCount
          isPrivate
          description
          isInOrganization
          owner {
            login
            avatarUrl
          }
          primaryLanguage {
            color
            name
          }
        }
      } 
    }
  }
''';
  }

  /// 查询一个仓库信息
  /// [owner] 仓库所有者，User字段中的`login`
  ///
  /// [name] 仓库名称
  ///
  /// [refs] 取值为 `refs/heads/` 或 `refs/tags/`
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#repository
  static String queryRepo(String owner, String name,
      {String refs = 'refs/heads/'}) {
    return '''  repository(owner:"$owner", name:"$name") {
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
          color
          name
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
      watchers {
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
      refs(refPrefix: "$refs") {
        totalCount  
      }
      releases {
        totalCount 
      }
      repositoryTopics(first: 20) {
         nodes {
           topic {
             name
           }
         }
      }
    }
''';
  }

  /// 查询一个仓库信息
  /// [owner] 仓库所有者，User字段中的`login`
  ///
  /// [name] 仓库名称
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#releaseconnection
  ///
  /// https://docs.github.com/zh/graphql/reference/objects#release
  ///
  /// `CREATED_AT`和`NAME`
  static String queryRepoRelease(String owner, String name, {int count = 20}) {
    // 应该要按更新时间排，但是没有相应的值可选
    return '''  repository(owner:"$owner", name:"$name") {
      releases(first:$count, orderBy: {direction: DESC, field: CREATED_AT}) {
        totalCount 
        pageInfo {
          endCursor
          startCursor
          hasNextPage
          hasPreviousPage
        }
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
          releaseAssets(first: 50) {   
            totalCount 
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
    }''';
  }

  /// 查询User的仓库列表，只列出少量信息，具体到时候使用[queryRepo]来查询详细信息
  /// [owner] 仓库所有者，User字段中的`login`
  ///
  /// [count] 取条数
  ///
  /// [sortDirection] 排序，可取值`DESC`或`ASC`
  ///
  /// [sortField] 排序，可取值`CREATED_AT`、`NAME`、`PUSHED_AT`、`STARGAZERS`、`UPDATED_AT`
  static String queryRepos({
    String owner = '',
    int count = 50,
    String sortDirection = "DESC",
    String sortField = "CREATED_AT",
  }) {
    // 只查询user的仓库信息
    return '''  ${owner.isEmpty ? 'viewer' : 'user(login: "$owner")'} {
    repositories(first:$count, orderBy: {direction: $sortDirection, field: $sortField}) {
      totalCount
      pageInfo {
        endCursor
        startCursor
        hasNextPage
        hasPreviousPage
      }
      nodes {
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
          stargazerCount
          isArchived
          isPrivate
          pushedAt
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
        }
      } 
  }
''';
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
  static String queryRepoIssuesOrPullRequests(
    String owner,
    String name, {
    int count = 30,
    String states = 'OPEN',
    bool isIssues = true,
    String sortDirection = "DESC",
    String sortField = "CREATED_AT",
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
    return '''  repository(owner:"$owner", name:"$name") {
          ${isIssues ? 'issues' : 'pullRequests'}(last: $count, states:$states, orderBy: { direction:$sortDirection, field: $sortField} ) {
             totalCount
             pageInfo {
              endCursor
              startCursor
              hasNextPage
              hasPreviousPage
             }
             nodes {
                number 
                ${isIssues ? 'isPinned' : ''} 
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
                     name 
                     color 
                     description 
                     isDefault 
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
                ${isIssues ? 'viewerCanDelete' : ''} 
                viewerCanReopen 
             }
          }
    }      
''';
  }

  /// 查询文件
  ///
  ///   repository(owner: "ying32", name: "govcl") {
  //     object(expression: "master:") {
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
  static String queryObject(String owner, String name,
      {String expression = ""}) {
    // 不能获得二进制文件，可以使用REST API来获取，headers中添加 "Accept": "application/vnd.github.v3.raw"
    // 核心 REST 接口：GET /repos/{owner}/{repo}/contents/{path}（推荐）
    // 备选 REST 接口：GET /repos/{owner}/{repo}/git/blobs/{oid}（通过哈希 ID）

    // 根目录
    // expression: "master:"
    // 查询指定的
    // expression: "master:README.zh-CN.md"
    return '''
  repository(owner: "$owner", name: "$name") {
    object(expression: "master:$expression") {
        ... on Tree {
           entries {
              extension 
              language { name }
              isGenerated 
              lineCount 
              name 
              path 
              size 
              type 
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
''';
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
  static String search(String query,
      {int count = 15, String type = 'REPOSITORY'}) {
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
    return '''
  search(first: $count, query: "$query", type: $type) {
      pageInfo {
      endCursor
      startCursor
      hasNextPage
      hasPreviousPage
    }
    nodes {
       ... on Repository {
            name
            forkCount
            stargazerCount
            isPrivate
            description
            isInOrganization
            url
            owner {
              login
              avatarUrl
            }
            primaryLanguage {
              color
              name
            }
            pushedAt
          }
        }
      }
''';
  }
}
