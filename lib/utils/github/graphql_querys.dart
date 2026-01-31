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

  /// 查询User的仓库列表
  /// [owner] 仓库所有者，User字段中的`login`
  ///
  /// [refs] 取值为 `refs/heads/` 或 `refs/tags/`
  ///
  /// [count] 取条数
  ///
  /// [sortDirection] 排序，可取值`DESC`或`ASC`
  ///
  /// [sortField] 排序，可取值`CREATED_AT`、`NAME`、`PUSHED_AT`、`STARGAZERS`、`UPDATED_AT`
  static String queryRepos({
    String owner = '',
    String refs = 'refs/heads/',
    int count = 30,
    String sortDirection = "DESC",
    String sortField = "CREATED_AT",
  }) {
    // 只查询user的仓库信息
    return '''  viewer {
    repositories(first:$count, orderBy: {direction: $sortDirection, field: $sortField}) {
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
          languages(first: 20) {
            nodes {
              color
              name
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
}
