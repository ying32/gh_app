import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/utils/utils.dart';
import 'package:github/github.dart';

/// issues的标签
class IssueLabels extends StatelessWidget {
  const IssueLabels({super.key, required this.labels});

  final List<IssueLabel> labels;

  static Color _getColor(Color color) {
    if ((0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue) /
            255.0 <
        0.66) return Colors.white;
    return Colors.black;
  }

  Widget _build(IssueLabel label) {
    final color = hexColorTo(label.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label.name,
        style: TextStyle(color: _getColor(color), fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 5,
        runSpacing: 5,
        children: labels.map((e) => _build(e)).toList(),
      );
}
