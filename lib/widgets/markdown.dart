import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/link.dart';
import 'package:markdown_widget/widget/markdown_block.dart';

class MarkdownBlockPlus extends StatelessWidget {
  const MarkdownBlockPlus({
    super.key,
    required this.data,
    this.selectable = true,
    this.onTap,
  });

  final String data;
  final bool selectable;
  final ValueCallback<String>? onTap;

  @override
  Widget build(BuildContext context) {
    // 这个编译不了，需要更新的，那就暂时不试了哈
    // return MarkdownViewer(
    //   data,
    //   enableTaskList: true,
    //   enableSuperscript: false,
    //   enableSubscript: false,
    //   enableFootnote: false,
    //   enableImageSize: false,
    //   enableKbd: false,
    //   syntaxExtensions: const [],
    //   elementBuilders: const [],
    // );

    final config = (context.isDark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig);
    return m.Material(
      type: m.MaterialType.transparency,
      child: MarkdownBlock(
        data: data,
        selectable: selectable,
        config: onTap != null
            ? config.copy(configs: [
                LinkConfig(
                    onTap: onTap,
                    style: const TextStyle(color: Color(0xff0969da)))
              ])
            : config,
      ),
    );
  }
}
