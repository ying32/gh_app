import 'package:fluent_ui/fluent_ui.dart';
import 'package:gh_app/theme.dart';
import 'package:gh_app/utils/consts.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final appTheme = context.watch<AppTheme>();
    const spacer = SizedBox(height: 10.0);
    // const biggerSpacer = SizedBox(height: 40.0);
    //
    // const supportedLocales = FluentLocalizations.supportedLocales;
    // final currentLocale =
    //     appTheme.locale ?? Localizations.maybeLocaleOf(context);
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
      ],
    );
  }
}
