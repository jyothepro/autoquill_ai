import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../platform/recording_overlay_platform.dart';
import '../../utils/audio_utils.dart';
import '../../../../core/services/input_device_service.dart';
import 'package:path_provider/path_provider.dart';

abstract class RecordingDataSource {
  Future<void> startRecording();
  Future<String> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<void> cancelRecording();
  Future<void> restartRecording();
  Future<bool> get isRecording;
  Future<bool> get isPaused;
}

class RecordingDataSourceImpl implements RecordingDataSource {
  final AudioRecorder recorder;
  final InputDeviceService _inputDeviceService = InputDeviceService();
  String? _currentRecordingPath;
  // ignore: unused_field
  bool _isRecording = false;
  bool _isInitialized = false;

  // Track recording start time to calculate duration
  DateTime? _recordingStartTime;

  // Minimum recording duration in seconds - reduced for faster processing
  static const int _minimumRecordingDuration = 2;

  // Waveform data streaming
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  StreamSubscription<Amplitude>? _amplitudeStreamSubscription;
  late List<double> _waveformData;
  static const int _waveformSamples =
      60; // Number of amplitude values for waveform display

  RecordingDataSourceImpl({required this.recorder});

  /// Initialize the recording system
  /// This should be called when the app starts to ensure the recording system is ready
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Only setup the directory structure, don't check permissions yet
      // Permissions will be checked when the user actually tries to record

      // Ensure the recordings directory exists
      final recordingsDir = await _getRecordingsDirectory();
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Validate that we can write to the directory
      final testFile = File('${recordingsDir.path}/test_init.txt');
      await testFile.writeAsString('test');
      await testFile.delete();

      _isInitialized = true;
      if (kDebugMode) {
        print(
            'Recording system initialized successfully (without permission check)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing recording system: $e');
      }
      // We'll try again when needed
    }
  }

  Future<Directory> _getRecordingsDirectory() async {
    // Use application support directory (no special permissions needed)
    final appSupportDir = await getApplicationSupportDirectory();
    return Directory('${appSupportDir.path}/recordings');
  }

  Future<String> _getRecordingPath() async {
    final recordingsDir = await _getRecordingsDirectory();
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    // Generate a unique filename based on timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${recordingsDir.path}/recording_$timestamp.wav';
  }

  @override
  Future<void> startRecording() async {
    if (kDebugMode) {
      print('Recording started');
    }

    // Ensure the recording system is initialized
    if (!_isInitialized) {
      await initialize();
    }

    if (!await recorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }

    // Get a unique path for this recording
    _currentRecordingPath = await _getRecordingPath();
    if (kDebugMode) {
      print('Recording to: $_currentRecordingPath');
    }

    // Get the selected input device
    final selectedDevice = await _inputDeviceService.getSelectedInputDevice();

    RecordConfig config;

    if (selectedDevice != null) {
      // Try to create config with the selected device
      if (kDebugMode) {
        print(
            'Using selected input device: ${selectedDevice.label} (ID: ${selectedDevice.id})');
      }

      try {
        // Try different possible parameter names for device selection
        config = RecordConfig(
          encoder:
              AudioEncoder.pcm16bits, // Use PCM16 for real-time waveform data
          sampleRate: 44100, // Higher sample rate for better waveform quality
          numChannels: 1,
          device: selectedDevice, // Try 'device' parameter
        );
      } catch (e) {
        if (kDebugMode) {
          print(
              'RecordConfig device parameter not supported, using default: $e');
        }
        // Fall back to default config if device parameter is not supported
        config = RecordConfig(
          encoder:
              AudioEncoder.pcm16bits, // Use PCM16 for real-time waveform data
          sampleRate: 44100, // Higher sample rate for better waveform quality
          numChannels: 1,
        );
      }
    } else {
      // Use default config for system default device
      if (kDebugMode) {
        print('Using system default input device');
      }
      config = RecordConfig(
        encoder:
            AudioEncoder.pcm16bits, // Use PCM16 for real-time waveform data
        sampleRate: 44100, // Higher sample rate for better waveform quality
        numChannels: 1,
      );
    }

    await recorder.start(config, path: _currentRecordingPath!);
    _isRecording = true;

    // Initialize waveform data
    _waveformData = List.filled(_waveformSamples, 0.0);

    // Store the recording start time
    _recordingStartTime = DateTime.now();
    if (kDebugMode) {
      print('Recording started at: $_recordingStartTime');
    }

    // Setup audio stream for real-time waveform data
    _setupAudioStreamProcessing();

    // Show the recording overlay
    await RecordingOverlayPlatform.showOverlay();
  }

  /// Setup audio stream processing for real-time waveform data
  void _setupAudioStreamProcessing() async {
    try {
      // Cancel any existing amplitude subscription to get fresh data
      await _amplitudeStreamSubscription?.cancel();
      _amplitudeStreamSubscription = null;

      if (kDebugMode) {
        print('Setting up fresh amplitude stream for real-time waveform data');
      }

      // Use the amplitude stream for waveform visualization
      // This is more reliable than trying to process raw PCM data
      _amplitudeStreamSubscription =
          recorder.onAmplitudeChanged(const Duration(milliseconds: 50)).listen(
        (amplitude) {
          // amplitude.current gives dBFS values (negative numbers from ~-80 to 0)
          // Convert dBFS to linear amplitude (0.0 to 1.0)
          final dBFS = amplitude.current;

          // Map dBFS range (-60 to 0) to (0.0 to 1.0) for better visualization
          // Values below -60dB are considered essentially silence
          final normalizedAmplitude = ((dBFS + 60.0) / 60.0).clamp(0.0, 1.0);

          // Debug: Show conversion
          if (kDebugMode && normalizedAmplitude > 0.05) {
            print(
                'dBFS: $dBFS -> normalized: ${normalizedAmplitude.toStringAsFixed(3)}');
          }

          _updateWaveformData(normalizedAmplitude);
          RecordingOverlayPlatform.updateWaveformData(_waveformData);
        },
        onError: (error) {
          if (kDebugMode) {
            print('Amplitude stream error: $error');
          }
          // Fallback to simulated waveform on error
          _startSimulatedWaveform();
        },
      );

      if (kDebugMode) {
        print('Amplitude stream processing setup successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up amplitude stream: $e');
      }
      // Fallback to simulated waveform
      _startSimulatedWaveform();
    }
  }

  /// Process audio data for waveform visualization
  void _processAudioForWaveform(Uint8List audioData) {
    try {
      // Convert bytes to 16-bit PCM samples
      List<int> samples = [];
      for (int i = 0; i < audioData.length; i += 2) {
        if (i + 1 < audioData.length) {
          int sample = (audioData[i + 1] << 8) | audioData[i];
          // Convert unsigned to signed
          if (sample > 32767) sample -= 65536;
          samples.add(sample);
        }
      }

      if (samples.isNotEmpty) {
        // Calculate amplitude for this chunk of audio data
        double amplitude =
            samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b) /
                32767.0;

        // Update waveform data with the new amplitude
        _updateWaveformData(amplitude);

        // Send waveform data to the overlay
        RecordingOverlayPlatform.updateWaveformData(_waveformData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing audio for waveform: $e');
      }
    }
  }

  /// Update the waveform data array with new amplitude value
  void _updateWaveformData(double amplitude) {
    // Shift existing values to the left
    for (int i = 0; i < _waveformData.length - 1; i++) {
      _waveformData[i] = _waveformData[i + 1];
    }

    // Add new amplitude value at the end
    _waveformData[_waveformData.length - 1] = math.min(1.0, amplitude);
  }

  /// Start simulated waveform for testing/fallback
  void _startSimulatedWaveform() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      // Generate somewhat realistic simulated amplitude
      final baseLevel = 0.1;
      final randomComponent = math.Random().nextDouble() * 0.7;
      final spike = math.Random().nextInt(20) == 0 ? 0.4 : 0.0;
      final amplitude = math.min(1.0, baseLevel + randomComponent + spike);

      _updateWaveformData(amplitude);
      RecordingOverlayPlatform.updateWaveformData(_waveformData);
    });
  }

  @override
  Future<String> stopRecording() async {
    if (kDebugMode) {
      print('Recording stopped');
    }
    final recordingEndTime = DateTime.now();

    // Stop the recording immediately to capture only what the user intended
    final path = await recorder.stop();
    if (path == null) throw Exception('Failed to stop recording');

    // Clean up amplitude stream
    await _amplitudeStreamSubscription?.cancel();
    _amplitudeStreamSubscription = null;

    _isRecording = false;

    // Update the overlay text to show recording stopped
    await RecordingOverlayPlatform.setRecordingStopped();

    // Check if we need to pad the recording with silence
    String finalPath = path;
    if (_recordingStartTime != null) {
      final recordingDuration =
          recordingEndTime.difference(_recordingStartTime!).inMilliseconds /
              1000.0;
      if (kDebugMode) {
        print('Recording duration: $recordingDuration seconds');
      }

      if (recordingDuration < _minimumRecordingDuration) {
        if (kDebugMode) {
          print(
              'Recording too short, padding with silence to reach $_minimumRecordingDuration seconds');
        }

        try {
          // Pad the recording with silence to reach the minimum duration
          finalPath = await AudioUtils.padWithSilence(
              path, Duration(seconds: _minimumRecordingDuration));
          if (kDebugMode) {
            print('Successfully padded recording with silence: $finalPath');
          }

          // Delete the original file if it's different from the padded one
          if (finalPath != path) {
            try {
              await File(path).delete();
              if (kDebugMode) {
                print('Deleted original short recording file');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error deleting original recording file: $e');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error padding recording with silence: $e');
          }
          // If padding fails, we'll use the original recording
          finalPath = path;
        }
      }
    }

    _currentRecordingPath = null;
    _recordingStartTime = null;
    return finalPath;
  }

  @override
  Future<void> pauseRecording() async {
    await recorder.pause();
  }

  @override
  Future<void> resumeRecording() async {
    await recorder.resume();
  }

  @override
  Future<bool> get isRecording async => await recorder.isRecording();

  @override
  Future<bool> get isPaused async => await recorder.isPaused();

  @override
  Future<void> cancelRecording() async {
    if (await isRecording && _currentRecordingPath != null) {
      // Clean up amplitude stream
      await _amplitudeStreamSubscription?.cancel();
      _amplitudeStreamSubscription = null;

      await recorder.stop();
      _isRecording = false;
      // Delete the current recording file
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentRecordingPath = null;
      _recordingStartTime = null;

      // Hide the recording overlay
      await RecordingOverlayPlatform.hideOverlay();
    }
  }

  @override
  Future<void> restartRecording() async {
    // First stop the current recording but don't hide the overlay yet
    if (await isRecording) {
      await recorder.stop();
      _isRecording = false;

      // Delete the current recording file if it exists
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Reset recording start time
      _recordingStartTime = null;
    }

    // Then start a new recording
    await startRecording();
  }

  /// Dispose of resources
  void dispose() {
    _inputDeviceService.dispose();
  }
}
