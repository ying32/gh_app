import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:gh_app/utils/github/graphql.dart';
import 'package:gh_app/widgets/default_icons.dart';
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
          double? radius}) =>
      TagLabel(
          color: color,
          padding: padding,
          radius: radius,
          text: Text(text, style: TextStyle(fontSize: 11, color: color)));
}

/// 链接跳转的？？？？
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
  });

  final Widget text;
  final EdgeInsetsGeometry padding;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return m.Material(
      // color: Colors.transparent,
      type: m.MaterialType.transparency,
      child: m.InkWell(
        onTap: onPressed,
        child: Padding(
          padding: padding,
          child: text,
        ),
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
class PaginationBar extends StatefulWidget {
  const PaginationBar({super.key});

  @override
  State<PaginationBar> createState() => _PaginationBarState();
}

class _PaginationBarState extends State<PaginationBar> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
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
