import 'dart:io';

//ignore_for_file:avoid_print

import 'package:markdown/markdown.dart';

void main() {
  final file = File('test\\README.zh-CN.md');
  final body = markdownToHtml(file.readAsStringSync());
  print(body);
}
