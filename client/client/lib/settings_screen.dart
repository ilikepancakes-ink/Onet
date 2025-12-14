import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'models.dart';
import 'l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final scale = isMobile ? 1.5 : 1.0;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings, style: TextStyle(fontSize: 20 * scale))),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return ListView(
            children: [
              SizedBox(
                height: 60 * scale,
                child: ListTile(
                  title: Text(l10n.theme, style: TextStyle(fontSize: 16 * scale)),
                  subtitle: Text(appProvider.settings.themeMode == ThemeMode.light
                      ? l10n.light
                      : appProvider.settings.themeMode == ThemeMode.dark
                          ? l10n.dark
                          : l10n.system, style: TextStyle(fontSize: 14 * scale)),
                  trailing: DropdownButton<ThemeMode>(
                    value: appProvider.settings.themeMode,
                    items: [
                      DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark, style: TextStyle(fontSize: 14 * scale))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        appProvider.updateSettings(AppSettings(
                          themeMode: value,
                          language: appProvider.settings.language,
                        ));
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 60 * scale,
                child: ListTile(
                  title: Text(l10n.language, style: TextStyle(fontSize: 16 * scale)),
                  subtitle: Text(_getLanguageName(appProvider.settings.language, l10n), style: TextStyle(fontSize: 14 * scale)),
                  trailing: DropdownButton<String>(
                    value: appProvider.settings.language,
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(l10n.english, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: 'es', child: Text(l10n.spanish, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: 'fr', child: Text(l10n.french, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: 'nl', child: Text(l10n.dutch, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: 'de', child: Text(l10n.german, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: 'ru', child: Text(l10n.russian, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: 'sv', child: Text(l10n.swedish, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: 'ko', child: Text(l10n.korean, style: TextStyle(fontSize: 14 * scale))),
                      DropdownMenuItem(value: 'sk', child: Text(l10n.slovakian, style: TextStyle(fontSize: 14 * scale))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        appProvider.updateSettings(AppSettings(
                          themeMode: appProvider.settings.themeMode,
                          language: value,
                        ));
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getLanguageName(String code, AppLocalizations l10n) {
    switch (code) {
      case 'en': return l10n.english;
      case 'es': return l10n.spanish;
      case 'fr': return l10n.french;
      case 'nl': return l10n.dutch;
      case 'de': return l10n.german;
      case 'ru': return l10n.russian;
      case 'sv': return l10n.swedish;
      case 'ko': return l10n.korean;
      case 'sk': return l10n.slovakian;
      default: return code;
    }
  }
}
