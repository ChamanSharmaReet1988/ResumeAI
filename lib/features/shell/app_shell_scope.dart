import 'package:flutter/widgets.dart';

/// Lets routes above the tab shell switch tabs (e.g. Settings after Pro unlock).
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  static const int settingsTabIndex = 3;

  final ValueChanged<int> selectTab;

  static AppShellScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AppShellScope>();
  }

  static void goToSettings(BuildContext context) {
    maybeOf(context)?.selectTab(settingsTabIndex);
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) {
    return selectTab != oldWidget.selectTab;
  }
}
