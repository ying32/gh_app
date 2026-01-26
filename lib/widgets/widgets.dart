import 'package:flutter/material.dart';

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
      : color = Colors.orange,
        text = const Text('已归档 ',
            style: TextStyle(fontSize: 11, color: Colors.orange));

  const TagLabel.private({super.key, this.padding})
      : color = Colors.black,
        text = const Text('私有 ', style: TextStyle(fontSize: 11));

  const TagLabel.public({super.key, this.padding})
      : color = Colors.black,
        text = const Text('公开 ', style: TextStyle(fontSize: 11));

  factory TagLabel.other(String text,
          {Color color = Colors.black, EdgeInsetsGeometry? padding}) =>
      TagLabel(
          color: color,
          padding: padding,
          text: Text(text,
              style: const TextStyle(fontSize: 11, color: Colors.orange)));
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
    return Material(
      // color: Colors.transparent,
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: padding,
          child: text,
        ),
      ),
    );
  }
}
