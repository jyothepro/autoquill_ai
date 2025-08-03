import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class MobileOnboardingEvent extends Equatable {
  const MobileOnboardingEvent();

  @override
  List<Object?> get props => [];
}

// Navigation events
class InitializeMobileOnboarding extends MobileOnboardingEvent {}

class NavigateToNextStep extends MobileOnboardingEvent {}

class NavigateToPreviousStep extends MobileOnboardingEvent {}

class NavigateToStep extends MobileOnboardingEvent {
  final MobileOnboardingStep step;

  const NavigateToStep(this.step);

  @override
  List<Object?> get props => [step];
}

// API Key events
class UpdateApiKey extends MobileOnboardingEvent {
  final String apiKey;

  const UpdateApiKey(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}

class ToggleApiKeyVisibility extends MobileOnboardingEvent {}

class ValidateApiKey extends MobileOnboardingEvent {}

class ClearApiKey extends MobileOnboardingEvent {}

// Permission events
class CheckPermissions extends MobileOnboardingEvent {}

class RequestPermission extends MobileOnboardingEvent {
  final String permissionType;

  const RequestPermission(this.permissionType);

  @override
  List<Object?> get props => [permissionType];
}

// Local models events
class ToggleLocalTranscription extends MobileOnboardingEvent {}

class SelectLocalModel extends MobileOnboardingEvent {
  final String modelName;

  const SelectLocalModel(this.modelName);

  @override
  List<Object?> get props => [modelName];
}

// Theme events
class SelectTheme extends MobileOnboardingEvent {
  final ThemeMode themeMode;

  const SelectTheme(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

// Completion events
class CompleteMobileOnboarding extends MobileOnboardingEvent {}

// Define onboarding steps
enum MobileOnboardingStep {
  welcome,
  permissions,
  apiKey,
  localModels,
  keyboardExtension,
  theme,
  completed,
}
