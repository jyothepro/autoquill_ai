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
    // Use a more persistent storage location that survives auto-updates
    await Hive.initFlutter('autoquill_persistent_data');
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
    try {
      // Primary check - normal onboarding completion flag
      final isCompleted = _settingsBox.get(_isOnboardingCompletedKey,
          defaultValue: false) as bool;

      // If onboarding is marked complete, do additional validation
      if (isCompleted) {
        // Check if we have essential settings that prove onboarding was actually completed
        final hasApiKey = _settingsBox.containsKey(_groqKey);
        final hasHotkeys = _settingsBox.containsKey('transcription_hotkey') ||
            _settingsBox.containsKey('assistant_hotkey');

        // If we have the completion flag but missing essential data,
        // this might be after an app update - try to preserve the completion status
        if (!hasApiKey && !hasHotkeys) {
          // Check if we have any stored permission data (indicates previous setup)
          final hasPermissions =
              _settingsBox.containsKey(_microphonePermissionKey) ||
                  _settingsBox.containsKey(_accessibilityPermissionKey) ||
                  _settingsBox.containsKey(_screenRecordingPermissionKey);

          if (hasPermissions) {
            // We have permission data, so user did complete onboarding before
            // This is likely post-update data loss - keep onboarding completed
            return true;
          } else {
            // No essential data at all, reset onboarding flag
            _settingsBox.put(_isOnboardingCompletedKey, false);
            return false;
          }
        }
      }

      return isCompleted;
    } catch (e) {
      // If there's any error reading storage, assume onboarding is not completed
      return false;
    }
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

  // Auto-update detection and handling
  static const String _lastKnownVersionKey = 'last_known_app_version';
  static const String _autoUpdateDetectedKey = 'auto_update_detected';

  static Future<void> checkForAutoUpdate(String currentVersion) async {
    final lastKnownVersion = _settingsBox.get(_lastKnownVersionKey) as String?;

    if (lastKnownVersion != null && lastKnownVersion != currentVersion) {
      // App version changed - this indicates an auto-update occurred
      await _settingsBox.put(_autoUpdateDetectedKey, true);
      print('Auto-update detected: $lastKnownVersion -> $currentVersion');
    }

    // Update the stored version
    await _settingsBox.put(_lastKnownVersionKey, currentVersion);
  }

  static bool wasAutoUpdateDetected() {
    return _settingsBox.get(_autoUpdateDetectedKey, defaultValue: false)
        as bool;
  }

  static Future<void> clearAutoUpdateFlag() async {
    await _settingsBox.delete(_autoUpdateDetectedKey);
  }

  // Enhanced permission checking for auto-updates
  static Future<Map<PermissionType, PermissionStatus>>
      getPermissionsWithAutoUpdateHandling() async {
    final storedPermissions = await getAllStoredPermissionStatuses();
    final wasAutoUpdated = wasAutoUpdateDetected();

    if (wasAutoUpdated && storedPermissions.isNotEmpty) {
      // If this was an auto-update and we have stored permissions,
      // we should trust the stored permissions more than system checks initially
      print(
          'Auto-update detected with stored permissions - using stored values initially');
      return storedPermissions;
    }

    return storedPermissions;
  }
}
