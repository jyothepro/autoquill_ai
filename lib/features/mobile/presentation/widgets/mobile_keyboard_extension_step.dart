import 'package:flutter/material.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';

class MobileKeyboardExtensionStep extends StatelessWidget {
  const MobileKeyboardExtensionStep({super.key});

  @override
  Widget build(BuildContext context) {
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
                      'Enable Custom Keyboard',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: DesignTokens.fontWeightBold,
                              ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSM),

                  // Description
                  Center(
                    child: Text(
                      'Enable AutoQuill\'s custom keyboard to access transcription features anywhere on your device',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXL),

                  // Benefits section
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceMD),
                    decoration: BoxDecoration(
                      color: DesignTokens.vibrantCoral.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMD),
                      border: Border.all(
                        color: DesignTokens.vibrantCoral.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.keyboard_alt_rounded,
                              color: DesignTokens.vibrantCoral,
                              size: DesignTokens.iconSizeMD,
                            ),
                            const SizedBox(width: DesignTokens.spaceSM),
                            Text(
                              'What you\'ll get:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: DesignTokens.fontWeightSemiBold,
                                    color: DesignTokens.vibrantCoral,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spaceMD),
                        _buildBenefitItem(
                            context, Icons.mic, 'Voice-to-text in any app'),
                        _buildBenefitItem(context, Icons.auto_awesome,
                            'AI-powered text editing'),
                        _buildBenefitItem(
                            context, Icons.translate, 'Multi-language support'),
                        _buildBenefitItem(context, Icons.offline_bolt,
                            'Works offline with local models'),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXL),

                  // Setup instructions
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
                              padding:
                                  const EdgeInsets.all(DesignTokens.spaceXS),
                              decoration: BoxDecoration(
                                gradient: DesignTokens.blueGradient,
                                borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusSM),
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                color: DesignTokens.trueWhite,
                                size: DesignTokens.iconSizeSM,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spaceSM),
                            Text(
                              'Setup Instructions',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: DesignTokens.fontWeightSemiBold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spaceMD),
                        _buildInstructionStep(
                          context,
                          1,
                          'Open Settings',
                          'Go to Settings > General > Keyboard',
                        ),
                        _buildInstructionStep(
                          context,
                          2,
                          'Add Keyboard',
                          'Tap "Keyboards" > "Add New Keyboard"',
                        ),
                        _buildInstructionStep(
                          context,
                          3,
                          'Select AutoQuill',
                          'Find and select "AutoQuill" from the list',
                        ),
                        _buildInstructionStep(
                          context,
                          4,
                          'Enable Full Access',
                          'Toggle "Allow Full Access" to enable all features',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMD),

                  // Open Settings button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Open iOS Settings app to keyboard section
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Open Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.vibrantCoral,
                        foregroundColor: DesignTokens.trueWhite,
                        padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.spaceMD),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMD),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMD),

                  // Skip note
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: DesignTokens.iconSizeSM,
                        ),
                        const SizedBox(width: DesignTokens.spaceSM),
                        Expanded(
                          child: Text(
                            'You can set this up later in the main app. The keyboard extension is optional but highly recommended for the best experience.',
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
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceXS),
      child: Row(
        children: [
          Icon(
            icon,
            color: DesignTokens.vibrantCoral,
            size: DesignTokens.iconSizeSM,
          ),
          const SizedBox(width: DesignTokens.spaceSM),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.vibrantCoral,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    int stepNumber,
    String title,
    String description, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : DesignTokens.spaceMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: DesignTokens.vibrantCoral,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: DesignTokens.trueWhite,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
              ),
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
    );
  }
}
