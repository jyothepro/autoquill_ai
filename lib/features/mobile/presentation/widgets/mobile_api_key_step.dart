import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../bloc/mobile_onboarding_bloc.dart';
import '../bloc/mobile_onboarding_event.dart';
import '../bloc/mobile_onboarding_state.dart';

class MobileApiKeyStep extends StatefulWidget {
  const MobileApiKeyStep({super.key});

  @override
  State<MobileApiKeyStep> createState() => _MobileApiKeyStepState();
}

class _MobileApiKeyStepState extends State<MobileApiKeyStep> {
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MobileOnboardingBloc, MobileOnboardingState>(
      listener: (context, state) {
        // Update text field when state changes
        if (_apiKeyController.text != state.apiKey) {
          _apiKeyController.text = state.apiKey;
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(DesignTokens.mobileSpaceSM),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: DesignTokens.mobileSpaceLG),

                      // Title
                      Center(
                        child: Text(
                          'Connect to Groq',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: DesignTokens.fontWeightBold,
                                fontSize: DesignTokens.mobileHeadlineMedium,
                              ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.mobileSpaceXS),

                      // Description
                      Center(
                        child: Text(
                          'Enter your Groq API key to power AutoQuill',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: DesignTokens.mobileBodyMedium,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.mobileSpaceLG),

                      // API Key input section
                      Container(
                        padding:
                            const EdgeInsets.all(DesignTokens.mobileSpaceSM),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                              DesignTokens.mobileRadiusMD),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Groq API Key',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: DesignTokens.fontWeightSemiBold,
                                    fontSize: DesignTokens.mobileTitleMedium,
                                  ),
                            ),
                            const SizedBox(height: DesignTokens.mobileSpaceXS),

                            // API Key input field
                            TextField(
                              controller: _apiKeyController,
                              obscureText: !state.isApiKeyVisible,
                              decoration: InputDecoration(
                                hintText: 'Enter your Groq API key',
                                prefixIcon: const Icon(Icons.vpn_key),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Toggle visibility
                                    IconButton(
                                      icon: Icon(
                                        state.isApiKeyVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        context
                                            .read<MobileOnboardingBloc>()
                                            .add(ToggleApiKeyVisibility());
                                      },
                                    ),
                                    // Clear button
                                    if (_apiKeyController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _apiKeyController.clear();
                                          context
                                              .read<MobileOnboardingBloc>()
                                              .add(const UpdateApiKey(''));
                                        },
                                      ),
                                  ],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      DesignTokens.mobileRadiusMD),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: DesignTokens.mobileSpaceSM,
                                  vertical: DesignTokens.mobileSpaceSM,
                                ),
                              ),
                              onChanged: (value) {
                                context
                                    .read<MobileOnboardingBloc>()
                                    .add(UpdateApiKey(value));
                              },
                            ),
                            const SizedBox(height: DesignTokens.mobileSpaceXS),

                            // Validation status
                            _buildValidationStatus(context, state),
                            const SizedBox(height: DesignTokens.mobileSpaceSM),

                            // Validate button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: state.apiKeyStatus !=
                                            ApiKeyValidationStatus.validating &&
                                        _apiKeyController.text.isNotEmpty
                                    ? () {
                                        context
                                            .read<MobileOnboardingBloc>()
                                            .add(ValidateApiKey());
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignTokens.vibrantCoral,
                                  foregroundColor: DesignTokens.trueWhite,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: DesignTokens.mobileSpaceSM),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        DesignTokens.mobileRadiusMD),
                                  ),
                                ),
                                child: state.apiKeyStatus ==
                                        ApiKeyValidationStatus.validating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Validate Key'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceXL),

                      // Help section
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
                                  Icons.help_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: DesignTokens.iconSizeMD,
                                ),
                                const SizedBox(width: DesignTokens.spaceSM),
                                Text(
                                  'Where to get a Groq API key?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight:
                                            DesignTokens.fontWeightSemiBold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: DesignTokens.spaceSM),
                            _buildHelpStep(
                                '1. Create a free account at groq.com'),
                            _buildHelpStep(
                                '2. Go to API Keys section in your dashboard'),
                            _buildHelpStep(
                                '3. Click "Create API Key" and name it "AutoQuill"'),
                            _buildHelpStep(
                                '4. Copy the key and paste it above'),
                            const SizedBox(height: DesignTokens.spaceMD),

                            // Open groq.com button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final Uri url = Uri.parse(
                                      'https://console.groq.com/keys');
                                  try {
                                    await url_launcher.launchUrl(url);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Could not open URL')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open groq.com'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: DesignTokens.spaceMD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        DesignTokens.radiusMD),
                                  ),
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

  Widget _buildValidationStatus(
      BuildContext context, MobileOnboardingState state) {
    switch (state.apiKeyStatus) {
      case ApiKeyValidationStatus.valid:
        return Row(
          children: [
            Icon(
              Icons.check_circle,
              color: DesignTokens.emeraldGreen,
              size: 16,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            Text(
              'API key is valid',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.emeraldGreen,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
            ),
          ],
        );
      case ApiKeyValidationStatus.invalid:
        return Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 16,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            Text(
              'API key is invalid',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
            ),
          ],
        );
      case ApiKeyValidationStatus.validating:
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            Text(
              'Validating...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
            ),
          ],
        );
      case ApiKeyValidationStatus.initial:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHelpStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceXS),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.8),
            ),
      ),
    );
  }
}
