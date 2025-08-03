import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/widgets/enhanced_stats_card.dart';
import 'package:autoquill_ai/features/home/presentation/bloc/home_bloc_barrel.dart';

class MobileHomePage extends StatelessWidget {
  const MobileHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(const LoadHomeStats()),
      child: const _MobileHomePageView(),
    );
  }
}

class _MobileHomePageView extends StatefulWidget {
  const _MobileHomePageView();

  @override
  State<_MobileHomePageView> createState() => _MobileHomePageViewState();
}

class _MobileHomePageViewState extends State<_MobileHomePageView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: DesignTokens.durationLong,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        fontSize: DesignTokens.mobileHeadlineSmall,
                      ),
                ),
                Text(
                  'Ready to capture your thoughts?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        fontSize: DesignTokens.mobileBodyMedium,
                      ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.mobileSpaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics section header
                    Container(
                      margin: const EdgeInsets.only(
                          bottom: DesignTokens.mobileSpaceMD),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                                DesignTokens.mobileSpaceXS),
                            decoration: BoxDecoration(
                              gradient: DesignTokens.coralGradient,
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.mobileRadiusSM),
                            ),
                            child: Icon(
                              Icons.analytics_rounded,
                              color: DesignTokens.trueWhite,
                              size: DesignTokens.mobileIconSizeSM,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.mobileSpaceSM),
                          Text(
                            'Your Activity Overview',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: DesignTokens.fontWeightSemiBold,
                                  fontSize: DesignTokens.mobileTitleLarge,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Stats grid - modified for mobile (single column)
                    Column(
                      children: [
                        // Transcription Words Card
                        EnhancedStatsCard(
                          icon: Icons.mic_rounded,
                          title: 'Transcribed',
                          value: state.transcriptionWordsCount.toString(),
                          subtitle: 'words captured',
                          gradient: DesignTokens.coralGradient,
                          iconColor: DesignTokens.vibrantCoral,
                          showAnimation: true,
                        ),
                        const SizedBox(height: DesignTokens.mobileSpaceSM),

                        // Generation Words Card
                        EnhancedStatsCard(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Generated',
                          value: state.generationWordsCount.toString(),
                          subtitle: 'words created',
                          gradient: DesignTokens.blueGradient,
                          iconColor: DesignTokens.deepBlue,
                          showAnimation: true,
                        ),
                        const SizedBox(height: DesignTokens.mobileSpaceSM),

                        // Recording Time Card
                        EnhancedStatsCard(
                          icon: Icons.timer_rounded,
                          title: 'Recording Time',
                          value: _formatTime(state.transcriptionTimeSeconds),
                          subtitle: 'total duration',
                          gradient: DesignTokens.greenGradient,
                          iconColor: DesignTokens.emeraldGreen,
                          showAnimation: true,
                        ),
                        const SizedBox(height: DesignTokens.mobileSpaceSM),

                        // Words Per Minute Card
                        EnhancedStatsCard(
                          icon: Icons.speed_rounded,
                          title: 'Efficiency',
                          value: state.wordsPerMinute.toStringAsFixed(1),
                          subtitle: 'words per minute',
                          gradient: DesignTokens.purpleGradient,
                          iconColor: DesignTokens.purpleViolet,
                          showAnimation: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: DesignTokens.mobileSpaceXL),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
