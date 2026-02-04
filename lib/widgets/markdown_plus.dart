import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/widgets/highlight_plus.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';

import 'dialogs.dart';

class MarkdownBlockPlus extends StatefulWidget {
  const MarkdownBlockPlus(this.body, {super.key});

  final String body;

  @override
  State<MarkdownBlockPlus> createState() => _MarkdownBlockPlusState();
}

class _MarkdownBlockPlusState extends State<MarkdownBlockPlus> {
  String _body = '';

  @override
  void initState() {
    super.initState();
    _convertMarkdown();
  }

  void _convertMarkdown() async {
    // https://pub.dev/packages/markdown
    //TODO： 这里要优化下
    _body = md.markdownToHtml(
      widget.body,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    if (mounted) {
      setState(() {});
    }
    //print("body=$_body");
  }

  @override
  Widget build(BuildContext context) {
    if (_body.isEmpty) return const SizedBox.shrink();
    return SelectionArea(
      child: HtmlWidget(
        _body,
        customStylesBuilder: (el) {
          return el.localName == 'a' ? {'color': 'DodgerBlue'} : null;
        },
        customWidgetBuilder: (el) {
          // <pre><code class="language-json">
          //print("e=${el.localName},lang=${el.attributes['class']} ");
          if (el.localName == 'code') {
            var lang = el.attributes['class'];
            if (lang?.startsWith("language-") ?? false) {
              lang = lang!.substring(9);
            }
            //TODO: 这里要突出显示下
            if (lang == null || lang.isEmpty) {
              return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(el.text ?? ''));
            }
            // 代码块
            //print("e=${el.localName},lang=$lang, text=${el.text}");
            return Card(
                child:
                    HighlightViewPlus(el.text, fileName: '', language: lang));
          } else if (el.localName == "img" && el.attributes['src'] != null) {
            // 这里替换 img
            //print("=============img=${el.attributes}");
            return CachedNetworkImageEx(
              el.attributes['src']!,
              width: double.tryParse(el.attributes['width'] ?? ''),
              height: double.tryParse(el.attributes['height'] ?? ''),
              tooltip: el.attributes['alt'],
              //alignment: Alignment.centerLeft,
            );
          }
          return null;
        },
        onTapUrl: (link) {
          try {
            final uri = Uri.tryParse(link);
            if (uri != null) {
              // 没有host当对目录的
              if (uri.host.isEmpty && uri.path.isNotEmpty) {
                context.read<PathModel>().path = uri.path;
              } else {
                onDefaultLinkAction(context, link);
              }
            }
          } catch (e) {
            onDefaultLinkAction(context, link);
          }
          //print("click=$link");
          return true;
        },
      ),
    );
  }
}
