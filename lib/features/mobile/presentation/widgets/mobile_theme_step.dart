import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import '../bloc/mobile_onboarding_bloc.dart';
import '../bloc/mobile_onboarding_event.dart';
import '../bloc/mobile_onboarding_state.dart';

class MobileThemeStep extends StatelessWidget {
  const MobileThemeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MobileOnboardingBloc, MobileOnboardingState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLG),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: DesignTokens.spaceXXL),

                      // Title
                      Center(
                        child: Text(
                          'Choose Your Theme',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: DesignTokens.fontWeightBold,
                              ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceSM),

                      // Description
                      Center(
                        child: Text(
                          'Select your preferred appearance. You can change this anytime in settings.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceXXL),

                      // Theme options
                      Column(
                        children: [
                          // Light mode option
                          _buildThemeOption(
                            context,
                            state,
                            themeMode: ThemeMode.light,
                            title: 'Light Mode',
                            description: 'Clean and bright interface',
                            icon: Icons.light_mode,
                            previewGradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey[50]!,
                                Colors.grey[100]!,
                              ],
                            ),
                            iconColor: Colors.orange,
                          ),
                          const SizedBox(height: DesignTokens.spaceMD),

                          // Dark mode option
                          _buildThemeOption(
                            context,
                            state,
                            themeMode: ThemeMode.dark,
                            title: 'Dark Mode',
                            description: 'Easy on the eyes in low light',
                            icon: Icons.dark_mode,
                            previewGradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey[900]!,
                                Colors.black,
                              ],
                            ),
                            iconColor: Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spaceXXL),

                      // Current selection indicator
                      if (state.selectedThemeMode != null)
                        Container(
                          padding: const EdgeInsets.all(DesignTokens.spaceMD),
                          decoration: BoxDecoration(
                            color: DesignTokens.emeraldGreen
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMD),
                            border: Border.all(
                              color: DesignTokens.emeraldGreen
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: DesignTokens.emeraldGreen,
                                size: DesignTokens.iconSizeMD,
                              ),
                              const SizedBox(width: DesignTokens.spaceSM),
                              Expanded(
                                child: Text(
                                  '${state.selectedThemeMode == ThemeMode.light ? 'Light' : 'Dark'} mode selected! The theme will be applied when you complete onboarding.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: DesignTokens.emeraldGreen,
                                        fontWeight:
                                            DesignTokens.fontWeightMedium,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    MobileOnboardingState state, {
    required ThemeMode themeMode,
    required String title,
    required String description,
    required IconData icon,
    required Gradient previewGradient,
    required Color iconColor,
  }) {
    final isSelected = state.selectedThemeMode == themeMode;

    return GestureDetector(
      onTap: () {
        context.read<MobileOnboardingBloc>().add(SelectTheme(themeMode));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(DesignTokens.spaceMD),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          border: Border.all(
            color: isSelected
                ? DesignTokens.vibrantCoral
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: DesignTokens.vibrantCoral.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Theme preview
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: previewGradient,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: DesignTokens.iconSizeLG,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceMD),

            // Theme info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: isSelected ? DesignTokens.vibrantCoral : null,
                        ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXS),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? DesignTokens.vibrantCoral
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.vibrantCoral
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
                color:
                    isSelected ? DesignTokens.vibrantCoral : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: DesignTokens.trueWhite,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
