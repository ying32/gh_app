import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:gh_app/utils/fonts/remix_icon.dart';
import 'package:url_launcher/link.dart';

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
  });

  final IconData icon;
  final Widget text;
  final double iconSize;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    Widget widget = Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: iconSize, color: iconColor),
      SizedBox(width: spacing),
      text,
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
  });

  final Color color;
  final Widget text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      decoration: BoxDecoration(
        // 背景
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: text,
    );
  }

  const TagLabel.archived({super.key, this.padding})
      : color = m.Colors.orange,
        text = const Text('已归档 ',
            style: TextStyle(fontSize: 11, color: m.Colors.orange));

  const TagLabel.private({super.key, this.padding})
      : color = m.Colors.black,
        text = const Text('私有 ', style: TextStyle(fontSize: 11));

  const TagLabel.public({super.key, this.padding})
      : color = m.Colors.black,
        text = const Text('公开 ', style: TextStyle(fontSize: 11));

  factory TagLabel.other(String text,
          {Color color = m.Colors.black, EdgeInsetsGeometry? padding}) =>
      TagLabel(
          color: color,
          padding: padding,
          text: Text(text, style: TextStyle(fontSize: 11, color: color)));
}

/// 链接跳转的
class LinkStyleButton extends StatelessWidget {
  const LinkStyleButton({
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

/// Github的图标
class GitHubIcon extends StatelessWidget {
  const GitHubIcon({
    super.key,
    this.size = 16,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(Remix.github_fill, size: size, color: color);
}

/// 一个icon样式的带跳转本地open的
class LinkAction extends StatelessWidget {
  const LinkAction({
    super.key,
    required this.icon,
    required this.link,
  });

  final Icon icon;
  final String link;

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse(link),
      builder: (context, followLink) => Semantics(
        link: true,
        child: Tooltip(
          message: link,
          child: IconButton(
            icon: icon,
            onPressed: () => followLink?.call(),
          ),
        ),
      ),
    );
  }
}

/// 初始加载数据
class WrapInit extends StatefulWidget {
  const WrapInit({
    super.key,
    required this.child,
    required this.onInit,
  });

  final Widget child;
  final VoidCallback onInit;

  @override
  State<WrapInit> createState() => _WrapInitState();
}

class _WrapInitState extends State<WrapInit> {
  @override
  void initState() {
    super.initState();
    widget.onInit.call();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
