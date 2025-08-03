import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/core/storage/app_storage.dart';
import '../bloc/mobile_onboarding_bloc.dart';
import '../bloc/mobile_onboarding_event.dart';
import '../bloc/mobile_onboarding_state.dart';
import '../widgets/mobile_permissions_step.dart';
import '../widgets/mobile_api_key_step.dart';
import '../widgets/mobile_local_models_step.dart';
import '../widgets/mobile_keyboard_extension_step.dart';
import '../widgets/mobile_theme_step.dart';
import 'mobile_main_layout.dart';

class MobileOnboardingPage extends StatelessWidget {
  const MobileOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MobileOnboardingBloc()..add(InitializeMobileOnboarding()),
      child: BlocConsumer<MobileOnboardingBloc, MobileOnboardingState>(
        listener: (context, state) {
          if (state.currentStep == MobileOnboardingStep.completed) {
            // Navigate to main layout
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MobileMainLayout()),
            );
          }
        },
        builder: (context, state) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignTokens.vibrantCoral.withValues(alpha: 0.1),
                    DesignTokens.deepBlue.withValues(alpha: 0.05),
                    isDarkMode
                        ? DesignTokens.pureBlack
                        : DesignTokens.trueWhite,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spaceMD),
                      child: Column(
                        children: [
                          // Progress bar
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusXS),
                              color: isDarkMode
                                  ? DesignTokens.darkSurfaceVariant
                                  : DesignTokens.lightSurfaceVariant,
                            ),
                            child: LinearProgressIndicator(
                              value: state.progressValue,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                DesignTokens.vibrantCoral,
                              ),
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusXS),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spaceSM),

                          // Step indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Step ${state.currentStep.index + 1} of ${MobileOnboardingStep.values.length - 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDarkMode
                                          ? DesignTokens.trueWhite
                                              .withValues(alpha: 0.7)
                                          : DesignTokens.pureBlack
                                              .withValues(alpha: 0.6),
                                      fontWeight: DesignTokens.fontWeightMedium,
                                    ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignTokens.spaceSM,
                                  vertical: DesignTokens.spaceXXS,
                                ),
                                decoration: BoxDecoration(
                                  gradient: DesignTokens.coralGradient,
                                  borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusSM),
                                ),
                                child: Text(
                                  _getStepName(state.currentStep),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: DesignTokens.trueWhite,
                                        fontWeight:
                                            DesignTokens.fontWeightMedium,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Page content
                    Expanded(
                      child: state.pageController != null
                          ? PageView(
                              controller: state.pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildWelcomeStep(context),
                                const MobilePermissionsStep(),
                                const MobileApiKeyStep(),
                                const MobileLocalModelsStep(),
                                const MobileKeyboardExtensionStep(),
                                const MobileThemeStep(),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),

                    // Navigation buttons
                    if (state.currentStep != MobileOnboardingStep.completed)
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.spaceMD),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            if (state.currentStep !=
                                MobileOnboardingStep.welcome)
                              TextButton.icon(
                                onPressed: () {
                                  context
                                      .read<MobileOnboardingBloc>()
                                      .add(NavigateToPreviousStep());
                                },
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back'),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: DesignTokens.spaceMD,
                                    vertical: DesignTokens.spaceSM,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 80),

                            // Next/Finish button
                            ElevatedButton(
                              onPressed: state.canProceedToNextStep
                                  ? () {
                                      if (state.currentStep ==
                                          MobileOnboardingStep.theme) {
                                        context
                                            .read<MobileOnboardingBloc>()
                                            .add(CompleteMobileOnboarding());
                                      } else {
                                        context
                                            .read<MobileOnboardingBloc>()
                                            .add(NavigateToNextStep());
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.vibrantCoral,
                                foregroundColor: DesignTokens.trueWhite,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignTokens.spaceLG,
                                  vertical: DesignTokens.spaceSM,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusMD),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    state.currentStep ==
                                            MobileOnboardingStep.theme
                                        ? 'Finish'
                                        : 'Next',
                                    style: const TextStyle(
                                      fontWeight:
                                          DesignTokens.fontWeightSemiBold,
                                    ),
                                  ),
                                  const SizedBox(width: DesignTokens.spaceXS),
                                  Icon(
                                    state.currentStep ==
                                            MobileOnboardingStep.theme
                                        ? Icons.check
                                        : Icons.arrow_forward,
                                    size: DesignTokens.iconSizeSM,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceLG),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: DesignTokens.spaceXXL),

                  // App logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: DesignTokens.coralGradient,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusLG),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 50,
                      color: DesignTokens.trueWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLG),

                  // Welcome title
                  Text(
                    'Welcome to AutoQuill',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceSM),

                  // Subtitle
                  Text(
                    'Your personal AI scribe and assistant',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceXS),

                  // Description
                  Text(
                    'Engineered for speed. Designed for trust. Free for life.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withValues(alpha: 0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceXXL),

                  // Features list
                  _buildFeatureItem(
                    context,
                    icon: Icons.mic,
                    title: 'Transcribe Audio',
                    description: 'Convert speech to clean text instantly',
                  ),
                  const SizedBox(height: DesignTokens.spaceLG),

                  _buildFeatureItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    title: 'AI Assistant',
                    description: 'Edit and generate text with AI',
                  ),
                  const SizedBox(height: DesignTokens.spaceLG),

                  _buildFeatureItem(
                    context,
                    icon: Icons.lock_outline,
                    title: 'No Login Required',
                    description: 'Use your own API key, no account needed',
                  ),
                  const SizedBox(height: DesignTokens.spaceXXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceSM),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: DesignTokens.iconSizeMD,
          ),
        ),
        const SizedBox(width: DesignTokens.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
              ),
              const SizedBox(height: DesignTokens.spaceXXS),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStepName(MobileOnboardingStep step) {
    switch (step) {
      case MobileOnboardingStep.welcome:
        return 'Welcome';
      case MobileOnboardingStep.permissions:
        return 'Permissions';
      case MobileOnboardingStep.apiKey:
        return 'API Setup';
      case MobileOnboardingStep.localModels:
        return 'Local Models';
      case MobileOnboardingStep.keyboardExtension:
        return 'Keyboard';
      case MobileOnboardingStep.theme:
        return 'Theme';
      case MobileOnboardingStep.completed:
        return 'Complete';
    }
  }
}
