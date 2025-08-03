import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import '../bloc/mobile_onboarding_bloc.dart';
import '../bloc/mobile_onboarding_event.dart';
import '../bloc/mobile_onboarding_state.dart';

class MobilePermissionsStep extends StatelessWidget {
  const MobilePermissionsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MobileOnboardingBloc, MobileOnboardingState>(
      listener: (context, state) {
        // Auto-check permissions when entering this step
        if (state.currentStep == MobileOnboardingStep.permissions) {
          context.read<MobileOnboardingBloc>().add(CheckPermissions());
        }
      },
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
                      const SizedBox(height: DesignTokens.spaceXL),

                      // Title
                      Center(
                        child: Text(
                          'Grant Permissions',
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
                          'AutoQuill needs these permissions to provide the best experience',
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
                      const SizedBox(height: DesignTokens.spaceXL),

                      // Permission cards
                      _buildPermissionCard(
                        context,
                        state: state,
                        permissionType: 'microphone',
                        icon: Icons.mic,
                        title: 'Microphone Access',
                        description:
                            'Required to record audio for transcription',
                        status: state.permissionStatuses['microphone'] ??
                            PermissionStatus.notDetermined,
                      ),
                      const SizedBox(height: DesignTokens.spaceXL),

                      // Success message
                      if (state.canProceedFromPermissions) ...[
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
                                  'All permissions granted! You can now continue.',
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
                      ] else ...[
                        // Info message
                        Container(
                          padding: const EdgeInsets.all(DesignTokens.spaceMD),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withValues(alpha: 0.3),
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMD),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: DesignTokens.iconSizeSM,
                                  ),
                                  const SizedBox(width: DesignTokens.spaceSM),
                                  Text(
                                    'Grant permissions to continue',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight:
                                              DesignTokens.fontWeightMedium,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DesignTokens.spaceXS),
                              Text(
                                'Tap "Grant Permission" on each card to allow access.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: DesignTokens.spaceMD),

                      // Refresh permissions button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context
                              .read<MobileOnboardingBloc>()
                              .add(CheckPermissions()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check Again'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: DesignTokens.spaceMD),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusMD),
                            ),
                          ),
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

  Widget _buildPermissionCard(
    BuildContext context, {
    required MobileOnboardingState state,
    required String permissionType,
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
  }) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;
    final String buttonText;
    final VoidCallback? onPressed;

    switch (status) {
      case PermissionStatus.authorized:
        statusColor = DesignTokens.emeraldGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Granted';
        buttonText = 'Granted';
        onPressed = null;
        break;
      case PermissionStatus.denied:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Denied';
        buttonText = 'Open Settings';
        onPressed = () {
          // TODO: Open app settings
        };
        break;
      case PermissionStatus.restricted:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'Restricted';
        buttonText = 'Open Settings';
        onPressed = () {
          // TODO: Open app settings
        };
        break;
      case PermissionStatus.notDetermined:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Not Granted';
        buttonText = 'Grant Permission';
        onPressed = () {
          context
              .read<MobileOnboardingBloc>()
              .add(RequestPermission(permissionType));
        };
        break;
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceSM),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: DesignTokens.iconSizeMD,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSM),
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
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: DesignTokens.spaceXS),
                        Text(
                          statusText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: DesignTokens.fontWeightMedium,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSM),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: DesignTokens.spaceMD),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: status == PermissionStatus.authorized
                    ? DesignTokens.emeraldGreen
                    : DesignTokens.vibrantCoral,
                foregroundColor: DesignTokens.trueWhite,
                padding:
                    const EdgeInsets.symmetric(vertical: DesignTokens.spaceSM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
