import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_state.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_event.dart';

class MobileLocalModelsSection extends StatelessWidget {
  const MobileLocalModelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.mobileSpaceXS),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.blueGradient,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.mobileRadiusSM),
                  ),
                  child: Icon(
                    Icons.storage_rounded,
                    color: DesignTokens.trueWhite,
                    size: DesignTokens.mobileIconSizeSM,
                  ),
                ),
                const SizedBox(width: DesignTokens.mobileSpaceSM),
                Text(
                  'Local Models',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontSize: DesignTokens.mobileTitleLarge,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.mobileSpaceSM),

            // Description
            Text(
              'Download models for offline transcription',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontSize: DesignTokens.mobileBodyMedium,
                  ),
            ),
            const SizedBox(height: DesignTokens.mobileSpaceMD),

            // Local transcription toggle
            Container(
              padding: const EdgeInsets.all(DesignTokens.mobileSpaceSM),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? DesignTokens.darkSurface
                    : DesignTokens.lightSurface,
                borderRadius:
                    BorderRadius.circular(DesignTokens.mobileRadiusMD),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_download_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: DesignTokens.mobileIconSizeMD,
                          ),
                          const SizedBox(width: DesignTokens.mobileSpaceSM),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Local Transcription',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: DesignTokens.fontWeightMedium,
                                      fontSize: DesignTokens.mobileTitleMedium,
                                    ),
                              ),
                              Text(
                                state.localTranscriptionEnabled
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
                        value: state.localTranscriptionEnabled,
                        onChanged: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(ToggleLocalTranscription());
                        },
                        activeColor: DesignTokens.vibrantCoral,
                      ),
                    ],
                  ),

                  // Model selection (when enabled)
                  if (state.localTranscriptionEnabled) ...[
                    const SizedBox(height: DesignTokens.mobileSpaceMD),
                    _buildModelSelection(context, state),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelSelection(BuildContext context, SettingsState state) {
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
          'Selected Model',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.mobileTitleMedium,
              ),
        ),
        const SizedBox(height: DesignTokens.mobileSpaceXS),

        // Model options
        Column(
          children: models.map((model) {
            final isSelected = state.selectedLocalModel == model['name'];

            return Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.mobileSpaceXS),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(DesignTokens.mobileRadiusSM),
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
                      .read<SettingsBloc>()
                      .add(SelectLocalModel(model['name']! as String));
                },
                borderRadius:
                    BorderRadius.circular(DesignTokens.mobileRadiusSM),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.mobileSpaceSM),
                  child: Row(
                    children: [
                      // Radio button
                      Container(
                        width: 16,
                        height: 16,
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
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: DesignTokens.vibrantCoral,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: DesignTokens.mobileSpaceXS),

                      // Model info
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
                                        fontSize:
                                            DesignTokens.mobileTitleMedium,
                                        color: isSelected
                                            ? DesignTokens.vibrantCoral
                                            : null,
                                      ),
                                ),
                                if (model['recommended'] == true) ...[
                                  const SizedBox(
                                      width: DesignTokens.mobileSpaceXS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: DesignTokens.mobileSpaceXS,
                                      vertical: DesignTokens.mobileSpaceXXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.emeraldGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          DesignTokens.mobileRadiusXS),
                                    ),
                                    child: Text(
                                      'RECOMMENDED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: DesignTokens.fontWeightBold,
                                        color: DesignTokens.emeraldGreen,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: DesignTokens.mobileSpaceXXS),
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
                                    fontSize: DesignTokens.mobileBodyMedium,
                                  ),
                            ),
                            const SizedBox(height: DesignTokens.mobileSpaceXXS),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: DesignTokens.mobileIconSizeXS,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(
                                    width: DesignTokens.mobileSpaceXXS),
                                Text(
                                  model['size']! as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 10,
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

                      // Action button
                      const SizedBox(width: DesignTokens.mobileSpaceSM),
                      _buildModelActionButton(
                          context, model['name']! as String),
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

  Widget _buildModelActionButton(BuildContext context, String modelName) {
    // For UI purposes, showing download button
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: DesignTokens.vibrantCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.mobileRadiusXS),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Start download
        },
        borderRadius: BorderRadius.circular(DesignTokens.mobileRadiusXS),
        child: Icon(
          Icons.download_rounded,
          color: DesignTokens.vibrantCoral,
          size: DesignTokens.mobileIconSizeSM,
        ),
      ),
    );
  }
}
