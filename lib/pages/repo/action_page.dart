import 'package:fluent_ui/fluent_ui.dart';
import 'package:github/github.dart';

class ActionPage extends StatelessWidget {
  const ActionPage(this.repo, {super.key});

  final Repository repo;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('还没做'),
    );
  }
}
