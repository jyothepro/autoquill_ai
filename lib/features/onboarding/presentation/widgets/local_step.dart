import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../widgets/minimalist_card.dart';
import '../../../../widgets/minimalist_button.dart';
import '../../../../core/services/whisper_kit_service.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

class LocalStep extends StatelessWidget {
  const LocalStep({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        // Initialize local transcription settings when entering this step
        if (state.currentStep == OnboardingStep.local) {
          context.read<OnboardingBloc>().add(LoadLocalTranscriptionSettings());
        }
      },
      buildWhen: (previous, current) =>
          previous.localTranscriptionEnabled !=
              current.localTranscriptionEnabled ||
          previous.selectedLocalModel != current.selectedLocalModel ||
          previous.downloadedModels != current.downloadedModels ||
          previous.modelDownloadProgress != current.modelDownloadProgress ||
          previous.modelDownloadErrors != current.modelDownloadErrors,
      builder: (context, state) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Local Transcription',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceSM),

                // Description
                Text(
                  'Use local models for transcription without internet connectivity. This is optional but provides offline functionality.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spaceLG),

                // Local transcription toggle
                MinimalistCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(DesignTokens.spaceXS),
                            decoration: BoxDecoration(
                              gradient: DesignTokens.purpleGradient,
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusSM),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Local Transcription',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight:
                                            DesignTokens.fontWeightSemiBold,
                                      ),
                                ),
                                const SizedBox(height: DesignTokens.spaceXS),
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
                                  .read<OnboardingBloc>()
                                  .add(ToggleLocalTranscription());
                            },
                            activeColor: DesignTokens.vibrantCoral,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      if (state.localTranscriptionEnabled) ...[
                        const SizedBox(height: DesignTokens.spaceLG),
                        _buildModelSelectionSection(context, state, isDarkMode),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: DesignTokens.spaceMD),

                // Skip local transcription option
                if (!state.localTranscriptionEnabled)
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
                                'Skip for now',
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
                          'You can enable local transcription later in settings. The app will use cloud-based transcription for now.',
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelSelectionSection(
      BuildContext context, OnboardingState state, bool isDarkMode) {
    final models = [
      {
        'name': 'large-v3-v20240930_turbo_632MB',
        'size': '~632 MB',
        'description': 'Very high accuracy, high speed'
      },
      {
        'name': 'large-v3_947MB',
        'size': '~947 MB',
        'description': 'Highest accuracy, slowest speed'
      },
      {
        'name': 'medium',
        'size': '~1.5 GB',
        'description': 'Medium accuracy, medium speed'
      },
      {
        'name': 'small_216MB',
        'size': '~216 MB',
        'description': 'Low accuracy, fast speed'
      },
      {
        'name': 'base',
        'size': '~150 MB',
        'description': 'Lowest accuracy, fastest speed'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select and Download a Model',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDarkMode
                    ? DesignTokens.trueWhite
                    : DesignTokens.pureBlack,
              ),
        ),
        const SizedBox(height: DesignTokens.spaceSM),
        Text(
          'Choose one model to download. We recommend starting with Turbo for the best balance of speed and accuracy.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode
                    ? DesignTokens.trueWhite.withValues(alpha: 0.7)
                    : DesignTokens.pureBlack.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: DesignTokens.spaceMD),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? DesignTokens.trueWhite.withValues(alpha: 0.03)
                : DesignTokens.pureBlack.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
          ),
          child: Column(
            children: models.map((model) {
              final isSelected = state.selectedLocalModel == model['name'];
              final isDownloaded =
                  state.downloadedModels.contains(model['name']);
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode
                          ? DesignTokens.trueWhite.withValues(alpha: 0.05)
                          : DesignTokens.pureBlack.withValues(alpha: 0.03),
                      width: models.last == model ? 0 : 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceMD),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: model['name']!,
                        groupValue: state.selectedLocalModel,
                        onChanged: isDownloaded
                            ? (value) {
                                if (value != null) {
                                  context
                                      .read<OnboardingBloc>()
                                      .add(SelectLocalModel(value));
                                }
                              }
                            : null,
                        activeColor: DesignTokens.vibrantCoral,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: DesignTokens.spaceSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDisplayName(model['name']!),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: DesignTokens.fontWeightMedium,
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                        : DesignTokens.pureBlack,
                                  ),
                            ),
                            const SizedBox(height: DesignTokens.spaceXXS),
                            Text(
                              '${model['size']} • ${model['description']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                            .withValues(alpha: 0.6)
                                        : DesignTokens.pureBlack
                                            .withValues(alpha: 0.5),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spaceMD),
                      _buildModelActionButton(
                          context, model['name']!, state, isDarkMode),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMD),
        _buildOpenModelsDirectoryButton(context, isDarkMode),
        if (state.modelDownloadErrors.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spaceSM),
          _buildHelpSection(context, state, isDarkMode),
        ],
      ],
    );
  }

  /// Maps display names to actual model names
  String _getDisplayName(String modelName) {
    switch (modelName) {
      case 'base':
        return 'base';
      case 'small_216MB':
        return 'small';
      case 'medium':
        return 'medium';
      case 'large-v3_947MB':
        return 'large';
      case 'large-v3-v20240930_turbo_632MB':
        return 'turbo (recommended)';
      default:
        return modelName.toUpperCase();
    }
  }

  Widget _buildModelActionButton(BuildContext context, String modelName,
      OnboardingState state, bool isDarkMode) {
    final isDownloaded = state.downloadedModels.contains(modelName);
    final isDownloading = state.modelDownloadProgress.containsKey(modelName);
    final downloadProgress = state.modelDownloadProgress[modelName] ?? 0.0;
    final hasError = state.modelDownloadErrors.containsKey(modelName);

    if (isDownloading) {
      // Show progress indicator
      return Container(
        decoration: BoxDecoration(
          color: DesignTokens.vibrantCoral.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
        ),
        width: 60,
        height: 32,
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
      // Show downloaded indicator
      return Container(
        decoration: BoxDecoration(
          color: DesignTokens.emeraldGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
        ),
        child: IconButton(
          onPressed: null, // Just shows status
          icon: Icon(
            Icons.check_circle_rounded,
            color: DesignTokens.emeraldGreen,
            size: DesignTokens.iconSizeSM,
          ),
          iconSize: DesignTokens.iconSizeSM,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          padding: const EdgeInsets.all(DesignTokens.spaceXS),
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
            context.read<OnboardingBloc>().add(DownloadModel(modelName));
          },
          icon: Icon(
            hasError ? Icons.error_rounded : Icons.download_rounded,
            color: hasError ? Colors.red : DesignTokens.vibrantCoral,
            size: DesignTokens.iconSizeSM,
          ),
          iconSize: DesignTokens.iconSizeSM,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          padding: const EdgeInsets.all(DesignTokens.spaceXS),
        ),
      );
    }
  }

  Widget _buildOpenModelsDirectoryButton(
      BuildContext context, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: MinimalistButton(
        label: 'Open Models Folder',
        variant: MinimalistButtonVariant.secondary,
        onPressed: () => _openModelsDirectory(context),
        icon: Icons.folder_open_rounded,
      ),
    );
  }

  Widget _buildHelpSection(
      BuildContext context, OnboardingState state, bool isDarkMode) {
    // Check if there are any download errors
    final hasDownloadErrors = state.modelDownloadErrors.isNotEmpty;
    final hasAuthErrors = state.modelDownloadErrors.values.any((error) =>
        error.toLowerCase().contains('authorization') ||
        error.toLowerCase().contains('authorizationrequired'));

    if (!hasDownloadErrors) return const SizedBox.shrink();

    return MinimalistCard(
      backgroundColor: hasAuthErrors
          ? Colors.orange.withValues(alpha: 0.1)
          : Colors.blue.withValues(alpha: 0.1),
      borderColor: hasAuthErrors
          ? Colors.orange.withValues(alpha: 0.3)
          : Colors.blue.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAuthErrors
                    ? Icons.warning_rounded
                    : Icons.help_outline_rounded,
                color: hasAuthErrors ? Colors.orange : Colors.blue,
                size: DesignTokens.iconSizeSM,
              ),
              const SizedBox(width: DesignTokens.spaceXS),
              Text(
                hasAuthErrors ? 'Download Issue' : 'Download Help',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: hasAuthErrors ? Colors.orange : Colors.blue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceXS),
          Text(
            hasAuthErrors
                ? 'Model downloads require authentication. You can skip this step and set up local models later in settings.'
                : 'Having trouble downloading models? You can skip this step and configure local transcription later.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? DesignTokens.trueWhite.withValues(alpha: 0.8)
                      : DesignTokens.pureBlack.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  void _openModelsDirectory(BuildContext context) async {
    try {
      final success = await WhisperKitService.openModelsDirectory();

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open models folder'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening models folder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
