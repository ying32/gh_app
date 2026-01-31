import 'dart:io';

// ignore_for_file: depend_on_referenced_packages

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:path/path.dart' as p;

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
          propValue = color.text;
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
        if (names.firstOrNull == "token" && names.length >= 2) {
          final className = names.elementAt(1);
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
          //     "============================ ${selector.simpleSelectorSequences.join(" ")}");
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
  prismStyleFileToDart(
      r"F:\StudyDiskJ\GitRepo\prism-themes\themes\prism-a11y-dark.css");
  prismStyleFileToDart(
      r"F:\StudyDiskJ\GitRepo\prism-themes\themes\prism-coldark-cold.css");
  prismStyleFileToDart(
      r"F:\StudyDiskJ\GitRepo\prism-themes\themes\prism-coldark-dark.css");
}

void prismStyleFileToDart(String filename) {
  final file = File(filename);
  var stylesheet = css.parse(file.readAsStringSync(),
      options: const css.PreprocessorOptions(
          useColors: true,
          checked: true,
          warningsAsErrors: false,
          inputFile: 'memory'));
  final clsVisits = RuleSetVisitor()..visitTree(stylesheet);
  writeToFile(
      p
          .withoutExtension(p.basename(file.path))
          .replaceAll(RegExp(r"-|\."), "_"),
      clsVisits);
}

void writeToFile(String fileName, RuleSetVisitor visitor) {
  final className = fileName
      .split("_")
      .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
      .join();

  final dartClassName = "${className}Style";

  final fileBuff = StringBuffer();
  fileBuff.writeln("//");
  fileBuff.writeln("// 使用 dart run gh_app:prism2dart 自动生成");
  fileBuff.writeln("//");
  fileBuff.writeln("import 'package:dart_prism/dart_prism.dart' as p;");
  fileBuff.writeln("import 'package:flutter/painting.dart';");
  fileBuff.writeln();
  fileBuff.writeln("/// Creates a $className style.");
  fileBuff.writeln("class $dartClassName extends p.PrismStyle<TextStyle> {");
  fileBuff.writeln("  const $dartClassName({");

  const unsupportedProperties = [
    "variable",
    "delimiter",
    "key",
    "parameter",
    "color",
    "package",
    "combinator",
    "unit",
    "this"
  ];

  // 写数据
  for (var key in visitor.classNames.keys) {
    if (unsupportedProperties.contains(key)) {
      continue;
    }

    key = key
        .split("-")
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join();
    key = key[0].toLowerCase() + key.substring(1);
    final value = visitor.classNames[key];
    if (value == null) continue;
    final color = value['color'] ?? '';
    var fontWeight = value['font-weight']?.toLowerCase() ?? '';
    // 这个没有所以不管
    if (fontWeight == "inherit") {
      fontWeight = "";
    }
    final fontStyle = value['font-style']?.toLowerCase() ?? '';

    fileBuff.write("    super.$key = const TextStyle(");
    if (color.isNotEmpty) {
      fileBuff.write('color: Color(0xff$color)');
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
  fileBuff.writeln("}");

  // print(fileBuff.toString());
  final file = File("lib/utils/prism_themes/$fileName.dart")
    ..createSync(recursive: true);
  file.writeAsStringSync(fileBuff.toString());
}
