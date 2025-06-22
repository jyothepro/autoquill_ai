import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../widgets/minimalist_card.dart';
import '../../../../widgets/minimalist_button.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

class PermissionsStep extends StatelessWidget {
  const PermissionsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        // Start permission checking when entering this step
        if (state.currentStep == OnboardingStep.permissions &&
            !state.isPermissionCheckingActive) {
          context.read<OnboardingBloc>().add(StartPeriodicPermissionCheck());
        }

        // Stop permission checking when leaving this step
        if (state.currentStep != OnboardingStep.permissions &&
            state.isPermissionCheckingActive) {
          context.read<OnboardingBloc>().add(StopPeriodicPermissionCheck());
        }
      },
      buildWhen: (previous, current) =>
          previous.permissionStatuses != current.permissionStatuses ||
          previous.pendingPermissions != current.pendingPermissions,
      builder: (context, state) {
        // Initialize permission checking and check permissions on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.currentStep == OnboardingStep.permissions) {
            context.read<OnboardingBloc>().add(CheckPermissions());
            if (!state.isPermissionCheckingActive) {
              context
                  .read<OnboardingBloc>()
                  .add(StartPeriodicPermissionCheck());
            }
          }
        });

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Grant Permissions',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceSM),

                // Description
                Text(
                  'AutoQuill needs these permissions to provide the best experience',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceLG),

                // Permission cards
                _buildPermissionCard(
                  context,
                  state: state,
                  permissionType: PermissionType.microphone,
                  icon: Icons.mic,
                  title: PermissionService.getPermissionTitle(
                      PermissionType.microphone),
                  description: PermissionService.getPermissionDescription(
                      PermissionType.microphone),
                  status: state.permissionStatuses[PermissionType.microphone] ??
                      PermissionStatus.notDetermined,
                  guidingText: (state
                              .permissionStatuses[PermissionType.microphone] ==
                          PermissionStatus.denied)
                      ? "Permission was denied. Go to System Preferences → Privacy & Security → Microphone → Enable AutoQuill"
                      : null,
                ),
                const SizedBox(height: DesignTokens.spaceMD),

                _buildPermissionCard(
                  context,
                  state: state,
                  permissionType: PermissionType.accessibility,
                  icon: Icons.accessibility,
                  title: PermissionService.getPermissionTitle(
                      PermissionType.accessibility),
                  description: PermissionService.getPermissionDescription(
                      PermissionType.accessibility),
                  status:
                      state.permissionStatuses[PermissionType.accessibility] ??
                          PermissionStatus.notDetermined,
                  guidingText:
                      "System Preferences → Privacy & Security → Accessibility → + (add app) → Select AutoQuill (in Applications) → Turn On → Close System Preferences",
                ),
                const SizedBox(height: DesignTokens.spaceMD),

                _buildPermissionCard(
                  context,
                  state: state,
                  permissionType: PermissionType.screenRecording,
                  icon: Icons.screen_share,
                  title: PermissionService.getPermissionTitle(
                      PermissionType.screenRecording),
                  description: PermissionService.getPermissionDescription(
                      PermissionType.screenRecording),
                  status: state
                          .permissionStatuses[PermissionType.screenRecording] ??
                      PermissionStatus.notDetermined,
                  guidingText:
                      "You might be prompted to restart the app after giving permission for screen recording. Please do so.",
                ),
                const SizedBox(height: DesignTokens.spaceLG),

                // All permissions granted message
                if (state.canProceedFromPermissions) ...[
                  MinimalistCard(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.1),
                    borderColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: DesignTokens.spaceSM),
                        Expanded(
                          child: Text(
                            'All permissions granted! You can now continue.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSM),
                ],

                // Help text for manual permission granting
                if (!state.canProceedFromPermissions) ...[
                  MinimalistCard(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withValues(alpha: 0.1),
                    borderColor: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: DesignTokens.spaceSM),
                            Expanded(
                              child: Text(
                                'Grant permissions and check again',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spaceXS),
                        Text(
                          'After granting permissions in System Preferences, return to this app and click "Check Permissions Again" to refresh the status.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMD),
                ],

                // Refresh permissions button
                Center(
                  child: MinimalistButton(
                    label: 'Check Permissions Again',
                    variant: MinimalistButtonVariant.secondary,
                    onPressed: () =>
                        context.read<OnboardingBloc>().add(CheckPermissions()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required OnboardingState state,
    required PermissionType permissionType,
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
    String? guidingText,
  }) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;
    final String buttonText;
    final VoidCallback? onPressed;

    // Check if this permission is pending
    final bool isPending = state.pendingPermissions.contains(permissionType);

    // Special handling for screen recording
    bool isScreenRecording = permissionType == PermissionType.screenRecording;
    String specialNote = '';

    switch (status) {
      case PermissionStatus.authorized:
        statusColor = Colors.green;
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
          context.read<OnboardingBloc>().add(
                OpenSystemPreferences(permissionType: permissionType),
              );
        };
        break;
      case PermissionStatus.restricted:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'Restricted';
        buttonText = 'Open Settings';
        onPressed = () {
          context.read<OnboardingBloc>().add(
                OpenSystemPreferences(permissionType: permissionType),
              );
        };
        break;
      case PermissionStatus.notDetermined:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Not Granted';

        // Special handling for accessibility permission
        if (permissionType == PermissionType.accessibility) {
          buttonText = isPending ? 'Opening Settings...' : 'Open Settings';
          onPressed = isPending
              ? null
              : () {
                  context.read<OnboardingBloc>().add(
                        AddPendingPermission(permissionType: permissionType),
                      );
                  context.read<OnboardingBloc>().add(
                        OpenSystemPreferences(permissionType: permissionType),
                      );
                };
        } else {
          // For microphone and screen recording - try to request permission first
          buttonText = isPending ? 'Requesting...' : 'Grant Permission';
          if (isScreenRecording) {
            specialNote =
                'Note: App will need to restart after granting this permission.';
          }
          onPressed = isPending
              ? null
              : () {
                  context.read<OnboardingBloc>().add(
                        AddPendingPermission(permissionType: permissionType),
                      );
                  context.read<OnboardingBloc>().add(
                        RequestPermission(permissionType: permissionType),
                      );
                };
        }
        break;
    }

    return MinimalistCard(
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
                  size: 24,
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
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.spaceXS),
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
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMD),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
          ),

          // Guiding text if provided
          if (guidingText != null) ...[
            const SizedBox(height: DesignTokens.spaceSM),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceSM),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: DesignTokens.spaceXS),
                  Expanded(
                    child: Text(
                      guidingText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Special note for screen recording
          if (specialNote.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spaceXS),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceSM),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: DesignTokens.spaceXS),
                  Expanded(
                    child: Text(
                      specialNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: DesignTokens.spaceMD),

          // Action button
          SizedBox(
            width: double.infinity,
            child: MinimalistButton(
              label: buttonText,
              variant: status == PermissionStatus.authorized
                  ? MinimalistButtonVariant.secondary
                  : MinimalistButtonVariant.primary,
              isDisabled: status == PermissionStatus.authorized,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
