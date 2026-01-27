import 'package:flutter/material.dart';
import 'package:flutter_prism/flutter_prism.dart';
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:path/path.dart' as path_lib;

/// 修改自：flutter_highlight-0.7.0\lib\flutter_highlight.dart

class HighlightViewPlus extends StatelessWidget {
  HighlightViewPlus(
    String input, {
    super.key,
    required this.fileName,
    this.isDiff = false,
    int tabSize = 8, // TODO: https://github.com/flutter/flutter/issues/50087
  }) : source = input.replaceAll('\t', ' ' * tabSize);

  final String source;
  final String fileName;
  final bool isDiff;

  // 因为有些不能根据扩展名识别，所以这里维护一个
  static final _otherHighlights = {
    "txt": {"CMakeLists.txt": "cmake"},
    "iml": "xml",
    "manifest": "xml",
    "rc": "c",
    "arb": "json",
    "firebaserc": "json",
    "fmx": "delphi",
    "lfm": "delphi",
    "dfm": "delphi",
    "dpr": "delphi",
    "lpr": "delphi",
    "": {"Podfile": "ruby"}
  };

  static final _xmlStartPattern = RegExp(r'\<\?xml|\<.+?xmlns\=\"');

  String _getLang(String data) {
    var ext = path_lib.extension(fileName).toLowerCase();
    if (ext.startsWith(".")) ext = ext.substring(1);

    // 这个只是临时的，想要好的，还得做内容识别
    final highlight = _otherHighlights[ext];

    if (highlight != null) {
      // 先查文件名
      final language = (highlight is Map)
          ? highlight[fileName] ?? highlight[ext]
          : highlight;
      if (language != null && language.isNotEmpty) {
        ext = language;
      }
    }
    if (highlight == null) {
      if (data.startsWith(_xmlStartPattern)) {
        ext = "xml";
      }
    }
    ext = switch (ext) {
      "delphi" || "inc" => "pascal",
      "bat" || "cmd" => "batch",
      _ => ext,
    };

    return ext;
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        // fontFamily: 'Courier New',
        fontFamily: 'monospace',
        fontSize: 16.0,
        height: 1.5);
    // 这里要优化下，先要查找语言有没有支持，有的话才继续，没有就不继续了
    final prism = Prism(
        style: !context.isDark ? const PrismStyle() : const PrismStyle.dark());
    try {
      final textSpans = prism.render(source, _getLang(source));
      return SelectableText.rich(TextSpan(
        style: style,
        children: textSpans,
      ));
    } catch (e) {
      return SelectableText(source, style: style);
    }
  }
}
