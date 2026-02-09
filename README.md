# gh_app

一个Github桌面版App（样式仿照github Web版），使用github [GraphQL API V4](https://docs.github.com/zh/graphql) 实现

* flutter: 3.22.1
* dart: 3.4.1

## 前言

写这个的初衷是因为国内访问github太难了，但是使用API方式比较正常，而且官方的github桌面版实在用不习惯，貌似也满足不了我的要求。

## 进度

**注：因为对GraphQL也不熟，一边写一边学的，还有好多没完成的。。。。。**

* 认证（登录）
  * [x] Access Token
  * [ ] OAuth2
* 我的
  * [x] 基本信息
  * [x] 置顶的仓库
  * [x] 仓库列表
  * [x] star的仓库
  * [ ] 通知（没找到相关的，唯一个找到的结果相关api已经被移除了）
  * [ ] pull Requests
  * [ ] issues
* 搜索
  * [x] 搜索仓库
  * [ ] 搜索用户
  * [ ] 搜索代码
  * [ ] 搜索issues等
* 仓库
  * [x] 仓库基本信息
  * [x] 分支列表（部分，还有排序问题）
  * [x] 文件目录树
    * [x] 查看代码（部分，不太完善，能凑合） 
  * [ ] watch、fork、star按钮功能
  * [x] issues列表
    * [x] 查看指定issue评论信息（部分） 
      * [ ] Timelime
      * [ ] 评论修改和回复
  * [x] pull Requests列表
    * [x] 查看合并信息
  * [ ] Actions
  * [ ] Wiki
  * [x] Release列表
    * [x] Release Notes
    * [x] File Assets 列表
* 其它
  * [x] 部分`github.com/{login}/{name}*`等的跳转实现



## 其它

### github API

* [GraphQL v4](https://docs.github.com/zh/graphql)
* ~~[REST v3](https://docs.github.com/zh/rest)~~

### 代码修改

* [markdown_viewer-0.6.2](https://pub.dev/packages/markdown_viewer)
```
  // 修改原因，因为作者有很久没更新了，有些属性变化了
  //  markdown_viewer-0.6.2\lib\src\renderer.dart
  // 行： 50
  // 原： 
  ? Theme.of(context).textTheme.bodyText2?.color
  // 之后  
  ? Theme.of(context).textTheme.bodyMedium?.color
 
```

### API 的限制

* [GraphQL API 的速率限制和查询限制](https://docs.github.com/zh/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api)
* [REST API 的速率限制](https://docs.github.com/zh/rest/overview/rate-limits-for-the-rest-api)
