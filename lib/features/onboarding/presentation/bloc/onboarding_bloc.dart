import 'dart:async';
import 'package:autoquill_ai/core/settings/settings_service.dart';
import 'package:autoquill_ai/core/storage/app_storage.dart';
import 'package:autoquill_ai/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:autoquill_ai/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:autoquill_ai/core/permissions/permission_service.dart';
import 'package:autoquill_ai/widgets/hotkey_handler.dart';
import 'package:autoquill_ai/core/di/injection_container.dart' as di;
import 'package:autoquill_ai/features/recording/presentation/bloc/recording_bloc.dart';
import 'package:autoquill_ai/features/transcription/presentation/bloc/transcription_bloc.dart'
    as transcription_bloc;
import 'package:autoquill_ai/features/recording/domain/repositories/recording_repository.dart';
import 'package:autoquill_ai/features/transcription/domain/repositories/transcription_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/whisper_kit_service.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  Timer? _permissionCheckTimer;
  Timer? _debounceTimer;

  OnboardingBloc() : super(const OnboardingState()) {
    on<InitializeOnboarding>(_onInitializeOnboarding);
    on<InitializePageController>(_onInitializePageController);
    on<DisposePageController>(_onDisposePageController);
    on<InitializeApiKeyController>(_onInitializeApiKeyController);
    on<DisposeApiKeyController>(_onDisposeApiKeyController);
    on<ToggleApiKeyVisibility>(_onToggleApiKeyVisibility);
    on<ClearApiKey>(_onClearApiKey);

    // Permission events
    on<CheckPermissions>(_onCheckPermissions);
    on<StartPeriodicPermissionCheck>(_onStartPeriodicPermissionCheck);
    on<StopPeriodicPermissionCheck>(_onStopPeriodicPermissionCheck);
    on<AddPendingPermission>(_onAddPendingPermission);
    on<RemovePendingPermission>(_onRemovePendingPermission);
    on<OnAppResumed>(_onAppResumed);
    on<RequestPermission>(_onRequestPermission);
    on<OpenSystemPreferences>(_onOpenSystemPreferences);
    on<UpdatePermissionStatus>(_onUpdatePermissionStatus);

    // UpdateSelectedTools event removed as both tools are always enabled
    on<UpdateApiKey>(_onUpdateApiKey);
    on<ValidateApiKey>(_onValidateApiKey);
    on<UpdateTranscriptionHotkey>(_onUpdateTranscriptionHotkey);
    on<UpdateAssistantHotkey>(_onUpdateAssistantHotkey);
    on<UpdatePushToTalkHotkey>(_onUpdatePushToTalkHotkey);
    on<RegisterHotkeys>(_onRegisterHotkeys);
    on<UpdateThemePreference>(_onUpdateThemePreference);
    on<UpdateAutoCopyPreference>(_onUpdateAutoCopyPreference);
    on<UpdateTranscriptionModel>(_onUpdateTranscriptionModel);
    on<UpdateAssistantScreenshotPreference>(
        _onUpdateAssistantScreenshotPreference);
    on<UpdateSmartTranscriptionPreference>(
        _onUpdateSmartTranscriptionPreference);

    // Local transcription events
    on<LoadLocalTranscriptionSettings>(_onLoadLocalTranscriptionSettings);
    on<ToggleLocalTranscription>(_onToggleLocalTranscription);
    on<SelectLocalModel>(_onSelectLocalModel);
    on<DownloadModel>(_onDownloadModel);
    on<UpdateModelDownloadProgress>(_onUpdateModelDownloadProgress);
    on<ModelDownloadCompleted>(_onModelDownloadCompleted);
    on<ModelDownloadFailed>(_onModelDownloadFailed);
    on<LoadDownloadedModels>(_onLoadDownloadedModels);

    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<NavigateToNextStep>(_onNavigateToNextStep);
    on<NavigateToPreviousStep>(_onNavigateToPreviousStep);
    // SkipOnboarding event removed as skipping is no longer allowed
  }

  void _onInitializePageController(
    InitializePageController event,
    Emitter<OnboardingState> emit,
  ) {
    final pageController = PageController();
    emit(state.copyWith(
      pageController: pageController,
      progressValue: 0.0,
    ));
  }

  void _onDisposePageController(
    DisposePageController event,
    Emitter<OnboardingState> emit,
  ) {
    state.pageController?.dispose();
    _stopPermissionChecking();

    // Also dispose the API key controller when disposing the page controller
    if (state.apiKeyController != null) {
      try {
        state.apiKeyController!.dispose();
      } catch (e) {
        if (kDebugMode) {
          print(
              'Warning: Error disposing API key controller on page disposal: $e');
        }
      }
    }

    emit(state.copyWith(
      pageController: null,
      apiKeyController: null,
    ));
  }

  void _onInitializeApiKeyController(
    InitializeApiKeyController event,
    Emitter<OnboardingState> emit,
  ) {
    // Dispose existing controller if it exists
    if (state.apiKeyController != null) {
      try {
        state.apiKeyController!.dispose();
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Error disposing existing API key controller: $e');
        }
      }
    }

    final apiKeyController = TextEditingController();
    // Set initial value if API key exists
    if (state.apiKey.isNotEmpty) {
      apiKeyController.text = state.apiKey;
    }
    emit(state.copyWith(
      apiKeyController: apiKeyController,
    ));
  }

  void _onDisposeApiKeyController(
    DisposeApiKeyController event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.apiKeyController != null) {
      try {
        state.apiKeyController!.dispose();
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Error disposing API key controller: $e');
        }
      }
    }
    emit(state.copyWith(
      apiKeyController: null,
    ));
  }

  void _onToggleApiKeyVisibility(
    ToggleApiKeyVisibility event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(
      apiKeyObscureText: !state.apiKeyObscureText,
    ));
  }

  void _onClearApiKey(
    ClearApiKey event,
    Emitter<OnboardingState> emit,
  ) {
    state.apiKeyController?.clear();
    emit(state.copyWith(
      apiKey: '',
      apiKeyStatus: ApiKeyValidationStatus.initial,
    ));
  }

  void _onStartPeriodicPermissionCheck(
    StartPeriodicPermissionCheck event,
    Emitter<OnboardingState> emit,
  ) {
    _stopPermissionChecking(); // Stop any existing timer

    emit(state.copyWith(isPermissionCheckingActive: true));

    // Check permissions every 5 seconds to catch changes from System Preferences
    _permissionCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        add(CheckPermissions());
      },
    );
  }

  void _onStopPeriodicPermissionCheck(
    StopPeriodicPermissionCheck event,
    Emitter<OnboardingState> emit,
  ) {
    _stopPermissionChecking();
    emit(state.copyWith(isPermissionCheckingActive: false));
  }

  void _onAddPendingPermission(
    AddPendingPermission event,
    Emitter<OnboardingState> emit,
  ) {
    final updatedPending = Set<PermissionType>.from(state.pendingPermissions)
      ..add(event.permissionType);

    emit(state.copyWith(pendingPermissions: updatedPending));

    // Auto-remove after a delay based on permission type
    final delayDuration = event.permissionType == PermissionType.accessibility
        ? const Duration(seconds: 2)
        : const Duration(seconds: 3);

    Timer(delayDuration, () {
      add(RemovePendingPermission(permissionType: event.permissionType));
    });
  }

  void _onRemovePendingPermission(
    RemovePendingPermission event,
    Emitter<OnboardingState> emit,
  ) {
    final updatedPending = Set<PermissionType>.from(state.pendingPermissions)
      ..remove(event.permissionType);

    emit(state.copyWith(pendingPermissions: updatedPending));
  }

  void _onAppResumed(
    OnAppResumed event,
    Emitter<OnboardingState> emit,
  ) {
    // Check permissions with debounce when app resumes
    _checkPermissionsWithDebounce();
  }

  void _stopPermissionChecking() {
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _checkPermissionsWithDebounce() {
    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    // Set up a new debounce timer to prevent rapid consecutive calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      add(CheckPermissions());
    });
  }

  @override
  Future<void> close() {
    _stopPermissionChecking();
    state.apiKeyController?.dispose();
    return super.close();
  }

  void _onInitializeOnboarding(
    InitializeOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    // Set default hotkeys
    final defaultTranscriptionHotkey = HotKey(
      key: LogicalKeyboardKey.keyZ,
      modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );

    final defaultAssistantHotkey = HotKey(
      key: LogicalKeyboardKey.keyS,
      modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );

    final defaultPushToTalkHotkey = HotKey(
      key: LogicalKeyboardKey.space,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.system,
    );

    emit(state.copyWith(
      transcriptionHotkey: defaultTranscriptionHotkey,
      assistantHotkey: defaultAssistantHotkey,
      pushToTalkHotkey: defaultPushToTalkHotkey,
    ));

    // Check permissions on app startup with enhanced restart handling
    try {
      // First, load any stored permission statuses from previous sessions
      final storedPermissions =
          await AppStorage.getAllStoredPermissionStatuses();
      if (kDebugMode) {
        print('Loaded stored permissions: $storedPermissions');
      }

      // Check current permission statuses from the system
      final currentPermissions = await PermissionService.checkAllPermissions();
      if (kDebugMode) {
        print('Current system permissions: $currentPermissions');
      }

      // Enhanced merging logic with robust restart handling
      final Map<PermissionType, PermissionStatus> finalPermissions = {};

      for (final permissionType in PermissionType.values) {
        final current = currentPermissions[permissionType] ??
            PermissionStatus.notDetermined;
        final stored = storedPermissions[permissionType];

        // Enhanced handling for app restart scenarios, especially screen recording
        if (current == PermissionStatus.notDetermined &&
            stored == PermissionStatus.authorized) {
          if (kDebugMode) {
            print(
                '${permissionType.name} permission was stored as authorized but currently notDetermined, performing thorough verification...');
          }

          // Give system time to recognize permissions after restart
          await Future.delayed(const Duration(milliseconds: 800));

          // Multiple verification attempts for reliability
          PermissionStatus verifiedStatus = PermissionStatus.notDetermined;
          for (int attempt = 1; attempt <= 3; attempt++) {
            verifiedStatus =
                await PermissionService.checkPermission(permissionType);

            if (kDebugMode) {
              print(
                  '${permissionType.name} verification attempt $attempt: $verifiedStatus');
            }

            if (verifiedStatus == PermissionStatus.authorized) {
              break;
            }

            // Wait longer between attempts for system to catch up (important after restart)
            if (attempt < 3) {
              await Future.delayed(Duration(milliseconds: 600 * attempt));
            }
          }

          if (verifiedStatus == PermissionStatus.authorized) {
            finalPermissions[permissionType] = verifiedStatus;
            if (kDebugMode) {
              print(
                  '${permissionType.name} permission verified as authorized after restart');
            }
          } else {
            // Trust stored status if system hasn't caught up yet (especially common for screen recording)
            finalPermissions[permissionType] = stored!;
            if (kDebugMode) {
              print(
                  'Using stored ${permissionType.name} permission status after restart: $stored');
            }
          }
        } else {
          // For normal cases or when current status is reliable, use current status
          finalPermissions[permissionType] = current;
        }
      }

      emit(state.copyWith(permissionStatuses: finalPermissions));

      if (kDebugMode) {
        print(
            'Final permission statuses after initialization: $finalPermissions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permissions on startup: $e');
      }
    }
  }

  Future<void> _onCheckPermissions(
    CheckPermissions event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      if (kDebugMode) {
        print('OnboardingBloc: Checking all permissions...');
      }

      // Get stored permissions from previous sessions
      final storedPermissions =
          await AppStorage.getAllStoredPermissionStatuses();

      // Check current permissions from the system
      final currentPermissions = await PermissionService.checkAllPermissions();

      // Merge stored and current permissions with enhanced logic for app restarts
      final Map<PermissionType, PermissionStatus> finalPermissions = {};

      for (final permissionType in PermissionType.values) {
        final current = currentPermissions[permissionType] ??
            PermissionStatus.notDetermined;
        final stored = storedPermissions[permissionType];

        PermissionStatus finalStatus;

        // Enhanced handling for screen recording after app restarts
        if (permissionType == PermissionType.screenRecording) {
          if (stored == PermissionStatus.authorized &&
              current == PermissionStatus.notDetermined) {
            // App restart scenario: stored permission is authorized but current check shows notDetermined
            // This commonly happens after screen recording permission is granted and app is restarted
            if (kDebugMode) {
              print(
                  'OnboardingBloc: Screen recording permission mismatch - stored: $stored, current: $current');
              print(
                  'OnboardingBloc: Performing additional verification checks...');
            }

            // Give the system more time to recognize the permission after restart
            await Future.delayed(const Duration(milliseconds: 500));

            // Multiple verification attempts with increasing delays
            PermissionStatus verifiedStatus = PermissionStatus.notDetermined;
            for (int attempt = 1; attempt <= 3; attempt++) {
              if (kDebugMode) {
                print(
                    'OnboardingBloc: Screen recording verification attempt $attempt/3');
              }

              verifiedStatus =
                  await PermissionService.checkPermission(permissionType);
              if (verifiedStatus == PermissionStatus.authorized) {
                if (kDebugMode) {
                  print(
                      'OnboardingBloc: Screen recording permission verified as authorized on attempt $attempt');
                }
                break;
              }

              // Wait longer between attempts for system to catch up
              if (attempt < 3) {
                await Future.delayed(Duration(milliseconds: 500 * attempt));
              }
            }

            // If verification confirms authorization, use it; otherwise trust stored value
            if (verifiedStatus == PermissionStatus.authorized) {
              finalStatus = verifiedStatus;
            } else {
              // System might still be catching up after restart, use stored value
              finalStatus = stored!;
              if (kDebugMode) {
                print(
                    'OnboardingBloc: Using stored screen recording permission status after restart: $stored');
              }
            }
          } else {
            // Normal case or current status is reliable
            finalStatus = current;
            // Save the current status to storage
            await AppStorage.savePermissionStatus(permissionType, current);
          }
        } else {
          // For microphone and accessibility permissions, prioritize current status
          // but handle cases where system might be slow to respond
          if (stored == PermissionStatus.authorized &&
              current == PermissionStatus.notDetermined) {
            // Double-check for other permissions too, in case of system delay
            if (kDebugMode) {
              print(
                  'OnboardingBloc: Permission mismatch for ${permissionType.name} - stored: $stored, current: $current');
            }

            await Future.delayed(const Duration(milliseconds: 200));
            final recheckStatus =
                await PermissionService.checkPermission(permissionType);

            if (recheckStatus == PermissionStatus.authorized) {
              finalStatus = recheckStatus;
            } else {
              // Use current status if recheck doesn't confirm authorization
              finalStatus = current;
            }
          } else {
            finalStatus = current;
          }

          // Save the current status to storage
          await AppStorage.savePermissionStatus(permissionType, finalStatus);
        }

        finalPermissions[permissionType] = finalStatus;
      }

      emit(state.copyWith(permissionStatuses: finalPermissions));

      if (kDebugMode) {
        print('OnboardingBloc: Permission check completed: $finalPermissions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permissions: $e');
      }
    }
  }

  Future<void> _onRequestPermission(
    RequestPermission event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      if (kDebugMode) {
        print(
            'OnboardingBloc: Requesting permission for ${event.permissionType}');
      }

      final status =
          await PermissionService.requestPermission(event.permissionType);

      if (kDebugMode) {
        print(
            'OnboardingBloc: Permission request result for ${event.permissionType}: $status');
      }

      // Save the permission status to Hive storage
      await AppStorage.savePermissionStatus(event.permissionType, status);
      if (kDebugMode) {
        print(
            'OnboardingBloc: Saved permission status to storage: ${event.permissionType} = $status');
      }

      // Update the permission status in the state
      final updatedPermissions =
          Map<PermissionType, PermissionStatus>.from(state.permissionStatuses);
      updatedPermissions[event.permissionType] = status;

      emit(state.copyWith(permissionStatuses: updatedPermissions));

      // If permission is still not granted after request, re-check the status
      if (status != PermissionStatus.authorized) {
        if (kDebugMode) {
          print('OnboardingBloc: Permission not granted, rechecking status...');
        }

        // Wait a bit and then recheck the permission status
        await Future.delayed(const Duration(milliseconds: 500));
        final recheckStatus =
            await PermissionService.checkPermission(event.permissionType);

        if (recheckStatus != status) {
          if (kDebugMode) {
            print(
                'OnboardingBloc: Permission status changed after recheck: $recheckStatus');
          }

          // Save the updated status to storage
          await AppStorage.savePermissionStatus(
              event.permissionType, recheckStatus);

          updatedPermissions[event.permissionType] = recheckStatus;
          emit(state.copyWith(permissionStatuses: updatedPermissions));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permission ${event.permissionType}: $e');
      }
    }
  }

  Future<void> _onOpenSystemPreferences(
    OpenSystemPreferences event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      await PermissionService.openSystemPreferences(event.permissionType);
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error opening system preferences for ${event.permissionType}: $e');
      }
    }
  }

  void _onUpdatePermissionStatus(
    UpdatePermissionStatus event,
    Emitter<OnboardingState> emit,
  ) {
    final updatedPermissions =
        Map<PermissionType, PermissionStatus>.from(state.permissionStatuses);
    updatedPermissions[event.permissionType] = event.status;

    emit(state.copyWith(permissionStatuses: updatedPermissions));
  }

  // _onUpdateSelectedTools removed as both tools are always enabled

  void _onUpdateApiKey(
    UpdateApiKey event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(
      apiKey: event.apiKey,
      apiKeyStatus: ApiKeyValidationStatus.initial,
    ));
  }

  Future<void> _onValidateApiKey(
    ValidateApiKey event,
    Emitter<OnboardingState> emit,
  ) async {
    if (event.apiKey.isEmpty) {
      emit(state.copyWith(apiKeyStatus: ApiKeyValidationStatus.invalid));
      return;
    }

    emit(state.copyWith(apiKeyStatus: ApiKeyValidationStatus.validating));

    try {
      // Validate Groq API key by making a test request
      // Using a simpler endpoint with minimal data transfer
      final response = await http.get(
        Uri.parse('https://api.groq.com/openai/v1/models'),
        headers: {
          'Authorization': 'Bearer ${event.apiKey}',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Groq API validation response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        emit(state.copyWith(
          apiKey: event.apiKey,
          apiKeyStatus: ApiKeyValidationStatus.valid,
        ));
      } else {
        // For debugging purposes, log the error details
        if (kDebugMode) {
          print('Invalid API key. Status code: ${response.statusCode}');
        }
        emit(state.copyWith(apiKeyStatus: ApiKeyValidationStatus.invalid));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error validating API key: $e');
      }
      // Handle network errors gracefully
      emit(state.copyWith(apiKeyStatus: ApiKeyValidationStatus.invalid));
    }
  }

  void _onUpdateTranscriptionHotkey(
    UpdateTranscriptionHotkey event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(transcriptionHotkey: event.hotkey));
  }

  void _onUpdateAssistantHotkey(
    UpdateAssistantHotkey event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(assistantHotkey: event.hotkey));
  }

  void _onUpdatePushToTalkHotkey(
    UpdatePushToTalkHotkey event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(pushToTalkHotkey: event.hotkey));
  }

  Future<void> _onRegisterHotkeys(
    RegisterHotkeys event,
    Emitter<OnboardingState> emit,
  ) async {
    // This will register the hotkeys when moving from hotkeys step to test step
    try {
      // Save the current hotkeys to storage so they can be picked up by the hotkey system
      final settingsService = SettingsService();

      if (state.transcriptionHotkey != null) {
        await settingsService
            .setTranscriptionHotkey(state.transcriptionHotkey!);
        final hotkeyMap = state.transcriptionHotkey!.toJson();
        await AppStorage.settingsBox.put('transcription_hotkey', hotkeyMap);
      }

      if (state.assistantHotkey != null) {
        await settingsService.setAssistantHotkey(state.assistantHotkey!);
        final hotkeyMap = state.assistantHotkey!.toJson();
        await AppStorage.settingsBox.put('assistant_hotkey', hotkeyMap);
      }

      if (state.pushToTalkHotkey != null) {
        final hotkeyMap = state.pushToTalkHotkey!.toJson();
        await AppStorage.settingsBox.put('push_to_talk_hotkey', hotkeyMap);
      }

      if (kDebugMode) {
        print('Hotkeys saved to storage for testing');
      }

      // Reload hotkeys
      await HotkeyHandler.reloadHotkeys();
    } catch (e) {
      if (kDebugMode) {
        print('Error registering hotkeys: $e');
      }
    }
  }

  void _onUpdateThemePreference(
    UpdateThemePreference event,
    Emitter<OnboardingState> emit,
  ) async {
    // Use the settings service to update theme
    final settingsService = SettingsService();
    await settingsService.setThemeMode(event.themeMode);

    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _onUpdateAutoCopyPreference(
    UpdateAutoCopyPreference event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(autoCopyEnabled: event.autoCopyEnabled));
  }

  void _onUpdateTranscriptionModel(
    UpdateTranscriptionModel event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(transcriptionModel: event.modelName));
  }

  void _onUpdateAssistantScreenshotPreference(
    UpdateAssistantScreenshotPreference event,
    Emitter<OnboardingState> emit,
  ) async {
    // Save the setting immediately to make it available for testing
    try {
      await AppStorage.settingsBox
          .put('assistant_screenshot_enabled', event.enabled);

      if (kDebugMode) {
        print(
            'Assistant screenshot preference saved immediately: ${event.enabled}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving assistant screenshot preference: $e');
      }
    }

    emit(state.copyWith(assistantScreenshotEnabled: event.enabled));
  }

  void _onUpdateSmartTranscriptionPreference(
    UpdateSmartTranscriptionPreference event,
    Emitter<OnboardingState> emit,
  ) async {
    // Save the setting immediately to make it available for testing
    try {
      await AppStorage.settingsBox
          .put('smart_transcription_enabled', event.enabled);

      if (kDebugMode) {
        print(
            'Smart transcription preference saved immediately: ${event.enabled}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving smart transcription preference: $e');
      }
    }

    emit(state.copyWith(smartTranscriptionEnabled: event.enabled));
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      // Save all settings to persistent storage
      await _saveOnboardingSettings();

      // Mark onboarding as completed
      await AppStorage.setOnboardingCompleted(true);

      // Dispose the API key controller now that onboarding is complete
      if (state.apiKeyController != null) {
        try {
          state.apiKeyController!.dispose();
        } catch (e) {
          if (kDebugMode) {
            print(
                'Warning: Error disposing API key controller on completion: $e');
          }
        }
      }

      // Add a delay to ensure all settings are properly saved before navigation
      await Future.delayed(const Duration(milliseconds: 500));

      emit(state.copyWith(
        currentStep: OnboardingStep.completed,
        apiKeyController: null,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error completing onboarding: $e');
      }
      // Still try to complete onboarding even if there was an error
      emit(state.copyWith(currentStep: OnboardingStep.completed));
    }
  }

  void _onNavigateToNextStep(
    NavigateToNextStep event,
    Emitter<OnboardingState> emit,
  ) {
    final currentStep = state.currentStep;
    OnboardingStep nextStep;

    switch (currentStep) {
      case OnboardingStep.welcome:
        nextStep = OnboardingStep.permissions;
        break;
      case OnboardingStep.permissions:
        nextStep = OnboardingStep.apiKey;
        // Initialize systems after permissions are granted
        _initializeSystems();
        break;
      case OnboardingStep.apiKey:
        nextStep = OnboardingStep.local;
        // Save API key immediately when moving from API key step
        _saveApiKeyToStorage();
        break;
      case OnboardingStep.local:
        nextStep = OnboardingStep.hotkeys;
        // Save local transcription settings when moving from local step
        _saveLocalTranscriptionSettings();
        break;
      case OnboardingStep.hotkeys:
        nextStep = OnboardingStep.testHotkeys;
        break;
      case OnboardingStep.testHotkeys:
        nextStep = OnboardingStep.preferences;
        break;
      case OnboardingStep.preferences:
        nextStep = OnboardingStep.completed;
        // Save settings when reaching the completed step
        _saveOnboardingSettings();
        AppStorage.setOnboardingCompleted(true);
        break;
      case OnboardingStep.completed:
        // Already at the last step
        return;
    }

    // Animate to the next page and update progress
    final progress = (nextStep.index) / (OnboardingStep.completed.index - 1);
    state.pageController?.animateToPage(
      nextStep.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    emit(state.copyWith(
      currentStep: nextStep,
      progressValue: progress,
    ));
  }

  void _onNavigateToPreviousStep(
    NavigateToPreviousStep event,
    Emitter<OnboardingState> emit,
  ) {
    final currentStep = state.currentStep;
    OnboardingStep previousStep;

    switch (currentStep) {
      case OnboardingStep.welcome:
        // Already at the first step
        return;
      case OnboardingStep.permissions:
        previousStep = OnboardingStep.welcome;
        break;
      case OnboardingStep.apiKey:
        previousStep = OnboardingStep.permissions;
        break;
      case OnboardingStep.local:
        previousStep = OnboardingStep.apiKey;
        break;
      case OnboardingStep.hotkeys:
        previousStep = OnboardingStep.local;
        break;
      case OnboardingStep.testHotkeys:
        previousStep = OnboardingStep.hotkeys;
        break;
      case OnboardingStep.preferences:
        previousStep = OnboardingStep.testHotkeys;
        break;
      case OnboardingStep.completed:
        previousStep = OnboardingStep.preferences;
        break;
    }

    // Animate to the previous page and update progress
    final progress =
        (previousStep.index) / (OnboardingStep.completed.index - 1);
    state.pageController?.animateToPage(
      previousStep.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    emit(state.copyWith(
      currentStep: previousStep,
      progressValue: progress,
    ));
  }

  // _onSkipOnboarding method removed as skipping is no longer allowed

  Future<void> _saveApiKeyToStorage() async {
    try {
      final settingsService = SettingsService();

      // Save API key immediately for testing
      if (state.apiKey.isNotEmpty &&
          state.apiKeyStatus == ApiKeyValidationStatus.valid) {
        await AppStorage.saveApiKey(state.apiKey);
        // Also save to settings service
        await settingsService.setApiKey(state.apiKey);

        if (kDebugMode) {
          print('API key saved to storage for testing');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving API key: $e');
      }
    }
  }

  Future<void> _saveOnboardingSettings() async {
    // Use the settings service for all settings
    final settingsService = SettingsService();

    // Save API key
    if (state.apiKey.isNotEmpty &&
        state.apiKeyStatus == ApiKeyValidationStatus.valid) {
      await AppStorage.saveApiKey(state.apiKey);
      // Also save to settings service
      await settingsService.setApiKey(state.apiKey);
    }

    // Save hotkeys - use direct Hive access to ensure they're saved correctly
    // Both transcription and assistant are always enabled now
    if (state.transcriptionHotkey != null) {
      // Save using both methods to ensure compatibility
      await settingsService.setTranscriptionHotkey(state.transcriptionHotkey!);

      // Save to Hive as a Map
      final hotkeyMap = state.transcriptionHotkey!.toJson();
      await AppStorage.settingsBox.put('transcription_hotkey', hotkeyMap);

      if (kDebugMode) {
        print('Saved transcription hotkey: $hotkeyMap');
      }
    }

    if (state.assistantHotkey != null) {
      // Save using both methods to ensure compatibility
      await settingsService.setAssistantHotkey(state.assistantHotkey!);

      // Save to Hive as a Map
      final hotkeyMap = state.assistantHotkey!.toJson();
      await AppStorage.settingsBox.put('assistant_hotkey', hotkeyMap);

      if (kDebugMode) {
        print('Saved assistant hotkey: $hotkeyMap');
      }
    }

    if (state.pushToTalkHotkey != null) {
      // Save to Hive as a Map
      final hotkeyMap = state.pushToTalkHotkey!.toJson();
      await AppStorage.settingsBox.put('push_to_talk_hotkey', hotkeyMap);

      if (kDebugMode) {
        print('Saved push-to-talk hotkey: $hotkeyMap');
      }
    }

    // Save theme preference
    await settingsService.setThemeMode(state.themeMode);
    await AppStorage.settingsBox.put(
        'theme_mode', state.themeMode == ThemeMode.light ? 'light' : 'dark');

    // Save auto-copy preference
    await settingsService.setAutoCopy(state.autoCopyEnabled);
    await AppStorage.settingsBox.put('auto_copy', state.autoCopyEnabled);

    // Save transcription model
    await settingsService.setTranscriptionModel(state.transcriptionModel);
    await AppStorage.settingsBox
        .put('transcription-model', state.transcriptionModel);

    // Save assistant screenshot preference
    await AppStorage.settingsBox
        .put('assistant_screenshot_enabled', state.assistantScreenshotEnabled);

    // Save smart transcription preference
    await AppStorage.settingsBox
        .put('smart_transcription_enabled', state.smartTranscriptionEnabled);

    // Add a longer delay to ensure all settings are written before navigation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _initializeSystems() async {
    try {
      if (kDebugMode) {
        print('Initializing systems after permissions granted...');
      }

      // Prepare hotkeys (read from storage into cache)
      await HotkeyHandler.prepareHotkeys();

      // Load and register stored hotkeys for immediate availability
      await HotkeyHandler.loadAndRegisterStoredHotkeys();

      // Initialize recording and transcription systems
      try {
        // Get repositories from dependency injection
        final recordingRepository = di.sl<RecordingRepository>();
        final transcriptionRepository = di.sl<TranscriptionRepository>();

        // Create blocs
        final recordingBloc = RecordingBloc(repository: recordingRepository);
        final transcriptionBloc = transcription_bloc.TranscriptionBloc(
          repository: transcriptionRepository,
        );

        // Initialize transcription bloc
        transcriptionBloc.add(transcription_bloc.InitializeTranscription());

        // Set up HotkeyHandler with blocs and repositories
        HotkeyHandler.setBlocs(
          recordingBloc,
          transcriptionBloc,
          recordingRepository,
          transcriptionRepository,
        );

        if (kDebugMode) {
          print('Recording and transcription systems initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing recording/transcription systems: $e');
        }
      }

      if (kDebugMode) {
        print('Systems initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing systems: $e');
      }
    }
  }

  // Local transcription event handlers
  Future<void> _onLoadLocalTranscriptionSettings(
    LoadLocalTranscriptionSettings event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      // Initialize WhisperKit service
      await WhisperKitService.initialize();

      // Load settings from Hive
      final settingsBox = Hive.box('settings');
      final localTranscriptionEnabled = settingsBox
          .get('local_transcription_enabled', defaultValue: false) as bool;
      final selectedLocalModel = settingsBox.get('selected_local_model',
          defaultValue: 'large-v3-v20240930_turbo_632MB') as String;

      // Load downloaded models
      final savedDownloadedModels =
          settingsBox.get('downloaded_models') as List<dynamic>?;
      final downloadedModels =
          savedDownloadedModels?.cast<String>() ?? <String>[];

      emit(state.copyWith(
        localTranscriptionEnabled: localTranscriptionEnabled,
        selectedLocalModel: selectedLocalModel,
        downloadedModels: downloadedModels,
      ));

      // Load current downloaded models from WhisperKit
      add(LoadDownloadedModels());
    } catch (e) {
      if (kDebugMode) {
        print('Error loading local transcription settings: $e');
      }
    }
  }

  Future<void> _onToggleLocalTranscription(
    ToggleLocalTranscription event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      final newValue = !state.localTranscriptionEnabled;

      // Save to Hive
      final settingsBox = Hive.box('settings');
      await settingsBox.put('local_transcription_enabled', newValue);

      emit(state.copyWith(localTranscriptionEnabled: newValue));

      if (kDebugMode) {
        print('Local transcription toggled to: $newValue');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling local transcription: $e');
      }
    }
  }

  Future<void> _onSelectLocalModel(
    SelectLocalModel event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      // Save to Hive
      final settingsBox = Hive.box('settings');
      await settingsBox.put('selected_local_model', event.modelName);

      emit(state.copyWith(selectedLocalModel: event.modelName));

      if (kDebugMode) {
        print('Selected local model: ${event.modelName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error selecting local model: $e');
      }
    }
  }

  Future<void> _onDownloadModel(
    DownloadModel event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      if (kDebugMode) {
        print('Starting download for model: ${event.modelName}');
      }

      // Clear any previous errors for this model
      final updatedErrors = Map<String, String>.from(state.modelDownloadErrors);
      updatedErrors.remove(event.modelName);

      // Initialize progress to show download started immediately
      final updatedProgress =
          Map<String, double>.from(state.modelDownloadProgress);
      updatedProgress[event.modelName] = 0.0;

      emit(state.copyWith(
        modelDownloadErrors: updatedErrors,
        modelDownloadProgress: updatedProgress,
      ));

      // Start the download and listen to progress
      await for (final progress
          in WhisperKitService.downloadModel(event.modelName)) {
        add(UpdateModelDownloadProgress(event.modelName, progress));

        if (progress >= 1.0) {
          add(ModelDownloadCompleted(event.modelName));
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading model ${event.modelName}: $e');
      }
      add(ModelDownloadFailed(event.modelName, e.toString()));
    }
  }

  void _onUpdateModelDownloadProgress(
    UpdateModelDownloadProgress event,
    Emitter<OnboardingState> emit,
  ) {
    final updatedProgress =
        Map<String, double>.from(state.modelDownloadProgress);
    updatedProgress[event.modelName] = event.progress;

    emit(state.copyWith(modelDownloadProgress: updatedProgress));

    if (kDebugMode) {
      print('Download progress for ${event.modelName}: ${event.progress}');
    }
  }

  void _onModelDownloadCompleted(
    ModelDownloadCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      // Remove from progress map
      final updatedProgress =
          Map<String, double>.from(state.modelDownloadProgress);
      updatedProgress.remove(event.modelName);

      // Add to downloaded models list
      final updatedDownloaded = List<String>.from(state.downloadedModels);
      if (!updatedDownloaded.contains(event.modelName)) {
        updatedDownloaded.add(event.modelName);
      }

      // Save to Hive
      final settingsBox = Hive.box('settings');
      await settingsBox.put('downloaded_models', updatedDownloaded);

      // If this is the first downloaded model and no model is selected, select it
      String newSelectedModel = state.selectedLocalModel;
      if (state.selectedLocalModel.isEmpty ||
          !updatedDownloaded.contains(state.selectedLocalModel)) {
        newSelectedModel = event.modelName;
        await settingsBox.put('selected_local_model', newSelectedModel);
      }

      emit(state.copyWith(
        modelDownloadProgress: updatedProgress,
        downloadedModels: updatedDownloaded,
        selectedLocalModel: newSelectedModel,
      ));

      if (kDebugMode) {
        print('Model download completed: ${event.modelName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling download completion: $e');
      }
    }
  }

  void _onModelDownloadFailed(
    ModelDownloadFailed event,
    Emitter<OnboardingState> emit,
  ) {
    // Remove from progress map
    final updatedProgress =
        Map<String, double>.from(state.modelDownloadProgress);
    updatedProgress.remove(event.modelName);

    // Add to errors map
    final updatedErrors = Map<String, String>.from(state.modelDownloadErrors);
    updatedErrors[event.modelName] = event.error;

    emit(state.copyWith(
      modelDownloadProgress: updatedProgress,
      modelDownloadErrors: updatedErrors,
    ));

    if (kDebugMode) {
      print('Model download failed for ${event.modelName}: ${event.error}');
    }
  }

  Future<void> _onLoadDownloadedModels(
    LoadDownloadedModels event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      // Get models from WhisperKit service
      final downloadedModels = await WhisperKitService.getDownloadedModels();

      // Load from Hive as fallback
      final settingsBox = Hive.box('settings');
      final savedModels =
          settingsBox.get('downloaded_models') as List<dynamic>?;
      final fallbackModels = savedModels?.cast<String>() ?? <String>[];

      // Combine and deduplicate
      final allModels =
          <String>{...downloadedModels, ...fallbackModels}.toList();

      // Save updated list to Hive
      await settingsBox.put('downloaded_models', allModels);

      emit(state.copyWith(downloadedModels: allModels));

      if (kDebugMode) {
        print('Loaded downloaded models: $allModels');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading downloaded models: $e');
      }
    }
  }

  Future<void> _saveLocalTranscriptionSettings() async {
    try {
      final settingsBox = Hive.box('settings');

      // Save local transcription settings
      await settingsBox.put(
          'local_transcription_enabled', state.localTranscriptionEnabled);
      await settingsBox.put('selected_local_model', state.selectedLocalModel);
      await settingsBox.put('downloaded_models', state.downloadedModels);

      if (kDebugMode) {
        print('Local transcription settings saved');
        print('Enabled: ${state.localTranscriptionEnabled}');
        print('Selected model: ${state.selectedLocalModel}');
        print('Downloaded models: ${state.downloadedModels}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving local transcription settings: $e');
      }
    }
  }
}
