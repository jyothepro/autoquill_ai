import 'package:hive_flutter/hive_flutter.dart';
import '../permissions/permission_service.dart';

class AppStorage {
  static const String _settingsBoxName = 'settings';
  static const String _groqKey = 'groq_api_key';
  static const String _isOnboardingCompletedKey = 'is_onboarding_completed';

  // Permission storage keys
  static const String _microphonePermissionKey = 'microphone_permission_status';
  static const String _accessibilityPermissionKey =
      'accessibility_permission_status';
  static const String _screenRecordingPermissionKey =
      'screen_recording_permission_status';

  static late Box<dynamic> _settingsBox;

  static Box<dynamic> get settingsBox => _settingsBox;

  static Future<void> init() async {
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  static Future<void> saveApiKey(String apiKey) async {
    await _settingsBox.put(_groqKey, apiKey);
  }

  static Future<String?> getApiKey() async {
    if (!_settingsBox.containsKey(_groqKey)) return null;
    final value = _settingsBox.get(_groqKey) as String?;
    return value?.isEmpty == true ? null : value;
  }

  static Future<void> deleteApiKey() async {
    await _settingsBox.delete(_groqKey);
  }

  static Future<void> saveHotkey(
      String setting, Map<String, dynamic> hotkeyData) async {
    await _settingsBox.put(setting, hotkeyData);
  }

  static Map<String, dynamic>? getHotkey(String setting) {
    final data = _settingsBox.get(setting);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> deleteHotkey(String setting) async {
    await _settingsBox.delete(setting);
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    await _settingsBox.put(_isOnboardingCompletedKey, completed);
  }

  static bool isOnboardingCompleted() {
    return _settingsBox.get(_isOnboardingCompletedKey, defaultValue: false)
        as bool;
  }

  // Permission storage methods
  static Future<void> savePermissionStatus(
      PermissionType permissionType, PermissionStatus status) async {
    String key;
    switch (permissionType) {
      case PermissionType.microphone:
        key = _microphonePermissionKey;
        break;
      case PermissionType.accessibility:
        key = _accessibilityPermissionKey;
        break;
      case PermissionType.screenRecording:
        key = _screenRecordingPermissionKey;
        break;
    }

    await _settingsBox.put(key, status.name);
  }

  static PermissionStatus? getStoredPermissionStatus(
      PermissionType permissionType) {
    String key;
    switch (permissionType) {
      case PermissionType.microphone:
        key = _microphonePermissionKey;
        break;
      case PermissionType.accessibility:
        key = _accessibilityPermissionKey;
        break;
      case PermissionType.screenRecording:
        key = _screenRecordingPermissionKey;
        break;
    }

    final statusString = _settingsBox.get(key) as String?;
    if (statusString == null) return null;

    // Convert string back to enum
    return PermissionStatus.values.firstWhere(
      (status) => status.name == statusString,
      orElse: () => PermissionStatus.notDetermined,
    );
  }

  static Future<Map<PermissionType, PermissionStatus>>
      getAllStoredPermissionStatuses() async {
    final Map<PermissionType, PermissionStatus> storedStatuses = {};

    for (final permissionType in PermissionType.values) {
      final status = getStoredPermissionStatus(permissionType);
      if (status != null) {
        storedStatuses[permissionType] = status;
      }
    }

    return storedStatuses;
  }

  static Future<void> clearAllPermissionStatuses() async {
    await _settingsBox.delete(_microphonePermissionKey);
    await _settingsBox.delete(_accessibilityPermissionKey);
    await _settingsBox.delete(_screenRecordingPermissionKey);
  }
}
