import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/app_storage.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'features/mobile/presentation/pages/mobile_onboarding_page.dart';
import 'features/mobile/presentation/pages/mobile_main_layout.dart';

class MobileMainApp extends StatelessWidget {
  const MobileMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc()..add(LoadSettings()),
      child: Builder(
        builder: (context) {
          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'AutoQuill Mobile',
                builder: BotToastInit(),
                navigatorObservers: [BotToastNavigatorObserver()],
                theme: minimalistLightTheme,
                darkTheme: minimalistDarkTheme,
                themeMode: state.themeMode ?? ThemeMode.system,
                home: _buildHomeWidget(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeWidget() {
    // Check if onboarding is completed
    final bool isOnboardingCompleted = AppStorage.isOnboardingCompleted();

    if (isOnboardingCompleted) {
      return const MobileMainLayout();
    } else {
      return const MobileOnboardingPage();
    }
  }
}
