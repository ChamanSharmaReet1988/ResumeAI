import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/view_models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settings, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Appearance',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<ThemeMode>(
                          value: settings.themeMode,
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Theme.of(context).cardColor,
                          iconEnabledColor: Theme.of(context).colorScheme.primary,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              settings.updateThemeMode(value);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
