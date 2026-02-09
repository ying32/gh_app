import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:gh_app/models/repo_model.dart';
import 'package:gh_app/widgets/highlight_plus.dart';
import 'package:gh_app/widgets/widgets.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _body = md.markdownToHtml(
      widget.body,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant MarkdownBlockPlus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body) {
      _convertMarkdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_body.isEmpty) return const SizedBox.shrink();
    return SelectionArea(
      child: HtmlWidget(
        _body,
        textStyle: const TextStyle(
            fontSize: 15, height: 1.8, textBaseline: TextBaseline.ideographic),
        customStylesBuilder: (el) {
          return el.localName == 'a' ? {'color': 'DodgerBlue'} : null;
        },
        customWidgetBuilder: (el) {
          // <pre><code class="language-json">
          //print("e=${el.localName},lang=${el.attributes['class']} ");
          if (el.localName == 'a') {
          } else if (el.localName == 'blockquote') {
            return InlineCustomWidget(
              child: Row(
                children: [
                  Container(
                      margin: const EdgeInsets.only(right: 10.0),
                      width: 2.0,
                      height: 24.0,
                      color: Colors.grey.withOpacity(0.5)),
                  Text(el.text),
                ],
              ),
            );
          } else if (el.localName == "hr") {
            return Container(height: 2, color: Colors.grey.withOpacity(0.5));
          } else if (el.localName == 'code') {
            if (el.text.isEmpty) return null;
            var lang = el.attributes['class'];
            if (lang?.startsWith("language-") ?? false) {
              lang = lang!.substring(9);
            }
            // 没有指定语法时，直接只突出显示
            if (lang == null || lang.isEmpty) {
              return InlineCustomWidget(
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      el.text,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    )),
              );
            }
            // 代码块
            //print("e=${el.localName},lang=$lang, text=${el.text}");
            return InlineCustomWidget(
              child: Card(
                  child: HighlightViewPlus(el.text,
                      fileName: '', language: lang, selectable: false)),
            );
          } else if (el.localName == "img" && el.attributes['src'] != null) {
            //return SizedBox();
            // 这里替换 img
            //print("=============img=${el.attributes}");
            final imgUrl = el.attributes['src'];
            return InlineCustomWidget(
              child: GestureDetector(
                onDoubleTap: () => showImageDialog(context, imgUrl),
                child: CachedNetworkImageEx(
                  imgUrl!,
                  width: double.tryParse(el.attributes['width'] ?? ''),
                  height: double.tryParse(el.attributes['height'] ?? ''),
                  alt: el.attributes['alt'],
                  //alignment: Alignment.centerLeft,
                ),
              ),
            );
          }
          return null;
        },
        onTapUrl: (link) {
          try {
            final uri = Uri.tryParse(link);
            if (uri != null) {
              //print("uri=$uri");
              switch (uri.scheme.trim().toLowerCase()) {
                case "" || "http" || "https":
                  // 没有host当对目录的
                  if (uri.host.isEmpty && uri.path.isNotEmpty) {
                    context.read<RepoModel>().path = uri.path;
                  } else {
                    onDefaultLinkAction(context, link);
                  }
                //case "mailto" || "file" || "ft"
                default:
                  launchUrl(uri);
                  break;
              }
              //print("uri scheme=${uri.scheme}, host=${uri.host}");
            }
          } catch (e) {
            //onDefaultLinkAction(context, link);
          }
          // print("click=$link");
          return true;
        },
      ),
    );
  }
}
