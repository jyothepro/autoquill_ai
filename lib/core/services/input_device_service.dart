import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:record/record.dart';

/// Service to manage audio input devices using the record package
class InputDeviceService {
  static const String _selectedDeviceKey = 'selected_input_device_id';

  final AudioRecorder _audioRecorder = AudioRecorder();

  /// Get all available input devices
  Future<List<InputDevice>> getAvailableInputDevices() async {
    try {
      final devices = await _audioRecorder.listInputDevices();
      if (kDebugMode) {
        print('Found ${devices.length} input devices:');
        for (final device in devices) {
          print('  - ${device.label} (ID: ${device.id})');
        }
      }
      return devices;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting input devices: $e');
      }
      return [];
    }
  }

  /// Get the currently selected input device
  Future<InputDevice?> getSelectedInputDevice() async {
    try {
      final settingsBox = Hive.box('settings');
      final savedDeviceId = settingsBox.get(_selectedDeviceKey) as String?;

      if (savedDeviceId == null) {
        return null;
      }

      final devices = await getAvailableInputDevices();
      return devices.where((device) => device.id == savedDeviceId).firstOrNull;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting selected input device: $e');
      }
      return null;
    }
  }

  /// Save the selected input device
  Future<void> saveSelectedInputDevice(InputDevice device) async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.put(_selectedDeviceKey, device.id);
      if (kDebugMode) {
        print(
            'Saved selected input device: ${device.label} (ID: ${device.id})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving selected input device: $e');
      }
    }
  }

  /// Clear the selected input device (use system default)
  Future<void> clearSelectedInputDevice() async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.delete(_selectedDeviceKey);
      if (kDebugMode) {
        print('Cleared selected input device, will use system default');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing selected input device: $e');
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    _audioRecorder.dispose();
  }
}
