import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import '../bloc/mobile_onboarding_bloc.dart';
import '../bloc/mobile_onboarding_event.dart';
import '../bloc/mobile_onboarding_state.dart';

class MobileLocalModelsStep extends StatelessWidget {
  const MobileLocalModelsStep({super.key});

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
                      const SizedBox(height: DesignTokens.spaceXL),

                      // Title
                      Center(
                        child: Text(
                          'Local Transcription',
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
                          'Use local models for transcription without internet connectivity. This is optional but provides offline functionality.',
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

                      // Local transcription toggle card
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.spaceMD),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMD),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                      DesignTokens.spaceXS),
                                  decoration: BoxDecoration(
                                    gradient: DesignTokens.purpleGradient,
                                    borderRadius: BorderRadius.circular(
                                        DesignTokens.radiusSM),
                                  ),
                                  child: Icon(
                                    Icons.computer_rounded,
                                    color: DesignTokens.trueWhite,
                                    size: DesignTokens.iconSizeSM,
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.spaceSM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enable Local Transcription',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: DesignTokens
                                                  .fontWeightSemiBold,
                                            ),
                                      ),
                                      const SizedBox(
                                          height: DesignTokens.spaceXS),
                                      Text(
                                        'Process transcriptions locally using downloaded models',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
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
                                const SizedBox(width: DesignTokens.spaceMD),
                                Switch(
                                  value: state.localTranscriptionEnabled,
                                  onChanged: (value) {
                                    context
                                        .read<MobileOnboardingBloc>()
                                        .add(ToggleLocalTranscription());
                                  },
                                  activeColor: DesignTokens.vibrantCoral,
                                ),
                              ],
                            ),
                            if (state.localTranscriptionEnabled) ...[
                              const SizedBox(height: DesignTokens.spaceLG),
                              _buildModelSelectionSection(context, state),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: DesignTokens.spaceMD),

                      // Skip section (when local transcription is disabled)
                      if (!state.localTranscriptionEnabled)
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
                                    'Skip for now',
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
                                'You can enable local transcription later in settings. The app will use cloud-based transcription for now.',
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
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelSelectionSection(
      BuildContext context, MobileOnboardingState state) {
    final models = [
      {
        'name': 'base',
        'displayName': 'Base',
        'size': '~150 MB',
        'description': 'Lightweight model for basic transcription',
        'recommended': false,
      },
      {
        'name': 'large-v3-turbo',
        'displayName': 'Turbo',
        'size': '~632 MB',
        'description': 'High-quality model optimized for speed',
        'recommended': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a Model',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
        ),
        const SizedBox(height: DesignTokens.spaceSM),
        Text(
          'Choose one model to download. We recommend starting with Turbo for the best balance of speed and accuracy.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: DesignTokens.spaceMD),

        // Model options
        Column(
          children: models.map((model) {
            final isSelected = state.selectedLocalModel == model['name'];
            final isDownloaded = state.downloadedModels.contains(model['name']);

            return Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.spaceXS),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.vibrantCoral.withValues(alpha: 0.5)
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? DesignTokens.vibrantCoral.withValues(alpha: 0.05)
                    : null,
              ),
              child: InkWell(
                onTap: () {
                  context
                      .read<MobileOnboardingBloc>()
                      .add(SelectLocalModel(model['name']! as String));
                },
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceMD),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: model['name']! as String,
                        groupValue: state.selectedLocalModel,
                        onChanged: (value) {
                          if (value != null) {
                            context
                                .read<MobileOnboardingBloc>()
                                .add(SelectLocalModel(value));
                          }
                        },
                        activeColor: DesignTokens.vibrantCoral,
                      ),
                      const SizedBox(width: DesignTokens.spaceSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  model['displayName']! as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight:
                                            DesignTokens.fontWeightMedium,
                                        color: isSelected
                                            ? DesignTokens.vibrantCoral
                                            : null,
                                      ),
                                ),
                                if (model['recommended'] == true) ...[
                                  const SizedBox(width: DesignTokens.spaceXS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: DesignTokens.spaceXS,
                                      vertical: DesignTokens.spaceXXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.emeraldGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          DesignTokens.radiusXS),
                                    ),
                                    child: Text(
                                      'RECOMMENDED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: DesignTokens.fontWeightBold,
                                        color: DesignTokens.emeraldGreen,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: DesignTokens.spaceXS),
                            Text(
                              model['description']! as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: DesignTokens.spaceXS),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: DesignTokens.iconSizeXS,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: DesignTokens.spaceXXS),
                                Text(
                                  model['size']! as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceMD),
                      _buildModelActionButton(
                          context, model['name']! as String, state),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModelActionButton(
    BuildContext context,
    String modelName,
    MobileOnboardingState state,
  ) {
    final isDownloaded = state.downloadedModels.contains(modelName);
    final isDownloading = state.modelDownloadProgress.containsKey(modelName);
    final downloadProgress = state.modelDownloadProgress[modelName] ?? 0.0;
    final hasError = state.modelDownloadErrors.containsKey(modelName);

    if (isDownloading) {
      // Show progress
      return Container(
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          color: DesignTokens.vibrantCoral.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: downloadProgress,
              strokeWidth: 2,
              backgroundColor: DesignTokens.vibrantCoral.withValues(alpha: 0.2),
              valueColor:
                  AlwaysStoppedAnimation<Color>(DesignTokens.vibrantCoral),
            ),
            Text(
              '${(downloadProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.vibrantCoral,
              ),
            ),
          ],
        ),
      );
    } else if (isDownloaded) {
      // Show downloaded
      return Container(
        decoration: BoxDecoration(
          color: DesignTokens.emeraldGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
        ),
        child: IconButton(
          onPressed: null,
          icon: Icon(
            Icons.check_circle_rounded,
            color: DesignTokens.emeraldGreen,
            size: DesignTokens.iconSizeSM,
          ),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      );
    } else {
      // Show download button
      return Container(
        decoration: BoxDecoration(
          color: hasError
              ? Colors.red.withValues(alpha: 0.1)
              : DesignTokens.vibrantCoral.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
        ),
        child: IconButton(
          onPressed: () {
            // TODO: Implement download functionality
          },
          icon: Icon(
            hasError ? Icons.error_rounded : Icons.download_rounded,
            color: hasError ? Colors.red : DesignTokens.vibrantCoral,
            size: DesignTokens.iconSizeSM,
          ),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      );
    }
  }
}
