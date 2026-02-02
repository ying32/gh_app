import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/config.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:gh_app/widgets/dialogs.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _releaseFileAssetsMirrorUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _releaseFileAssetsMirrorUrlController.text =
        AppConfig.instance.releaseFileAssetsMirrorUrl;
  }

  @override
  void dispose() {
    _releaseFileAssetsMirrorUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final appTheme = context.watch<AppTheme>();
    const spacer = SizedBox(height: 10.0);
    const biggerSpacer = SizedBox(height: 40.0);

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('设置')),
      children: [
        Text('主题模式', style: FluentTheme.of(context).typography.subtitle),
        spacer,
        ...List.generate(ThemeMode.values.length, (index) {
          final mode = ThemeMode.values[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: RadioButton(
              checked: appTheme.mode == mode,
              onChanged: (value) {
                if (value) {
                  appTheme.mode = mode;
                }
              },
              content: Text(themeModeStrings[mode.index]),
            ),
          );
        }),
        biggerSpacer,
        Text('Release FileAssets 下载链接镜像',
            style: FluentTheme.of(context).typography.subtitle),
        spacer,
        TextBox(
          controller: _releaseFileAssetsMirrorUrlController,
          onSubmitted: (value) {
            //print("onSubmitted.value=$value");
            var uri = Uri.tryParse(value);
            if (uri != null && uri.scheme.isNotEmpty && uri.path.isNotEmpty) {
              AppConfig.instance.releaseFileAssetsMirrorUrl = value.trim();
            } else {
              showInfoDialog('请输入一个合法的URL',
                  context: context, severity: InfoBarSeverity.error);
            }
          },
        ),
      ],
    );
  }
}
