import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/link.dart';
import 'package:window_manager/window_manager.dart';

/// 带icon前缀的文本
class IconText extends StatelessWidget {
  const IconText({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 16.0,
    this.spacing = 8.0,
    this.padding,
    this.iconColor,
    this.trailing,
    this.expanded = false,
  });

  final IconData icon;
  final Widget text;
  final double iconSize;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;
  final Widget? trailing;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    Widget widget = Row(
        mainAxisSize: MainAxisSize.min,
        // crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          SizedBox(width: spacing),
          expanded ? Expanded(child: text) : text,
          if (trailing != null) ...[
            SizedBox(width: spacing),
            trailing!,
          ],
        ]);
    if (padding != null) {
      widget = Padding(padding: padding!, child: widget);
    }
    return widget;
  }
}

/// 小型的标签类的
class TagLabel extends StatelessWidget {
  const TagLabel({
    super.key,
    this.color = Colors.black,
    required this.text,
    this.padding,
    this.radius,
    this.opacity,
  });

  final Color color;
  final Widget text;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      decoration: BoxDecoration(
        // 背景
        color: color.withOpacity(opacity ?? 0.1),
        border: Border.all(
          color: color.withOpacity(opacity ?? 0.1),
        ),
        borderRadius: BorderRadius.circular(radius ?? 10.0),
      ),
      child: text,
    );
  }

  const TagLabel.archived({super.key, this.padding, this.radius})
      : color = m.Colors.orange,
        opacity = null,
        text = const Text('已归档 ',
            style: TextStyle(fontSize: 11, color: m.Colors.orange));

  const TagLabel.private({super.key, this.padding, this.radius})
      : color = m.Colors.black,
        opacity = null,
        text = const Text('私有 ', style: TextStyle(fontSize: 11));

  const TagLabel.public({super.key, this.padding, this.radius})
      : color = m.Colors.black,
        opacity = null,
        text = const Text('公开 ', style: TextStyle(fontSize: 11));

  factory TagLabel.other(String text,
          {Color color = m.Colors.black,
          EdgeInsetsGeometry? padding,
          double? radius,
          FontWeight? fontWeight}) =>
      TagLabel(
          color: color,
          padding: padding,
          radius: radius,
          text: Text(text,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: fontWeight)));
}

/// 链接跳转的？？？？
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
    this.borderRadius,
  });

  final Widget text;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return m.Material(
      // color: Colors.transparent,
      type: m.MaterialType.transparency,
      child: m.InkWell(
        borderRadius: borderRadius,
        onTap: onPressed,
        child: Padding(padding: padding, child: text),
      ),
    );
  }
}

/// 一个icon样式的带跳转本地open的
class IconLinkButton extends StatelessWidget {
  const IconLinkButton({
    super.key,
    required this.icon,
    required this.link,
    this.message,
  });

  final Widget icon;
  final String link;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse(link),
      builder: (context, followLink) => Semantics(
        link: true,
        child: Tooltip(
          message: message ?? link,
          child: IconButton(
            icon: icon,
            onPressed: () => followLink?.call(),
          ),
        ),
      ),
    );
  }

  /// 使用[DefaultIcon.linkSource]图标的
  const IconLinkButton.linkSource(this.link, {super.key, this.message})
      : icon = const DefaultIcon.linkSource(size: 18);
}

/// 初始加载数据
class WrapInit extends StatefulWidget {
  const WrapInit({
    super.key,
    required this.child,
    required this.onInit,
  });

  final Widget child;
  final ValueChanged<BuildContext> onInit;

  @override
  State<WrapInit> createState() => _WrapInitState();
}

class _WrapInitState extends State<WrapInit> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.onInit.call(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// icon样式的弹出菜单
class IconPopupMenu extends StatelessWidget {
  const IconPopupMenu({
    super.key,
    required this.icon,
    required this.items,
    this.tooltip,
  });

  final Widget icon;
  final String? tooltip;
  final List<MenuFlyoutItemBase> items;

  @override
  Widget build(BuildContext context) {
    Widget child = DropDownButton(
      buttonBuilder: (_, onOpen) => IconButton(icon: icon, onPressed: onOpen),
      leading: const SizedBox.shrink(),
      trailing: const SizedBox.shrink(),
      items: items,
    );
    if (tooltip != null) {
      child = Tooltip(message: tooltip, child: child);
    }
    return child;
  }
}

/// 窗口标标题栏和按钮
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: FluentTheme.of(context).brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

/// 分页按钮，嗯，先放着
/// TODO: 这个分页组件还没完全实现，只是简单的弄下。
/// 另外这个感觉不能在GraphQL API里面使用吧，只适合REST API的，
/// 估计得改下，改为上拉加载数据
// class PaginationBar extends StatefulWidget {
//   const PaginationBar({
//     super.key,
//     required this.pageInfo,
//     required this.totalCount,
//     required this.pageSize,
//   });
//
//   @override
//   State<PaginationBar> createState() => _PaginationBarState();
//
//   final QLPageInfo pageInfo;
//   final int totalCount;
//   final int pageSize;
// }
//
// class _PaginationBarState extends State<PaginationBar> {
//   List<Widget> _buildPageButtons() {
//     if (widget.totalCount > 0 && widget.pageSize > 0) {
//       final res = <Widget>[];
//       for (int i = 1; i <= (widget.totalCount / widget.pageSize).ceil(); i++) {
//         res.add(Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 3.0),
//           child: Button(
//               child: Text("$i"),
//               onPressed: () {
//                 showInfoDialog('没有实现', context: context);
//               }),
//         ));
//       }
//       return res;
//     }
//     return [];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Button(
//             onPressed: widget.pageInfo.hasPreviousPage
//                 ? () {
//                     showInfoDialog('没有实现', context: context);
//                   }
//                 : null,
//             child: const Text('上一页')),
//         const SizedBox(width: 10),
//         Container(
//           constraints:
//               BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 3),
//           child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: _buildPageButtons(),
//               )),
//         ),
//
//         // Padding(
//         //   padding: const EdgeInsets.symmetric(horizontal: 10.0),
//         //   child: Text('${widget.totalCount}'),
//         // ),
//         const SizedBox(width: 10),
//         Button(
//             onPressed: widget.pageInfo.hasNextPage
//                 ? () {
//                     showInfoDialog('没有实现', context: context);
//                   }
//                 : null,
//             child: const Text('下一页')),
//       ],
//     );
//   }
// }

typedef AsyncNextQLListGetter<T> = Future<QLList<T>> Function(QLPageInfo?);
typedef AsyncQLListGetter<T> = Future<QLList<T>> Function();

/// 可以上拉刷新和下拉加载的ListView包装
class ListViewRefresher<T> extends StatefulWidget {
  const ListViewRefresher({
    super.key,
    required this.initData,
    required this.itemBuilder,
    this.separator,
    this.padding,
    this.onRefresh,
    this.onLoading,
  });

  final QLList<T> initData;
  final Widget? separator;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext, T item, int) itemBuilder;
  final AsyncQLListGetter<T>? onRefresh;
  final AsyncNextQLListGetter<T>? onLoading;

  @override
  State<ListViewRefresher<T>> createState() => _ListViewRefresherState<T>();
}

class _ListViewRefresherState<T> extends State<ListViewRefresher<T>> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  QLPageInfo? _pageInfo;
  final List<T> _list = [];

  @override
  void initState() {
    super.initState();
    _pageInfo = widget.initData.pageInfo;
    _list.addAll(widget.initData.data);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //https://github.com/peng8350/flutter_pulltorefresh/blob/master/README_CN.md
    //    // 全局配置子树下的SmartRefresher,下面列举几个特别重要的属性
    //      RefreshConfiguration(
    //          headerBuilder: () => WaterDropHeader(),        // 配置默认头部指示器,假如你每个页面的头部指示器都一样的话,你需要设置这个
    //          footerBuilder:  () => ClassicFooter(),        // 配置默认底部指示器
    //          headerTriggerDistance: 80.0,        // 头部触发刷新的越界距离
    //          springDescription:SpringDescription(stiffness: 170, damping: 16, mass: 1.9),         // 自定义回弹动画,三个属性值意义请查询flutter api
    //          maxOverScrollExtent :100, //头部最大可以拖动的范围,如果发生冲出视图范围区域,请设置这个属性
    //          maxUnderScrollExtent:0, // 底部最大可以拖动的范围
    //          enableScrollWhenRefreshCompleted: true, //这个属性不兼容PageView和TabBarView,如果你特别需要TabBarView左右滑动,你需要把它设置为true
    //          enableLoadingWhenFailed : true, //在加载失败的状态下,用户仍然可以通过手势上拉来触发加载更多
    //          hideFooterWhenNotFull: false, // Viewport不满一屏时,禁用上拉加载更多功能
    //          enableBallisticLoad: true, // 可以通过惯性滑动触发加载更多
    //         child: MaterialApp(
    //             ........
    //         )
    //     );
    return RefreshConfiguration(
      hideFooterWhenNotFull: true,
      child: SmartRefresher(
        enablePullDown: widget.onRefresh != null,
        enablePullUp: widget.onLoading != null,
        //header: const ClassicHeader(releaseText: '松开刷新'),
        header: const ClassicHeader(),
        footer: const ClassicFooter(),

        // footer: CustomFooter(
        //   builder: (context, mode) {
        //     Widget body;
        //     if (mode == LoadStatus.idle) {
        //       body = const Text("上拉加载");
        //     } else if (mode == LoadStatus.loading) {
        //       body = const CupertinoActivityIndicator();
        //     } else if (mode == LoadStatus.failed) {
        //       body = const Text("加载失败！点击重试！");
        //     } else if (mode == LoadStatus.canLoading) {
        //       body = const Text("松手,加载更多!");
        //     } else {
        //       body = const Text("没有更多数据了!");
        //     }
        //     return SizedBox(
        //       height: 55.0,
        //       child: Center(child: body),
        //     );
        //   },
        // ),
        // _refreshController.refreshCompleted();
        onRefresh: widget.onRefresh == null
            ? null
            : () {
                widget.onRefresh!.call().then((data) {
                  if (data.isEmpty) {
                    _refreshController.refreshCompleted();
                    // 没有数据，这里提示？
                    showInfoDialog('刷新完成，没有数据', context: context);
                  } else {
                    setState(() {
                      _pageInfo = data.pageInfo;
                      _list.clear();
                      _list.addAll(data.data);
                    });
                    _refreshController.refreshCompleted();
                    showInfoDialog('刷新完成', context: context);
                  }
                }).onError((e, s) {
                  _refreshController.refreshFailed();
                  showInfoDialog('刷新失败',
                      error: "$e",
                      context: context,
                      severity: InfoBarSeverity.error);
                }).whenComplete(() {});
              },
        // _refreshController.loadComplete();
        onLoading: widget.onLoading == null
            ? null
            : () {
                widget.onLoading!.call(_pageInfo).then((data) {
                  if (kDebugMode) {
                    print(
                        "=======================${_pageInfo?.hasNextPage}, ${_pageInfo?.endCursor}");
                  }
                  if (data.isNotEmpty) {
                    setState(() {
                      _pageInfo = data.pageInfo;
                      _list.addAll(data.data);
                    });
                    _refreshController.loadComplete();
                  } else {
                    _refreshController.loadNoData();
                  }
                }).onError((e, s) {
                  _refreshController.loadFailed();
                }).whenComplete(() {});
              },
        controller: _refreshController,
        child: ListView.separated(
          padding: widget.padding,
          itemCount: _list.length,
          itemBuilder: (context, index) =>
              widget.itemBuilder(context, _list[index], index),
          separatorBuilder: (context, index) =>
              widget.separator ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// 简化api使用的异步加载
class APIFutureBuilder<T> extends StatelessWidget {
  const APIFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.waitingWidget,
    this.errorWidget,
    this.noDataWidget,
    this.showStackTrace = false,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T value) builder;

  /// 在等待数据中自定义的显示，如果没有则显示默认的
  final Widget? waitingWidget;

  /// 数据发生错误时显示的，如果没有则显示默认的
  final Widget? errorWidget;

  /// 数据为null或者List, Map, QLList为空时显示的，如果没有则显示默认的
  final Widget? noDataWidget;

  /// 当发生错误的时候，是否显示堆栈信息，默认不显示
  final bool showStackTrace;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
          // 如果未完成，则显示加载进度指示
          if (snapshot.connectionState != ConnectionState.done) {
            return waitingWidget ?? const Center(child: ProgressRing());
          }
          // 有错误，显示错误
          if (snapshot.hasError) {
            return errorWidget ??
                Center(
                    child: Text(
                        "${snapshot.error}${showStackTrace ? '\n${snapshot.stackTrace}' : ''}",
                        style: TextStyle(fontSize: 18, color: Colors.red)));
          }
          // 没有数据时显示的
          if (!snapshot.hasData ||
              ((snapshot.data is List) && (snapshot.data as List).isEmpty) ||
              ((snapshot.data is Map) && (snapshot.data as Map).isEmpty) ||
              ((snapshot.data is QLList) &&
                  (snapshot.data as QLList).isEmpty)) {
            return noDataWidget ??
                const Center(
                    child: Text("没有数据", style: TextStyle(fontSize: 13)));
          }
          // 最后返回数据，不为null
          return builder(context, snapshot.data as T);
        });
  }
}

/// 改自 fluent_ui-4.8.7\lib\src\controls\inputs\split_button.dart
class DropdownPanelButton extends StatefulWidget {
  const DropdownPanelButton({
    super.key,
    this.leading,
    required this.title,
    required this.flyout,
    this.onOpen,
  });

  final Widget? leading;
  final Widget title;
  final Widget flyout;
  final VoidCallback? onOpen;

  @override
  State<DropdownPanelButton> createState() => _DropdownPanelButtonState();
}

class _DropdownPanelButtonState extends State<DropdownPanelButton> {
  late final FlyoutController flyoutController = FlyoutController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    flyoutController.dispose();
    super.dispose();
  }

  void showFlyout() async {
    if (flyoutController.isOpen) return;
    widget.onOpen?.call();
    setState(() {});
    await flyoutController.showFlyout(
      barrierColor: Colors.transparent,
      autoModeConfiguration: FlyoutAutoConfiguration(
          preferredMode: FlyoutPlacementMode.bottomLeft),
      builder: (context) => widget.flyout,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FocusBorder(
      focused: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: DecoratedBox(
          decoration: ShapeDecoration(
              shape: ButtonThemeData.shapeBorder(context, {ButtonStates.none})),
          child: IntrinsicHeight(
            child: HoverButton(
              onPressed: showFlyout,
              builder: (context, states) {
                return FlyoutTarget(
                  controller: flyoutController,
                  child: Container(
                    color: ButtonThemeData.buttonColor(
                      context,
                      flyoutController.isOpen
                          ? {ButtonStates.pressing}
                          : states,
                      transparentWhenNone: true,
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12.0), //, vertical: 8.0
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 50),
                      opacity: flyoutController.isOpen ? 0.5 : 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leading != null) widget.leading!,
                          widget.title,
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: ChevronDown(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
