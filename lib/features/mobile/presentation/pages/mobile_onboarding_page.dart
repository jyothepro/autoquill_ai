import 'package:flutter/material.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/core/storage/app_storage.dart';
import 'mobile_main_layout.dart';

class MobileOnboardingPage extends StatelessWidget {
  const MobileOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLG),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: DesignTokens.spaceXXL),

                      // App logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: DesignTokens.coralGradient,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusLG),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 50,
                          color: DesignTokens.trueWhite,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceLG),

                      // Welcome title
                      Text(
                        'Welcome to AutoQuill',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.spaceSM),

                      // Subtitle
                      Text(
                        'Your personal AI scribe and assistant',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.spaceXS),

                      // Description
                      Text(
                        'Engineered for speed. Designed for trust. Free for life.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.spaceXXL),

                      // Features list
                      _buildFeatureItem(
                        context,
                        icon: Icons.mic,
                        title: 'Transcribe Audio',
                        description: 'Convert speech to clean text instantly',
                      ),
                      const SizedBox(height: DesignTokens.spaceLG),

                      _buildFeatureItem(
                        context,
                        icon: Icons.chat_bubble_outline,
                        title: 'AI Assistant',
                        description: 'Edit and generate text with AI',
                      ),
                      const SizedBox(height: DesignTokens.spaceLG),

                      _buildFeatureItem(
                        context,
                        icon: Icons.lock_outline,
                        title: 'No Login Required',
                        description: 'Use your own API key, no account needed',
                      ),
                      const SizedBox(height: DesignTokens.spaceXXL),
                    ],
                  ),
                ),
              ),

              // Get Started button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeOnboarding(context),
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
                  child: Text(
                    'Get Started',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: DesignTokens.trueWhite,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceSM),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: DesignTokens.iconSizeMD,
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
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _completeOnboarding(BuildContext context) {
    // Mark onboarding as completed
    AppStorage.setOnboardingCompleted(true);

    // Navigate to main layout
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MobileMainLayout()),
    );
  }
}
