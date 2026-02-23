import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_prism/flutter_prism.dart';
import 'package:gh_app/utils/helpers.dart';
import 'package:gh_app/utils/prism_themes/prism_coldark.dart';
import 'package:path/path.dart' as path_lib;

// 因为有些不能根据扩展名识别，所以这里维护一个
const _extHighlights = {
  "xml": {"iml", "manifest", "dproj"},
  "c": {"rc"},
  "json": {"arb", "firebaserc", "jsonc"},
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
  "powershell": {"ps1"},
};

/// 这个是查询纯文件名的
const _fileHighlights = {
  "cmake": {"CMakeLists.txt"},
  "ruby": {"Podfile"},
  "makefile": {"Makefile"},
};

//当 language不为null时，则查询下这个的，
const _langAlias = {
  "golang": "go",
  "delphi": "pascal",
};

/// 这个正则还要重新弄下，这个识别不太好
final _xmlStartPattern = RegExp(r'\<\?xml|\<.+?xmlns\=\"');

/// 默认代码样式
const defaultCodeStyle = TextStyle(
  // fontFamily: 'Courier New',
  fontFamily: 'monospace',
  fontSize: 16.0,
  height: 1.5,
);

/// 尝试解析语言枨，从文件名，给定语言或者源码
String tryGetLanguage(String fileName, {String? language, String source = ''}) {
  if (language != null) {
    return _langAlias[language.toLowerCase()] ?? language.toLowerCase();
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

// TODO: 这个还要优化下，对于大点的文件显示就有问题
class HighlightViewPlus extends StatefulWidget {
  HighlightViewPlus(
    String input, {
    super.key,
    required this.fileName,
    this.language,
    this.byteSize = 0,
    int tabSize = 8, // TODO: https://github.com/flutter/flutter/issues/50087
    this.selectable = true,
  }) : source = input.replaceAll('\t', ' ' * tabSize);

  final String source;
  final String fileName;
  final String? language;
  final int byteSize;
  final bool selectable;

  @override
  State<HighlightViewPlus> createState() => _HighlightViewPlusState();
}

class _HighlightViewPlusState extends State<HighlightViewPlus> {
  bool get _canHighlight => widget.byteSize < k1KB * 200;

  /// 查询语法高亮
  String get _getLang {
    return tryGetLanguage(widget.fileName,
        language: widget.language, source: widget.source);
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildSpan();
    });
  }

  @override
  void didUpdateWidget(covariant HighlightViewPlus oldWidget) {
    super.didUpdateWidget(oldWidget);
    //TODO: dark模式没弄
    if (oldWidget.source != widget.source) {
      _buildSpan();
    }
  }

  List<TextSpan> _spans = [];
  String _lang = '';

  void _buildSpan() async {
    _lang = _getLang;
    if (_lang.isEmpty) return;
    if (!_canHighlight) return;
    final prism = Prism(
        style: context.isDark
            ? const PrismColDarkStyle.dark()
            : const PrismColDarkStyle.light());
    try {
      _spans = prism.render(widget.source, _lang);
      if (_spans.isNotEmpty && mounted) {
        setState(() {});
      }
    } catch (e) {} //ignore:empty_catches
  }

  Widget _defaultSelectableText() {
    return RepaintBoundary(
      child: widget.selectable
          ? SelectableText(
              widget.source,
              style: defaultCodeStyle,
              selectionHeightStyle: ui.BoxHeightStyle.max,
            )
          : Text(widget.source, style: defaultCodeStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      //print("highlight lang=$lang");
    }
    if (_lang.isEmpty || !_canHighlight) {
      return _defaultSelectableText();
    }
    try {
      return RepaintBoundary(
        child: widget.selectable
            ? SelectableText.rich(
                TextSpan(style: defaultCodeStyle, children: _spans),
                selectionHeightStyle: ui.BoxHeightStyle.max,
              )
            : Text.rich(TextSpan(style: defaultCodeStyle, children: _spans)),
      );
    } catch (e) {
      // 如果没有查找到语法他会报一个错误，所以这里直接使用默认的
      return _defaultSelectableText();
    }
  }
}
