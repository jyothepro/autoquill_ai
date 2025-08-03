import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_event.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_state.dart';

class MobileThemeSettingsSection extends StatelessWidget {
  const MobileThemeSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(DesignTokens.mobileSpaceSM),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(DesignTokens.mobileRadiusMD),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.mobileSpaceXS),
                    decoration: BoxDecoration(
                      gradient: DesignTokens.purpleGradient,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.mobileRadiusSM),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: DesignTokens.trueWhite,
                      size: DesignTokens.mobileIconSizeSM,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.mobileSpaceSM),
                  Text(
                    'Theme Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontSize: DesignTokens.mobileTitleLarge,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.mobileSpaceXS),
              Text(
                'Choose between light and dark mode.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontSize: DesignTokens.mobileBodyMedium,
                    ),
              ),
              const SizedBox(height: DesignTokens.mobileSpaceSM),

              // Theme toggle
              Container(
                padding: const EdgeInsets.all(DesignTokens.mobileSpaceSM),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? DesignTokens.darkSurface
                      : DesignTokens.lightSurface,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.mobileRadiusMD),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Theme.of(context).colorScheme.primary,
                          size: DesignTokens.mobileIconSizeMD,
                        ),
                        const SizedBox(width: DesignTokens.mobileSpaceSM),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark Mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: DesignTokens.fontWeightMedium,
                                    fontSize: DesignTokens.mobileTitleMedium,
                                  ),
                            ),
                            Text(
                              state.themeMode == ThemeMode.dark
                                  ? 'Enabled'
                                  : 'Disabled',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: DesignTokens.mobileCaptionSize,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: state.themeMode == ThemeMode.dark,
                      activeColor: DesignTokens.vibrantCoral,
                      onChanged: (_) {
                        context.read<SettingsBloc>().add(ToggleThemeMode());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
