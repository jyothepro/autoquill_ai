import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_state.dart';
import '../widgets/mobile_api_key_section.dart';
import '../widgets/mobile_transcription_models_section.dart';
import '../widgets/mobile_local_models_section.dart';
import '../widgets/mobile_theme_settings_section.dart';

class MobileSettingsPage extends StatelessWidget {
  const MobileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                fontSize: DesignTokens.mobileHeadlineSmall,
              ),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.mobileSpaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // API Key Section
                  MobileApiKeySection(),
                  const SizedBox(height: DesignTokens.mobileSpaceXL),

                  // Transcription Models Section
                  const MobileTranscriptionModelsSection(),
                  const SizedBox(height: DesignTokens.mobileSpaceXL),

                  // Local Models Section
                  const MobileLocalModelsSection(),
                  const SizedBox(height: DesignTokens.mobileSpaceXL),

                  // Theme Settings Section
                  const MobileThemeSettingsSection(),
                  const SizedBox(height: DesignTokens.mobileSpaceXXL),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
