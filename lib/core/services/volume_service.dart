import 'package:flutter/foundation.dart';
import 'package:volume_controller/volume_controller.dart';

/// Service for managing system volume during recording
class VolumeService {
  static VolumeService? _instance;
  static VolumeService get instance => _instance ??= VolumeService._();

  VolumeService._();

  bool _isMuted = false;
  bool _isInitialized = false;
  bool _hasVolumePermission = false;

  /// Initialize the volume service
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        return;
      }

      // Hide system UI for volume changes (recommended for apps that control volume)
      VolumeController.instance.showSystemUI = false;

      // Test if we can access volume (this will throw if no permission)
      final currentVolume = await VolumeController.instance.getVolume();

      // Test if we can actually control muting by checking current mute state
      final currentMuteState = await VolumeController.instance.isMuted();

      // Test muting functionality by attempting to set mute (then restore)
      await VolumeController.instance.setMute(!currentMuteState);
      final testMuteState = await VolumeController.instance.isMuted();

      // Restore original mute state
      await VolumeController.instance.setMute(currentMuteState);

      // Check if the mute control actually works
      _hasVolumePermission = (testMuteState != currentMuteState);
      _isInitialized = true;

      if (kDebugMode) {
        print(
            'VolumeService initialized successfully with current volume: $currentVolume');
        print('VolumeService has volume permission: $_hasVolumePermission');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing VolumeService: $e');
        print(
            'This likely means the app does not have permission to control system volume on macOS.');
        print(
            'On macOS, this feature may require specific permissions or may not be available.');
      }
      _isInitialized = false;
      _hasVolumePermission = false;
    }
  }

  /// Mute the system volume
  Future<bool> muteVolume() async {
    try {
      if (!_isInitialized || !_hasVolumePermission) {
        if (kDebugMode) {
          print(
              'VolumeService: Not initialized or no volume permission, cannot mute volume');
        }
        return false;
      }

      if (_isMuted) {
        if (kDebugMode) {
          print('VolumeService: Already muted, skipping');
        }
        return true;
      }

      if (kDebugMode) {
        print('VolumeService: Muting system volume');
      }

      // Use the proper setMute function
      await VolumeController.instance.setMute(true);

      // Verify that the volume was actually muted
      final verifyMuted = await VolumeController.instance.isMuted();
      if (!verifyMuted) {
        if (kDebugMode) {
          print('VolumeService: Volume muting failed - system is not muted');
          print(
              'VolumeService: This is likely due to macOS security restrictions');
        }
        return false;
      }

      _isMuted = true;

      if (kDebugMode) {
        print('VolumeService: System volume successfully muted');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('VolumeService: Error muting volume: $e');
        print(
            'VolumeService: Volume control may not be available on this system');
      }
      return false;
    }
  }

  /// Restore the previously saved volume level
  Future<bool> restoreVolume() async {
    try {
      if (!_isInitialized || !_hasVolumePermission) {
        if (kDebugMode) {
          print(
              'VolumeService: Not initialized or no volume permission, cannot restore volume');
        }
        return false;
      }

      if (!_isMuted) {
        if (kDebugMode) {
          print('VolumeService: Not muted, skipping restore');
        }
        return true;
      }

      if (kDebugMode) {
        print('VolumeService: Unmuting system volume');
      }

      // Use the proper setMute function to unmute
      await VolumeController.instance.setMute(false);

      // Verify that the volume was actually unmuted
      final verifyMuted = await VolumeController.instance.isMuted();
      if (verifyMuted) {
        if (kDebugMode) {
          print(
              'VolumeService: Volume restoration failed - system is still muted');
        }
        return false;
      }

      _isMuted = false;

      if (kDebugMode) {
        print('VolumeService: System volume successfully restored');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('VolumeService: Error restoring volume: $e');
        print(
            'VolumeService: Volume control may not be available on this system');
      }
      return false;
    }
  }

  /// Check if volume is currently muted by this service
  bool get isMuted => _isMuted;

  /// Check if the service has permission to control volume
  bool get hasVolumePermission => _hasVolumePermission;

  /// Force reset the mute state (in case of errors)
  void resetMuteState() {
    _isMuted = false;
    if (kDebugMode) {
      print('VolumeService: Mute state reset');
    }
  }

  /// Get current system volume
  Future<double?> getCurrentVolume() async {
    try {
      if (!_isInitialized || !_hasVolumePermission) {
        if (kDebugMode) {
          print(
              'VolumeService: Not initialized or no volume permission, cannot get current volume');
        }
        return null;
      }

      return await VolumeController.instance.getVolume();
    } catch (e) {
      if (kDebugMode) {
        print('VolumeService: Error getting current volume: $e');
        print(
            'VolumeService: Volume control may not be available on this system');
      }
      return null;
    }
  }

  /// Check if system is currently muted
  Future<bool?> isSystemMuted() async {
    try {
      if (!_isInitialized || !_hasVolumePermission) {
        if (kDebugMode) {
          print(
              'VolumeService: Not initialized or no volume permission, cannot check mute status');
        }
        return null;
      }

      return await VolumeController.instance.isMuted();
    } catch (e) {
      if (kDebugMode) {
        print('VolumeService: Error checking mute status: $e');
        print(
            'VolumeService: Volume control may not be available on this system');
      }
      return null;
    }
  }
}
