import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_event.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_state.dart';

class MobileTranscriptionModelsSection extends StatelessWidget {
  const MobileTranscriptionModelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
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
              // Section header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceXS),
                    decoration: BoxDecoration(
                      gradient: DesignTokens.blueGradient,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSM),
                    ),
                    child: Icon(
                      Icons.model_training,
                      color: DesignTokens.trueWhite,
                      size: DesignTokens.iconSizeSM,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceSM),
                  Text(
                    'Transcription Models',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceSM),
              Text(
                'Select the model to use for audio transcription.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: DesignTokens.spaceMD),

              // Model options
              _buildModelOption(
                context,
                'whisper-large-v3-turbo',
                'Whisper Large v3 Turbo',
                'Great balance between speed and accuracy',
                state.transcriptionModel == 'whisper-large-v3-turbo',
                onTap: () => _selectModel(context, 'whisper-large-v3-turbo'),
                isFirst: true,
              ),
              const Divider(height: 1),
              _buildModelOption(
                context,
                'whisper-large-v3',
                'Whisper Large v3',
                'Best for complex audio or multiple languages',
                state.transcriptionModel == 'whisper-large-v3',
                onTap: () => _selectModel(context, 'whisper-large-v3'),
              ),
              const Divider(height: 1),
              _buildModelOption(
                context,
                'distil-whisper-large-v3-en',
                'Distil Whisper (English)',
                'Best for quick transcriptions of English audio',
                state.transcriptionModel == 'distil-whisper-large-v3-en',
                onTap: () =>
                    _selectModel(context, 'distil-whisper-large-v3-en'),
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelOption(
    BuildContext context,
    String modelId,
    String title,
    String description,
    bool isSelected, {
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? Radius.circular(DesignTokens.radiusMD) : Radius.zero,
        bottom: isLast ? Radius.circular(DesignTokens.radiusMD) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.spaceMD,
          horizontal: DesignTokens.spaceSM,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: isSelected ? DesignTokens.vibrantCoral : null,
                        ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXXS),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            const SizedBox(width: DesignTokens.spaceSM),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.vibrantCoral
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesignTokens.vibrantCoral,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _selectModel(BuildContext context, String modelId) {
    context.read<SettingsBloc>().add(SaveTranscriptionModel(modelId));
  }
}
