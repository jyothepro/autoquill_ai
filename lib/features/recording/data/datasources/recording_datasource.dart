import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
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
  AudioRecorder? _currentRecorder; // Change to nullable and manage internally
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

  RecordingDataSourceImpl({AudioRecorder? recorder}) {
    // Keep the old constructor for compatibility but don't require it
    _currentRecorder = recorder;
  }

  /// Get or create a fresh AudioRecorder instance for each recording session
  AudioRecorder _getFreshRecorder() {
    // Always create a fresh instance to avoid stream reuse issues
    return AudioRecorder();
  }

  /// Sigmoid transformation for more pronounced waveform visualization
  /// This applies an S-curve to enhance high decibels and subdue low decibels
  double _applySigmoidTransformation(double normalizedAmplitude) {
    // Apply sigmoid curve: f(x) = 1 / (1 + e^(-k*(x-0.5)))
    // where k controls the steepness of the curve
    const double steepness = 8.0; // Higher values = more pronounced curve
    const double midpoint =
        0.3; // Shift the curve to be more sensitive to speech

    // Shift and scale input to work well with sigmoid
    double shifted = (normalizedAmplitude - midpoint) * steepness;
    double sigmoid = 1.0 / (1.0 + math.exp(-shifted));

    // Normalize back to 0-1 range and apply some scaling for visual appeal
    return (sigmoid * 1.2).clamp(0.0, 1.0);
  }

  /// Transform dBFS values to waveform height using an S-curve
  /// This properly handles silence and speech ranges for better visualization
  double _transformDbfsToWaveHeight(double dbfs,
      {double silenceFloor = -35.0, // dBFS at which we consider it full silence
      double speechCeiling =
          -15.0, // dBFS at which we consider it full loudness
      double curveSharpness = 0.2 // tweak this for more/less S-curve sharpness
      }) {
    // Clamp input dBFS to expected range
    dbfs = dbfs.clamp(silenceFloor, speechCeiling);

    // Normalize dBFS to a 0-1 range (0=silence, 1=loud)
    double normalized = (dbfs - silenceFloor) / (speechCeiling - silenceFloor);

    // Apply an S-curve using a smoothstep function (sigmoid variant)
    double curved = 1 / (1 + math.exp(-((normalized - 0.5) / curveSharpness)));

    return curved.clamp(0.0, 1.0); // Output in range ~0 (silent) to 1 (loud)
  }

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

    // Create a fresh AudioRecorder instance for this recording session
    _currentRecorder = _getFreshRecorder();

    if (!await _currentRecorder!.hasPermission()) {
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

    await _currentRecorder!.start(config, path: _currentRecordingPath!);
    _isRecording = true;

    // Initialize waveform data
    _waveformData = List.filled(_waveformSamples, 0.0);

    // Store the recording start time
    _recordingStartTime = DateTime.now();
    if (kDebugMode) {
      print('Recording started at: $_recordingStartTime');
    }

    // Setup audio stream for real-time waveform data - wait for recording to be fully started
    await Future.delayed(const Duration(milliseconds: 150));
    _setupAudioStreamProcessing();

    // Show the recording overlay
    await RecordingOverlayPlatform.showOverlay();
  }

  /// Setup audio stream processing for real-time waveform data
  void _setupAudioStreamProcessing() async {
    try {
      // Ensure any existing streams are completely cleaned up
      await _cleanupRecordingState();

      if (kDebugMode) {
        print('Setting up fresh amplitude stream for real-time waveform data');
      }

      // Verify that recording is active before setting up stream
      final isCurrentlyRecording = await _currentRecorder!.isRecording();
      if (!isCurrentlyRecording) {
        if (kDebugMode) {
          print('Recording not active, skipping amplitude stream setup');
        }
        return;
      }

      // Retry logic for stream setup to handle "already listened to" errors
      bool streamSetupSuccess = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!streamSetupSuccess && retryCount < maxRetries) {
        try {
          if (kDebugMode && retryCount > 0) {
            print(
                'Retrying amplitude stream setup (attempt ${retryCount + 1}/$maxRetries)');
          }

          // Try to set up the amplitude stream
          _amplitudeStreamSubscription = _currentRecorder!
              .onAmplitudeChanged(const Duration(milliseconds: 50))
              .listen(
            (amplitude) {
              try {
                // Get dBFS values directly without the old normalization
                final dBFS = amplitude.current;

                // Use the new transformation function that properly handles silence and speech
                final enhancedAmplitude = _transformDbfsToWaveHeight(dBFS);

                // Debug: Show the new transformation
                if (kDebugMode && (enhancedAmplitude > 0.01 || dBFS > -45.0)) {
                  print(
                      'dBFS: ${dBFS.toStringAsFixed(1)} -> enhanced: ${enhancedAmplitude.toStringAsFixed(3)}');
                }

                _updateWaveformData(enhancedAmplitude);
                RecordingOverlayPlatform.updateWaveformData(_waveformData);
              } catch (e) {
                if (kDebugMode) {
                  print('Error processing amplitude data: $e');
                }
              }
            },
            onError: (error) {
              if (kDebugMode) {
                print('Amplitude stream error: $error');
                print('Using simulated waveform as fallback');
              }
              // Fall back to simulated waveform only on stream error
              _startSimulatedWaveform();
            },
            onDone: () {
              if (kDebugMode) {
                print('Amplitude stream completed');
              }
              // Stream completed normally, don't restart
            },
          );

          streamSetupSuccess = true;
          if (kDebugMode) {
            print('Amplitude stream processing setup successfully');
          }
        } catch (e) {
          retryCount++;
          if (kDebugMode) {
            print(
                'Error setting up amplitude stream (attempt $retryCount): $e');
          }

          if (retryCount < maxRetries) {
            // Wait before retry and ensure cleanup
            await Future.delayed(Duration(milliseconds: 200 * retryCount));
            await _amplitudeStreamSubscription?.cancel();
            _amplitudeStreamSubscription = null;
          } else {
            if (kDebugMode) {
              print(
                  'Failed to setup amplitude stream after $maxRetries attempts, falling back to simulation');
            }
            _startSimulatedWaveform();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Critical error in amplitude stream setup: $e');
        print('Falling back to simulated waveform');
      }
      // Only fall back to simulation if stream setup completely fails
      _startSimulatedWaveform();
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
    if (kDebugMode) {
      print(
          '⚠️  Starting simulated waveform as fallback - real audio data unavailable');
    }

    Timer? simulationTimer;
    simulationTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        if (kDebugMode) {
          print('Stopped simulated waveform - recording ended');
        }
        return;
      }

      // Generate more realistic simulated dBFS values that resemble speech patterns
      final time = timer.tick * 0.1;

      // Create a speech-like pattern with pauses and bursts
      double simulatedDbfs = -60.0; // Start with silence level
      if (time % 3.0 < 2.0) {
        // 2 seconds of "speech", 1 second of silence
        // Speech pattern: varying dBFS values like real speech
        final speechBase =
            -35.0 + (10.0 * math.sin(time * 2.0)); // -45 to -25 dBFS base
        final speechVariation = 5.0 * math.sin(time * 8.0); // Small variations
        final speechSpikes = math.Random().nextDouble() < 0.3
            ? -15.0
            : speechBase; // Occasional louder sounds
        simulatedDbfs = speechSpikes + speechVariation;
      } else {
        // Silence with occasional background noise
        simulatedDbfs = math.Random().nextDouble() < 0.1 ? -50.0 : -60.0;
      }

      // Apply the same transformation function as real audio
      final enhancedAmplitude = _transformDbfsToWaveHeight(simulatedDbfs);

      _updateWaveformData(enhancedAmplitude);
      RecordingOverlayPlatform.updateWaveformData(_waveformData);

      if (kDebugMode && timer.tick % 20 == 0) {
        print(
            '🔄 Simulated waveform active (${timer.tick * 100}ms) - dBFS: ${simulatedDbfs.toStringAsFixed(1)} -> amplitude: ${enhancedAmplitude.toStringAsFixed(3)}');
      }
    });
  }

  @override
  Future<String> stopRecording() async {
    if (kDebugMode) {
      print('Recording stopped');
    }
    final recordingEndTime = DateTime.now();

    // Stop the recording immediately to capture only what the user intended
    final path = await _currentRecorder!.stop();
    if (path == null) throw Exception('Failed to stop recording');

    // Clean up amplitude stream properly and reset state
    await _cleanupRecordingState();

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

    if (kDebugMode) {
      print('Recording cleanup completed, final path: $finalPath');
    }

    return finalPath;
  }

  /// Clean up recording state and streams to prepare for next recording
  Future<void> _cleanupRecordingState() async {
    try {
      // Cancel amplitude stream subscription
      await _amplitudeStreamSubscription?.cancel();
      _amplitudeStreamSubscription = null;

      // Cancel audio stream subscription if it exists
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Add a small delay to ensure internal cleanup
      await Future.delayed(const Duration(milliseconds: 100));

      if (kDebugMode) {
        print('Recording state cleaned up successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during recording state cleanup: $e');
      }
    }
  }

  @override
  Future<void> pauseRecording() async {
    await _currentRecorder!.pause();
  }

  @override
  Future<void> resumeRecording() async {
    await _currentRecorder!.resume();
  }

  @override
  Future<bool> get isRecording async => await _currentRecorder!.isRecording();

  @override
  Future<bool> get isPaused async => await _currentRecorder!.isPaused();

  @override
  Future<void> cancelRecording() async {
    if (await isRecording && _currentRecordingPath != null) {
      // Clean up amplitude stream properly using the new cleanup method
      await _cleanupRecordingState();

      await _currentRecorder!.stop();
      _isRecording = false;
      // Delete the current recording file
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentRecordingPath = null;
      _recordingStartTime = null;

      if (kDebugMode) {
        print('Recording cancelled and cleaned up');
      }

      // Hide the recording overlay
      await RecordingOverlayPlatform.hideOverlay();
    }
  }

  @override
  Future<void> restartRecording() async {
    if (kDebugMode) {
      print('Restarting recording...');
    }

    // First stop the current recording but don't hide the overlay yet
    if (await isRecording) {
      // Clean up using the new cleanup method
      await _cleanupRecordingState();

      await _currentRecorder!.stop();
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

      if (kDebugMode) {
        print('Previous recording stopped and cleaned up');
      }
    }

    // Wait a moment to ensure complete cleanup and state reset
    await Future.delayed(const Duration(milliseconds: 300));

    // Then start a new recording
    await startRecording();

    if (kDebugMode) {
      print('Recording restarted successfully');
    }
  }

  /// Dispose of resources
  void dispose() {
    _inputDeviceService.dispose();
  }
}
