import 'package:fluent_ui/fluent_ui.dart';
import 'package:github/github.dart';

class WikiPage extends StatelessWidget {
  const WikiPage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('还没做'),
    );
  }
}
