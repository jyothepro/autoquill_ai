import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) return;

    trayManager.addListener(this);

    // Use existing app icon asset for the tray. Consider a monochrome template icon later.
    final String iconPath = Platform.isWindows
        ? 'assets/icons/with_bg/autoquill_centered_1024_rounded.ico'
        : 'assets/icons/with_bg/autoquill_centered_1024_rounded.png';

    try {
      await trayManager.setIcon(iconPath);
    } catch (_) {
      // Ignore icon load failures for now; not critical to app operation
    }

    final Menu menu = Menu(items: [
      MenuItem(key: 'open_window', label: 'Open AutoQuill'),
      MenuItem.separator(),
      MenuItem(key: 'microphone', label: 'Microphone'),
      MenuItem(key: 'language', label: 'Language'),
      MenuItem.separator(),
      MenuItem(key: 'quit_app', label: 'Quit AutoQuill'),
    ]);

    await trayManager.setContextMenu(menu);

    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    trayManager.removeListener(this);
    _initialized = false;
  }

  @override
  void onTrayIconMouseDown() {
    // Show the context menu when the tray icon is clicked
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    // UI only for now; no functionality implemented as requested.
    // Leave this handler in place for future wiring.
  }
}
