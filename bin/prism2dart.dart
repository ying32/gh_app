import 'dart:io';

// ignore_for_file: depend_on_referenced_packages

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';

class HexColor {
  HexColor([this.text = "", this.value = 0]);
  String text;
  int value;
}

class HexColorVisitor extends Visitor {
  HexColorVisitor(this.color);

  final HexColor color;

  @override
  visitHexColorTerm(HexColorTerm node) {
    color.text = node.text;
    color.value = node.value as int;
    return super.visitHexColorTerm(node);
  }
}

class RuleSetVisitor extends Visitor {
  RuleSetVisitor();

  /// 收集类名和属性信息的
  final classNames = <String, Map<String, String>>{};

  @override
  visitRuleSet(RuleSet node) {
    // 保存属性的
    final props = <String, String>{};
    for (final declaration in node.declarationGroup.declarations) {
      if (declaration is Declaration) {
        // 提取属性名和属性值
        final propName = declaration.property;
        // if (propName == "cursor") {
        //   continue;
        // }
        var propValue = declaration.expression?.span?.text ?? '';
        if (propValue == "" || propValue == "#") {
          final color = HexColor();
          declaration.expression?.visit(HexColorVisitor(color));
          if (color.value > 0xFF000000) {
            propValue = color.value.toRadixString(16);
          } else {
            propValue = (0xFF000000 + color.value).toRadixString(16);
          }
        }
        //print("selector=$selectorText, name=$propName, value=$propValue");
        props[propName] = propValue;
      }
    }
    // print(props);

    if (node.selectorGroup != null) {
      for (final selector in node.selectorGroup!.selectors) {
        final names =
            selector.simpleSelectorSequences.map((e) => e.simpleSelector.name);
        // 可能有多个选择的组， token selector token id，所以从最后开始取值
        if (names.length >= 2 && names.elementAt(names.length - 2) == "token") {
          final className = names.last;
          // 已经保存了的
          if (classNames.containsKey(className)) {
            final pSrc = classNames[className];
            for (final key in props.keys) {
              final src = pSrc![key];
              final cur = props[key]!;
              // 没有值
              if (src == null) {
                pSrc[key] = cur;
              } else {
                // 不覆盖原有值
              }
            }
          } else {
            classNames[className] = props;
          }
          // print(
          //     "==========================selector == ${selector.simpleSelectorSequences.join(" ")}, props=$props");
        }
      }
    }
    return super.visitRuleSet(node);
  }
}

void main(List<String> arguments) {
  // 因为使用的那个库有几年没更新了，目前缺不少属性，所以不弄所有，只弄几个看得过去的主题吧
  // final directory = Directory(r'F:\StudyDiskJ\GitRepo\prism-themes\themes');
  // directory.listSync(recursive: false).forEach((FileSystemEntity entity) {
  //   if (entity is File) {
  //     if (p.extension(entity.path) != ".css") return;
  //     prismStyleFileToDart(entity.path);
  //   }
  // });
  const prismThemesRoot = r'F:\StudyDiskJ\GitRepo\prism-themes\themes';
  prismStyleFileToDart('A11y',
      darkCssFileName: "$prismThemesRoot\\prism-a11y-dark.css");
  prismStyleFileToDart('ColDark',
      lightCssFileName: "$prismThemesRoot\\prism-coldark-cold.css",
      darkCssFileName: "$prismThemesRoot\\prism-coldark-dark.css");
}

void prismStyleFileToDart(String className,
    {String lightCssFileName = '',
    String darkCssFileName = '',
    String? styleName}) {
  final dartClassName = "Prism${className}Style";

  final fileBuff = StringBuffer();
  fileBuff.writeln("//");
  fileBuff.writeln("// 使用 dart run gh_app:prism2dart 自动生成");
  fileBuff.writeln("//");
  fileBuff.writeln("import 'package:dart_prism/dart_prism.dart' as p;");
  fileBuff.writeln("import 'package:flutter/painting.dart';");
  fileBuff.writeln();
  fileBuff.writeln("/// Creates a $className style.");
  fileBuff.writeln("class $dartClassName extends p.PrismStyle<TextStyle> {");

  if (lightCssFileName.isNotEmpty) {
    writeConstructor(
        fileBuff, dartClassName, lightCssFileName, styleName ?? 'light');
  }
  if (darkCssFileName.isNotEmpty) {
    fileBuff.writeln();
    writeConstructor(
        fileBuff, dartClassName, darkCssFileName, styleName ?? 'dark');
  }

  fileBuff.writeln("}");

  // print(fileBuff.toString());
  final file =
      File("lib/utils/prism_themes/prism_${className.toLowerCase()}.dart")
        ..createSync(recursive: true);
  file.writeAsStringSync(fileBuff.toString());
}

void writeConstructor(StringBuffer fileBuff, String dartClassName,
    String inputFileName, String styleName) {
  final file = File(inputFileName);
  var stylesheet = css.parse(file.readAsStringSync(),
      options: const css.PreprocessorOptions(
          useColors: true,
          checked: true,
          warningsAsErrors: false,
          inputFile: 'memory'));
  final clsVisits = RuleSetVisitor()..visitTree(stylesheet);

  fileBuff.writeln("  const $dartClassName.$styleName({");

  const unsupportedProperties = [
    "variable",
    "delimiter",
    "key",
    "parameter",
    "color",
    "package",
    "combinator",
    "unit",
    "this",
    // "attribute",
    "value",
    // "class",
    "id",
    "rule",
    "title",
    "code",
    "content",
    "property-access",
    "url-link",
    "keyword-array",
    "pseudo-class",
    "pseudo-element",
    "keyword-this",
    "table-header",
  ];

  // 写数据
  for (var key in clsVisits.classNames.keys) {
    if (unsupportedProperties.contains(key)) {
      continue;
    }
    // 取值
    final value = clsVisits.classNames[key];
    // 重新调整为dart能用的key
    key = key
        .split("-")
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join();
    // "attribute",
    // "value",
    // "class",
    key = key[0].toLowerCase() + key.substring(1);

    // 重调整
    if (key == "class") {
      if (clsVisits.classNames['class-name'] == null) {
        key = "className";
      } else {
        continue;
      }
    } else if (key == "attribute") {
      if (clsVisits.classNames['atrule'] == null) {
        key = "atrule";
      } else {
        continue;
      }
    }
    if (value == null) continue;
    final color = value['color'] ?? '';
    var fontWeight = value['font-weight']?.toLowerCase() ?? '';
    // 关键字强制加粗
    if (key == 'keyword') {
      fontWeight = 'bold';
    }
    // 这个没有所以不管
    if (fontWeight == "inherit") {
      fontWeight = "";
    }
    final fontStyle = value['font-style']?.toLowerCase() ?? '';

    fileBuff.write("    super.$key = const TextStyle(");
    if (color.isNotEmpty) {
      fileBuff.write('color: Color(0x$color)');
      if (fontWeight.isNotEmpty) {
        fileBuff.write(", ");
      }
    }

    if (fontWeight.isNotEmpty) {
      if (fontWeight == "bold") {
        // bold太粗了，弄细点
        fontWeight = "w500";
      }
      fileBuff.write('fontWeight: FontWeight.$fontWeight');
      if (fontStyle.isNotEmpty) {
        fileBuff.write(", ");
      }
    }
    if (fontStyle.isNotEmpty) {
      fileBuff.write("fontStyle: FontStyle.$fontStyle");
    }

    fileBuff.writeln("),");
  }
  fileBuff.writeln("  });");
}
