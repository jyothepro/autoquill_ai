import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

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

    await _rebuildContextMenu();

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
    final String? key = menuItem.key;
    if (key == null) return;

    if (key == 'open_window') {
      _openMainWindow();
      return;
    }

    if (key == 'quit_app') {
      _quitApp();
      return;
    }
  }

  Future<void> _rebuildContextMenu() async {
    final Menu menu = Menu(items: [
      MenuItem(key: 'open_window', label: 'Open AutoQuill'),
      MenuItem.separator(),
      MenuItem(key: 'quit_app', label: 'Quit AutoQuill'),
    ]);

    await trayManager.setContextMenu(menu);
  }

  Future<void> _openMainWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  void _quitApp() {
    exit(0);
  }
}
