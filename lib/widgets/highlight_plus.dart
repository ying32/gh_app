import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_prism/flutter_prism.dart';
import 'package:gh_app/utils/build_context_helper.dart';
import 'package:gh_app/utils/prism_themes/prism_coldark_cold.dart';
import 'package:gh_app/utils/prism_themes/prism_coldark_dark.dart';
import 'package:path/path.dart' as path_lib;

/// 修改自：flutter_highlight-0.7.0\lib\flutter_highlight.dart

class HighlightViewPlus extends StatelessWidget {
  HighlightViewPlus(
    String input, {
    super.key,
    required this.fileName,
    this.isDiff = false,
    this.language,
    int tabSize = 8, // TODO: https://github.com/flutter/flutter/issues/50087
  }) : source = input.replaceAll('\t', ' ' * tabSize);

  final String source;
  final String fileName;
  final bool isDiff;
  final String? language;

  // 因为有些不能根据扩展名识别，所以这里维护一个
  static final _extHighlights = {
    "xml": {"iml", "manifest", "dproj"},
    "c": {"rc"},
    "json": {"arb", "firebaserc"},
    "pascal": {
      "fmx",
      "lfm",
      "dfm",
      "dpr",
      "lpr",
      "inc",
      "dpk",
      "lpk",
      "pas",
      "pp"
    },
    "batch": {"bat", "cmd"},
    "ini": {"dof", "desktop"},
    "rust": {"rs"},
    "cpp": {"h"},
  };

  /// 这个是查询纯文件名的
  static final _fileHighlights = {
    "cmake": {"CMakeLists.txt"},
    "ruby": {"Podfile"},
    "makefile": {"Makefile"},
  };

  //当 language不为null时，则查询下这个的，
  static final _langAlias = {
    "golang": "go",
  };

  /// 这个正则还要重新弄下，这个识别不太好
  static final _xmlStartPattern = RegExp(r'\<\?xml|\<.+?xmlns\=\"');

  /// 查询语法高亮
  String get _getLang {
    if (language != null) {
      return _langAlias[language] ?? language!;
    }

    // 根据文件名查询语法
    final shortName = path_lib.basename(fileName);

    // 匹配文件全名
    for (final key in _fileHighlights.keys) {
      if (_fileHighlights[key]?.contains(shortName) ?? false) {
        return key;
      }
    }
    // 根据扩展名查询
    var ext = path_lib.extension(shortName).toLowerCase();
    // 如果没有提取到扩展，但是shortName不为空，则说明是纯扩展名的文件
    if (ext.isEmpty && shortName.startsWith(".")) {
      ext = shortName;
    }
    if (ext.startsWith(".")) ext = ext.substring(1);
    // 这个只是临时的，想要好的，还得做内容识别
    // 匹配扩展名
    for (final key in _extHighlights.keys) {
      if (_extHighlights[key]?.contains(ext) ?? false) {
        return key;
      }
    }
    // 根据文件内容判断，这里判断为xml格式的
    if (source.startsWith(_xmlStartPattern)) {
      return "xml";
    }
    // 没有找到自定义的
    return ext;
  }

  // static Widget _defaultContextMenuBuilder(
  //     BuildContext context, EditableTextState editableTextState) {
  //   return FluentTextSelectionToolbar.editableText(
  //     editableTextState: editableTextState
  //       ..contextMenuButtonItems
  //           .add(ContextMenuButtonItem(label: 'ff', onPressed: () {})),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        // fontFamily: 'Courier New',
        fontFamily: 'monospace',
        fontSize: 16.0,
        height: 1.5);
    // 这里要优化下，先要查找语言有没有支持，有的话才继续，没有就不继续了
    final lang = _getLang;
    if (kDebugMode) {
      print("highlight lang=$lang");
    }
    if (lang.isEmpty) {
      return SelectableText(
        source,
        style: style,
        selectionHeightStyle: ui.BoxHeightStyle.max,
      );
    }
    final prism = Prism(
        style: context.isDark
            ? const PrismColdarkDarkStyle()
            : const PrismColdarkColdStyle());
    try {
      final textSpans = prism.render(source, lang);
      return SelectableText.rich(
        TextSpan(style: style, children: textSpans),
        // contextMenuBuilder: _defaultContextMenuBuilder,
        selectionHeightStyle: ui.BoxHeightStyle.max,
      );
    } catch (e) {
      // 如果没有查找到语法他会报一个错误，所以这里直接使用默认的
      return SelectableText(
        source,
        style: style,
        selectionHeightStyle: ui.BoxHeightStyle.max,
      );
    }
  }
}
