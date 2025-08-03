import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_event.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_state.dart';

class MobileApiKeySection extends StatelessWidget {
  MobileApiKeySection({super.key});

  final TextEditingController _apiKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        _apiKeyController.text = state.apiKey ?? '';

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
                      gradient: DesignTokens.coralGradient,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSM),
                    ),
                    child: Icon(
                      Icons.key,
                      color: DesignTokens.trueWhite,
                      size: DesignTokens.iconSizeSM,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceSM),
                  Text(
                    'API Key',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceSM),
              Text(
                'Enter your Groq API key to use transcription and assistant features.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: DesignTokens.spaceMD),

              // API Key input
              TextField(
                controller: _apiKeyController,
                obscureText: !state.isApiKeyVisible,
                decoration: InputDecoration(
                  labelText: 'Groq API Key',
                  hintText: 'Enter your API key here',
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.isApiKeyVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      context
                          .read<SettingsBloc>()
                          .add(ToggleApiKeyVisibility());
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceMD),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _apiKeyController.clear();
                        context.read<SettingsBloc>().add(DeleteApiKey());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.spaceSM),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMD),
                        ),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final apiKey = _apiKeyController.text;
                        if (apiKey.isNotEmpty) {
                          context.read<SettingsBloc>().add(SaveApiKey(apiKey));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.vibrantCoral,
                        foregroundColor: DesignTokens.trueWhite,
                        padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.spaceSM),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMD),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),

              // Success indicator
              if (state.apiKey?.isNotEmpty ?? false) ...[
                const SizedBox(height: DesignTokens.spaceSM),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: DesignTokens.vibrantCoral,
                      size: 16,
                    ),
                    const SizedBox(width: DesignTokens.spaceXS),
                    Text(
                      'API key saved',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: DesignTokens.vibrantCoral,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
