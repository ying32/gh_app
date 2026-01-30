// 查询User
// viewer 换成   user(login:"ying32") 可以查其它用户的
const String qlQueryUser = '''query {
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
