import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as mt;
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:gh_app/widgets/highlight_plus.dart';
// import 'package:markdown/markdown.dart' as mk;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';

import 'dialogs.dart';

// extension MarkdownGeneratorExt on MarkdownGenerator {
//   /// 构建span
//   TextSpan buildTextSpan(String data,
//       {ValueCallback<List<Toc>>? onTocList, MarkdownConfig? config}) {
//     final mdConfig = config ?? MarkdownConfig.defaultConfig;
//     final document = mk.Document(
//       extensionSet: extensionSet ?? mk.ExtensionSet.gitHubFlavored,
//       encodeHtml: false,
//       inlineSyntaxes: inlineSyntaxList,
//       blockSyntaxes: blockSyntaxList,
//     );
//     final regExp = splitRegExp ?? WidgetVisitor.defaultSplitRegExp;
//     final List<String> lines = data.split(regExp);
//     final List<mk.Node> nodes = document.parseLines(lines);
//     // final List<Toc> tocList = [];
//     final visitor = WidgetVisitor(
//         config: mdConfig,
//         generators: generators,
//         textGenerator: textGenerator,
//         richTextBuilder: richTextBuilder,
//         splitRegExp: regExp,
//         onNodeAccepted: (node, index) {
//           onNodeAccepted?.call(node, index);
//           // if (node is HeadingNode && headingNodeFilter(node)) {
//           //   final listLength = tocList.length;
//           //   tocList.add(
//           //       Toc(node: node, widgetIndex: index, selfIndex: listLength));
//           // }
//         });
//     final spans = visitor.visit(nodes);
//     // onTocList?.call(tocList);
//     final List<InlineSpan> result = [];
//     for (var span in spans) {
//       //result.add(Padding(padding: linesMargin, child: richText));
//       result.add(span.build());
//     }
//     return TextSpan(children: result);
//   }
// }

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
    final config = (context.isDark
            ? MarkdownConfig.darkConfig
            : MarkdownConfig.defaultConfig)
        .copy(configs: [
      PreConfig(builder: (source, lang) {
        return HighlightViewPlus(
          source,
          language: "go",
          fileName: '',
        );
      }),
      LinkConfig(
          onTap: onTap ?? (link) => onDefaultLinkAction(context, link),
          style: const TextStyle(color: Color(0xff0969da)))
    ]);

    // 这个代码段选择不了？
    // final markdownGenerator = MarkdownGenerator();
    // final span = markdownGenerator.buildTextSpan(data, config: config);
    // return selectable
    //     ? SelectableText.rich(span, selectionHeightStyle: ui.BoxHeightStyle.max)
    //     : RichText(text: span);

    return mt.Material(
      textStyle: FluentTheme.of(context).typography.body,
      type: mt.MaterialType.transparency,
      child: MarkdownBlock(data: data, selectable: selectable, config: config),
    );
  }
}

class MarkdownBlockPlusDefaultAction extends StatelessWidget {
  const MarkdownBlockPlusDefaultAction(this.body, {super.key});

  final String? body;

  void _onDefaultLinkAction(BuildContext context, String link) {
    final uri = Uri.tryParse(link);
    if (uri != null) {
      // 没有host当对目录的
      if (uri.host.isEmpty && uri.path.isNotEmpty) {
        context.read<PathModel>().path = uri.path;
      } else {
        onDefaultLinkAction(context, link);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (body == null || body!.isEmpty) return const SizedBox.shrink();
    return MarkdownBlockPlus(
      data: body!,
      onTap: (link) => _onDefaultLinkAction(context, link),
    );
  }
}
