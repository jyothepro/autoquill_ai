import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'mobile_onboarding_event.dart';

enum ApiKeyValidationStatus {
  initial,
  validating,
  valid,
  invalid,
}

enum PermissionStatus {
  notDetermined,
  authorized,
  denied,
  restricted,
}

class MobileOnboardingState extends Equatable {
  final MobileOnboardingStep currentStep;
  final PageController? pageController;
  final double progressValue;

  // API Key related
  final String apiKey;
  final bool isApiKeyVisible;
  final ApiKeyValidationStatus apiKeyStatus;

  // Permissions related
  final Map<String, PermissionStatus> permissionStatuses;
  final bool canProceedFromPermissions;

  // Local models related
  final bool localTranscriptionEnabled;
  final String selectedLocalModel;
  final List<String> downloadedModels;
  final Map<String, double> modelDownloadProgress;
  final Map<String, String> modelDownloadErrors;

  // Theme related
  final ThemeMode? selectedThemeMode;

  // General state
  final bool isLoading;
  final String? error;

  const MobileOnboardingState({
    this.currentStep = MobileOnboardingStep.welcome,
    this.pageController,
    this.progressValue = 0.0,
    this.apiKey = '',
    this.isApiKeyVisible = false,
    this.apiKeyStatus = ApiKeyValidationStatus.initial,
    this.permissionStatuses = const {},
    this.canProceedFromPermissions = false,
    this.localTranscriptionEnabled = false,
    this.selectedLocalModel = '',
    this.downloadedModels = const [],
    this.modelDownloadProgress = const {},
    this.modelDownloadErrors = const {},
    this.selectedThemeMode,
    this.isLoading = false,
    this.error,
  });

  MobileOnboardingState copyWith({
    MobileOnboardingStep? currentStep,
    PageController? pageController,
    double? progressValue,
    String? apiKey,
    bool? isApiKeyVisible,
    ApiKeyValidationStatus? apiKeyStatus,
    Map<String, PermissionStatus>? permissionStatuses,
    bool? canProceedFromPermissions,
    bool? localTranscriptionEnabled,
    String? selectedLocalModel,
    List<String>? downloadedModels,
    Map<String, double>? modelDownloadProgress,
    Map<String, String>? modelDownloadErrors,
    ThemeMode? selectedThemeMode,
    bool? isLoading,
    String? error,
  }) {
    return MobileOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      pageController: pageController ?? this.pageController,
      progressValue: progressValue ?? this.progressValue,
      apiKey: apiKey ?? this.apiKey,
      isApiKeyVisible: isApiKeyVisible ?? this.isApiKeyVisible,
      apiKeyStatus: apiKeyStatus ?? this.apiKeyStatus,
      permissionStatuses: permissionStatuses ?? this.permissionStatuses,
      canProceedFromPermissions:
          canProceedFromPermissions ?? this.canProceedFromPermissions,
      localTranscriptionEnabled:
          localTranscriptionEnabled ?? this.localTranscriptionEnabled,
      selectedLocalModel: selectedLocalModel ?? this.selectedLocalModel,
      downloadedModels: downloadedModels ?? this.downloadedModels,
      modelDownloadProgress:
          modelDownloadProgress ?? this.modelDownloadProgress,
      modelDownloadErrors: modelDownloadErrors ?? this.modelDownloadErrors,
      selectedThemeMode: selectedThemeMode ?? this.selectedThemeMode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get canProceedToNextStep {
    switch (currentStep) {
      case MobileOnboardingStep.welcome:
        return true;
      case MobileOnboardingStep.permissions:
        return true; // Allow proceeding without permissions for UI testing
      case MobileOnboardingStep.apiKey:
        return true; // Allow proceeding without API key validation for UI testing
      case MobileOnboardingStep.localModels:
        return true; // Optional step
      case MobileOnboardingStep.keyboardExtension:
        return true; // Instructions only
      case MobileOnboardingStep.theme:
        return true; // Allow proceeding without theme selection for UI testing
      case MobileOnboardingStep.completed:
        return false;
    }
  }

  @override
  List<Object?> get props => [
        currentStep,
        pageController,
        progressValue,
        apiKey,
        isApiKeyVisible,
        apiKeyStatus,
        permissionStatuses,
        canProceedFromPermissions,
        localTranscriptionEnabled,
        selectedLocalModel,
        downloadedModels,
        modelDownloadProgress,
        modelDownloadErrors,
        selectedThemeMode,
        isLoading,
        error,
      ];
}
