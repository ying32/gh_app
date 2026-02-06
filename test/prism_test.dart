import 'dart:io';

// ignore_for_file: avoid_print

import 'package:dart_prism/dart_prism.dart' as dp;

class StyleNode {
  const StyleNode({required this.text, this.style});

  final String text;
  final String? style;
}

void main() {
  final file = File('lib/app.dart');
  final prism = dp.Prism();

  final nodes = prism.parse(file.readAsStringSync(), 'dart');

  //行
  final List<List<StyleNode>> lines = _parseNodes(nodes, []);

  print("newNodes.length=${lines.length}");
  for (final line in lines) {
    // print("line=${line.map((e) {
    //   // return e.textContent;
    //   if (e is p.Text) {
    //     return e.text;
    //   } else if (e is p.Token) {
    //     return e.text;
    //   }
    //   // return '';
    // }).join()}");
  }
}

List<List<StyleNode>> _parseNodes(List<dp.Node> nodes, List<StyleNode> line) {
  final List<List<StyleNode>> lines = [];
  for (final node in nodes) {
    if (node is dp.Text) {
      // 统一换行符
      final text = node.text.replaceAll('\r', '');
      // // 判断结束位置是否为换行符
      if (text.contains("\n")) {
        for (final c in text.codeUnits) {
          if (c == 10) {
            lines.add(line);
            line = [];
          } else {
            line.add(StyleNode(text: String.fromCharCode(c)));
          }
        }
      } else {
        line.add(StyleNode(text: node.text));
      }

      // print(
      //     "node.text=`${text.replaceAll("\r", '\\r').replaceAll('\n', '\\n')}`, length=${text.length}");
    } else {
      print('node.type=`${node.type}`');
      // final style = _styles.get('token') ?? const TextStyle();
      // style = style!.merge(_styles.get(node.type));

      for (final alias in node.aliases) {
        //style = style!.merge(_styles.get(alias));
        //print("alias=`$alias`");
      }
      if (node is dp.Token) {
        //print("token=${node.text}");
        //text = node.text;
        //print('token=`${node.text}`');
        // line.add(node);
        line.add(StyleNode(text: node.text, style: node.type));
      } else if (node is dp.Container) {
        //print("children=${node.length}");
        // children = _parseNodes(node.children);
        lines.addAll(_parseNodes(node.children, line));
      } else {
        print('未知类型');
        //  throw ArgumentError('Unknown node type');
      }
    }
  }
  return lines;
}
