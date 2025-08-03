import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/storage/app_storage.dart';
import 'mobile_onboarding_event.dart';
import 'mobile_onboarding_state.dart';

class MobileOnboardingBloc
    extends Bloc<MobileOnboardingEvent, MobileOnboardingState> {
  PageController? _pageController;

  MobileOnboardingBloc() : super(const MobileOnboardingState()) {
    on<InitializeMobileOnboarding>(_onInitializeMobileOnboarding);
    on<NavigateToNextStep>(_onNavigateToNextStep);
    on<NavigateToPreviousStep>(_onNavigateToPreviousStep);
    on<NavigateToStep>(_onNavigateToStep);

    // API Key events
    on<UpdateApiKey>(_onUpdateApiKey);
    on<ToggleApiKeyVisibility>(_onToggleApiKeyVisibility);
    on<ValidateApiKey>(_onValidateApiKey);
    on<ClearApiKey>(_onClearApiKey);

    // Permission events
    on<CheckPermissions>(_onCheckPermissions);
    on<RequestPermission>(_onRequestPermission);

    // Local models events
    on<ToggleLocalTranscription>(_onToggleLocalTranscription);
    on<SelectLocalModel>(_onSelectLocalModel);

    // Theme events
    on<SelectTheme>(_onSelectTheme);

    // Completion events
    on<CompleteMobileOnboarding>(_onCompleteMobileOnboarding);
  }

  @override
  Future<void> close() {
    _pageController?.dispose();
    return super.close();
  }

  void _onInitializeMobileOnboarding(
    InitializeMobileOnboarding event,
    Emitter<MobileOnboardingState> emit,
  ) {
    _pageController = PageController();
    emit(state.copyWith(
      pageController: _pageController,
      progressValue: _calculateProgress(MobileOnboardingStep.welcome),
    ));
  }

  void _onNavigateToNextStep(
    NavigateToNextStep event,
    Emitter<MobileOnboardingState> emit,
  ) {
    if (!state.canProceedToNextStep) return;

    final nextStep = _getNextStep(state.currentStep);
    if (nextStep != null) {
      _navigateToStep(nextStep, emit);
    }
  }

  void _onNavigateToPreviousStep(
    NavigateToPreviousStep event,
    Emitter<MobileOnboardingState> emit,
  ) {
    final previousStep = _getPreviousStep(state.currentStep);
    if (previousStep != null) {
      _navigateToStep(previousStep, emit);
    }
  }

  void _onNavigateToStep(
    NavigateToStep event,
    Emitter<MobileOnboardingState> emit,
  ) {
    _navigateToStep(event.step, emit);
  }

  void _navigateToStep(
      MobileOnboardingStep step, Emitter<MobileOnboardingState> emit) {
    final index = step.index;
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    emit(state.copyWith(
      currentStep: step,
      progressValue: _calculateProgress(step),
    ));
  }

  void _onUpdateApiKey(
    UpdateApiKey event,
    Emitter<MobileOnboardingState> emit,
  ) {
    emit(state.copyWith(
      apiKey: event.apiKey,
      apiKeyStatus: ApiKeyValidationStatus.initial,
    ));
  }

  void _onToggleApiKeyVisibility(
    ToggleApiKeyVisibility event,
    Emitter<MobileOnboardingState> emit,
  ) {
    emit(state.copyWith(
      isApiKeyVisible: !state.isApiKeyVisible,
    ));
  }

  Future<void> _onValidateApiKey(
    ValidateApiKey event,
    Emitter<MobileOnboardingState> emit,
  ) async {
    if (state.apiKey.isEmpty) return;

    emit(state.copyWith(apiKeyStatus: ApiKeyValidationStatus.validating));

    // Simulate API key validation (replace with actual validation)
    await Future.delayed(const Duration(seconds: 1));

    // For now, just check if it's not empty and has a reasonable length
    final isValid = state.apiKey.length > 10;

    emit(state.copyWith(
      apiKeyStatus: isValid
          ? ApiKeyValidationStatus.valid
          : ApiKeyValidationStatus.invalid,
    ));

    // Save API key if valid
    if (isValid) {
      await AppStorage.saveApiKey(state.apiKey);
    }
  }

  void _onClearApiKey(
    ClearApiKey event,
    Emitter<MobileOnboardingState> emit,
  ) {
    emit(state.copyWith(
      apiKey: '',
      apiKeyStatus: ApiKeyValidationStatus.initial,
    ));
  }

  Future<void> _onCheckPermissions(
    CheckPermissions event,
    Emitter<MobileOnboardingState> emit,
  ) async {
    // Simulate permission checking (replace with actual permission service)
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock permission statuses
    final mockPermissions = {
      'microphone': PermissionStatus.notDetermined,
    };

    final canProceed = mockPermissions.values
        .every((status) => status == PermissionStatus.authorized);

    emit(state.copyWith(
      permissionStatuses: mockPermissions,
      canProceedFromPermissions: canProceed,
    ));
  }

  Future<void> _onRequestPermission(
    RequestPermission event,
    Emitter<MobileOnboardingState> emit,
  ) async {
    // Simulate permission request (replace with actual permission service)
    await Future.delayed(const Duration(seconds: 1));

    final updatedPermissions =
        Map<String, PermissionStatus>.from(state.permissionStatuses);
    updatedPermissions[event.permissionType] = PermissionStatus.authorized;

    final canProceed = updatedPermissions.values
        .every((status) => status == PermissionStatus.authorized);

    emit(state.copyWith(
      permissionStatuses: updatedPermissions,
      canProceedFromPermissions: canProceed,
    ));
  }

  void _onToggleLocalTranscription(
    ToggleLocalTranscription event,
    Emitter<MobileOnboardingState> emit,
  ) {
    emit(state.copyWith(
      localTranscriptionEnabled: !state.localTranscriptionEnabled,
    ));
  }

  void _onSelectLocalModel(
    SelectLocalModel event,
    Emitter<MobileOnboardingState> emit,
  ) {
    emit(state.copyWith(
      selectedLocalModel: event.modelName,
    ));
  }

  Future<void> _onSelectTheme(
    SelectTheme event,
    Emitter<MobileOnboardingState> emit,
  ) async {
    emit(state.copyWith(
      selectedThemeMode: event.themeMode,
    ));

    // Apply theme immediately
    await AppStorage.settingsBox.put(
        'theme_mode', event.themeMode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> _onCompleteMobileOnboarding(
    CompleteMobileOnboarding event,
    Emitter<MobileOnboardingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Save onboarding completion status
    await AppStorage.setOnboardingCompleted(true);

    emit(state.copyWith(
      currentStep: MobileOnboardingStep.completed,
      isLoading: false,
    ));
  }

  MobileOnboardingStep? _getNextStep(MobileOnboardingStep currentStep) {
    final currentIndex = currentStep.index;
    if (currentIndex < MobileOnboardingStep.values.length - 1) {
      return MobileOnboardingStep.values[currentIndex + 1];
    }
    return null;
  }

  MobileOnboardingStep? _getPreviousStep(MobileOnboardingStep currentStep) {
    final currentIndex = currentStep.index;
    if (currentIndex > 0) {
      return MobileOnboardingStep.values[currentIndex - 1];
    }
    return null;
  }

  double _calculateProgress(MobileOnboardingStep step) {
    // Don't include completed step in progress calculation
    final totalSteps = MobileOnboardingStep.values.length - 1;
    return (step.index + 1) / totalSteps;
  }
}
