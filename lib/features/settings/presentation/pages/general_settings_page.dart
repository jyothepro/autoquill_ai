import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_state.dart';
import 'package:autoquill_ai/features/settings/presentation/bloc/settings_event.dart';
import 'package:autoquill_ai/features/settings/presentation/widgets/api_key_section.dart';
import 'package:autoquill_ai/features/settings/presentation/widgets/theme_settings_section.dart';
import 'package:autoquill_ai/core/services/auto_update_service.dart';
import 'package:autoquill_ai/core/theme/design_tokens.dart';
import 'package:autoquill_ai/core/services/volume_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  late ValueNotifier<String> _selectedInputDeviceNotifier;

  /// Check if the app has permission to control volume
  Future<bool> _checkVolumePermission() async {
    try {
      await VolumeService.instance.initialize();
      return VolumeService.instance.hasVolumePermission;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize with current selected device or 'System Default'
    _selectedInputDeviceNotifier = ValueNotifier<String>('System Default');
    _loadCurrentInputDevice();
  }

  @override
  void dispose() {
    _selectedInputDeviceNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentInputDevice() async {
    final settingsBloc = context.read<SettingsBloc>();
    final currentDevice = settingsBloc.state.selectedInputDevice;
    _selectedInputDeviceNotifier.value =
        currentDevice?.label ?? 'System Default';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.error?.isNotEmpty ?? false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // API Key Section
              ApiKeySection(),
              const SizedBox(height: 32),

              // Theme Settings Section
              ThemeSettingsSection(),

              const SizedBox(height: 32),

              // Sound Settings Section
              _buildSoundSettingsSection(context),

              const SizedBox(height: 32),

              // Behavior Settings Section
              _buildBehaviorSettingsSection(context),

              const SizedBox(height: 32),

              // Input Device Settings Section
              _buildInputDeviceSettingsSection(context),

              const SizedBox(height: 32),

              // Data Location Section
              _buildDataLocationSection(context),

              const SizedBox(height: 32),

              // App Updates Section
              _buildAppUpdatesSection(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundSettingsSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceXS),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.greenGradient,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: DesignTokens.trueWhite,
                    size: DesignTokens.iconSizeSM,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceSM),
                Text(
                  'Sound Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: isDarkMode
                            ? DesignTokens.trueWhite
                            : DesignTokens.pureBlack,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSM),
            Text(
              'Control sound effects and audio notifications throughout the app.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? DesignTokens.trueWhite.withValues(alpha: 0.7)
                        : DesignTokens.pureBlack.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: DesignTokens.spaceMD),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMD),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? DesignTokens.trueWhite.withValues(alpha: 0.05)
                    : DesignTokens.pureBlack.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                // border: Border.all(
                //   color: isDarkMode
                //       ? DesignTokens.trueWhite.withValues(alpha: 0.1)
                //       : DesignTokens.pureBlack.withValues(alpha: 0.08),
                // ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Sound Effects',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: DesignTokens.fontWeightMedium,
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                        : DesignTokens.pureBlack,
                                  ),
                        ),
                        const SizedBox(height: DesignTokens.spaceXS),
                        Text(
                          'Play audio feedback for recording, typing, and error notifications.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                            .withValues(alpha: 0.7)
                                        : DesignTokens.pureBlack
                                            .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMD),
                  Switch(
                    value: state.soundEnabled,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(ToggleSound());
                    },
                    activeColor: DesignTokens.vibrantCoral,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMD),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMD),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? DesignTokens.trueWhite.withValues(alpha: 0.05)
                    : DesignTokens.pureBlack.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Mute System Volume',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: DesignTokens.fontWeightMedium,
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                        : DesignTokens.pureBlack,
                                  ),
                        ),
                        const SizedBox(height: DesignTokens.spaceXS),
                        FutureBuilder<bool>(
                          future: _checkVolumePermission(),
                          builder: (context, snapshot) {
                            final hasPermission = snapshot.data ?? false;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasPermission
                                      ? 'Automatically mute system volume during recording to prevent audio interference.'
                                      : 'Automatically mute system volume during recording. Note: This feature may not work on macOS due to system security restrictions.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isDarkMode
                                            ? DesignTokens.trueWhite
                                                .withValues(alpha: 0.7)
                                            : DesignTokens.pureBlack
                                                .withValues(alpha: 0.6),
                                      ),
                                ),
                                if (!hasPermission) ...[
                                  const SizedBox(height: DesignTokens.spaceXS),
                                  Text(
                                    '⚠️ Volume control not available - manually mute media before recording.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMD),
                  Switch(
                    value: state.autoMuteSystemEnabled,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(ToggleAutoMuteSystem());
                    },
                    activeColor: DesignTokens.vibrantCoral,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBehaviorSettingsSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceXS),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.blueGradient,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: DesignTokens.trueWhite,
                    size: DesignTokens.iconSizeSM,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceSM),
                Text(
                  'Behavior Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: isDarkMode
                            ? DesignTokens.trueWhite
                            : DesignTokens.pureBlack,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSM),
            Text(
              'Configure how transcriptions and assistant responses are handled.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? DesignTokens.trueWhite.withValues(alpha: 0.7)
                        : DesignTokens.pureBlack.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: DesignTokens.spaceMD),

            // Copy Last Transcription to Clipboard Setting
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMD),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? DesignTokens.trueWhite.withValues(alpha: 0.05)
                    : DesignTokens.pureBlack.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Copy Last Transcription to Clipboard',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: DesignTokens.fontWeightMedium,
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                        : DesignTokens.pureBlack,
                                  ),
                        ),
                        const SizedBox(height: DesignTokens.spaceXS),
                        Text(
                          'When enabled, transcriptions remain in clipboard. When disabled, the original clipboard content is restored after pasting.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                            .withValues(alpha: 0.7)
                                        : DesignTokens.pureBlack
                                            .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMD),
                  Switch(
                    value: state.copyLastTranscriptionToClipboard,
                    onChanged: (value) {
                      context
                          .read<SettingsBloc>()
                          .add(ToggleCopyLastTranscriptionToClipboard());
                    },
                    activeColor: DesignTokens.vibrantCoral,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMD),

            // Press Enter After Transcription Setting
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMD),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? DesignTokens.trueWhite.withValues(alpha: 0.05)
                    : DesignTokens.pureBlack.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Press Enter After Transcription',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: DesignTokens.fontWeightMedium,
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                        : DesignTokens.pureBlack,
                                  ),
                        ),
                        const SizedBox(height: DesignTokens.spaceXS),
                        Text(
                          'Automatically press Enter after pasting transcriptions or assistant responses.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? DesignTokens.trueWhite
                                            .withValues(alpha: 0.7)
                                        : DesignTokens.pureBlack
                                            .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMD),
                  Switch(
                    value: state.pressEnterAfterTranscription,
                    onChanged: (value) {
                      context
                          .read<SettingsBloc>()
                          .add(TogglePressEnterAfterTranscription());
                    },
                    activeColor: DesignTokens.vibrantCoral,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputDeviceSettingsSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<String>(
      valueListenable: _selectedInputDeviceNotifier,
      builder: (context, selectedDeviceLabel, child) {
        if (kDebugMode) {
          print(
              'UI: InputDeviceSettingsSection ValueListenableBuilder rebuilding with selectedInputDevice: $selectedDeviceLabel');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceXS),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.purpleGradient,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  ),
                  child: Icon(
                    Icons.keyboard_voice_rounded,
                    color: DesignTokens.trueWhite,
                    size: DesignTokens.iconSizeSM,
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceSM),
                Text(
                  'Input Device',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: isDarkMode
                            ? DesignTokens.trueWhite
                            : DesignTokens.pureBlack,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSM),
            Text(
              'Select the input device for recording audio. The selected device will be used for all recordings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? DesignTokens.trueWhite.withValues(alpha: 0.7)
                        : DesignTokens.pureBlack.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: DesignTokens.spaceMD),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMD),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? DesignTokens.trueWhite.withValues(alpha: 0.05)
                    : DesignTokens.pureBlack.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current selection display
                  Row(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: DesignTokens.iconSizeSM,
                        color: isDarkMode
                            ? DesignTokens.trueWhite.withValues(alpha: 0.8)
                            : DesignTokens.pureBlack.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: DesignTokens.spaceXS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Input Device',
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
                            const SizedBox(height: DesignTokens.spaceXS),
                            Builder(
                              builder: (context) {
                                if (kDebugMode) {
                                  print(
                                      'UI: Current input device label: $selectedDeviceLabel');
                                }
                                return Text(
                                  selectedDeviceLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isDarkMode
                                            ? DesignTokens.trueWhite
                                                .withValues(alpha: 0.7)
                                            : DesignTokens.pureBlack
                                                .withValues(alpha: 0.6),
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceMD),
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: state.isLoadingInputDevices
                              ? null
                              : () => _selectInputDevice(context),
                          icon: state.isLoadingInputDevices
                              ? SizedBox(
                                  width: DesignTokens.iconSizeSM,
                                  height: DesignTokens.iconSizeSM,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DesignTokens.trueWhite,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.keyboard_voice_rounded,
                                  size: DesignTokens.iconSizeSM,
                                ),
                          label: Text(
                            state.isLoadingInputDevices
                                ? 'Loading...'
                                : 'Change Input Device',
                            style: TextStyle(
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.vibrantCoral,
                            foregroundColor: DesignTokens.trueWhite,
                            padding: const EdgeInsets.symmetric(
                              vertical: DesignTokens.spaceSM,
                              horizontal: DesignTokens.spaceMD,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusSM),
                            ),
                            elevation: 0,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataLocationSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceXS),
              decoration: BoxDecoration(
                gradient: DesignTokens.blueGradient,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: DesignTokens.trueWhite,
                size: DesignTokens.iconSizeSM,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSM),
            Text(
              'Data Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: isDarkMode
                        ? DesignTokens.trueWhite
                        : DesignTokens.pureBlack,
                  ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceSM),
        Text(
          'Access your app data including transcriptions and recordings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? DesignTokens.trueWhite.withValues(alpha: 0.7)
                    : DesignTokens.pureBlack.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: DesignTokens.spaceMD),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceMD),
          decoration: BoxDecoration(
            color: isDarkMode
                ? DesignTokens.trueWhite.withValues(alpha: 0.05)
                : DesignTokens.pureBlack.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            // border: Border.all(
            //   color: isDarkMode
            //       ? DesignTokens.trueWhite.withValues(alpha: 0.1)
            //       : DesignTokens.pureBlack.withValues(alpha: 0.08),
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: DesignTokens.iconSizeXS,
                    color: isDarkMode
                        ? DesignTokens.trueWhite.withValues(alpha: 0.6)
                        : DesignTokens.pureBlack.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: DesignTokens.spaceXS),
                  Expanded(
                    child: Text(
                      'App data is stored securely in your system\'s Application Support directory.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode
                                ? DesignTokens.trueWhite.withValues(alpha: 0.7)
                                : DesignTokens.pureBlack.withValues(alpha: 0.6),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceMD),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openDataLocation(context),
                  icon: Icon(
                    Icons.folder_open_rounded,
                    size: DesignTokens.iconSizeSM,
                  ),
                  label: Text(
                    'Open Data Folder',
                    style: TextStyle(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.vibrantCoral,
                    foregroundColor: DesignTokens.trueWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.spaceSM,
                      horizontal: DesignTokens.spaceMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSM),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppUpdatesSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceXS),
              decoration: BoxDecoration(
                gradient: DesignTokens.purpleGradient,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              ),
              child: Icon(
                Icons.system_update_rounded,
                color: DesignTokens.trueWhite,
                size: DesignTokens.iconSizeSM,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSM),
            Text(
              'App Updates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: isDarkMode
                        ? DesignTokens.trueWhite
                        : DesignTokens.pureBlack,
                  ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceSM),
        Text(
          'AutoQuill automatically checks for updates. You can also manually check for updates below. Current version: v1.4.0',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? DesignTokens.trueWhite.withValues(alpha: 0.7)
                    : DesignTokens.pureBlack.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: DesignTokens.spaceMD),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spaceMD),
          decoration: BoxDecoration(
            color: isDarkMode
                ? DesignTokens.trueWhite.withValues(alpha: 0.05)
                : DesignTokens.pureBlack.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            // border: Border.all(
            //   color: isDarkMode
            //       ? DesignTokens.trueWhite.withValues(alpha: 0.1)
            //       : DesignTokens.pureBlack.withValues(alpha: 0.08),
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _checkForUpdates(context),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: DesignTokens.iconSizeSM,
                  ),
                  label: Text(
                    'Check for Updates',
                    style: TextStyle(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.vibrantCoral,
                    foregroundColor: DesignTokens.trueWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.spaceSM,
                      horizontal: DesignTokens.spaceMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSM),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _checkForUpdates(BuildContext context) async {
    // Show loading toast
    BotToast.showLoading(
      duration: const Duration(seconds: 3),
    );

    try {
      await AutoUpdateService.checkForUpdates();

      // Show success message
      BotToast.showText(
        text: 'Update check completed successfully!',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Show error message
      BotToast.showText(
        text: 'Failed to check for updates: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _openDataLocation(BuildContext context) async {
    try {
      // Get the Application Support directory (same as used in main.dart)
      final directory = await getApplicationSupportDirectory();
      final uri = Uri.file(directory.path);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        BotToast.showText(
          text: 'Data folder opened successfully',
          duration: const Duration(seconds: 2),
        );
      } else {
        throw Exception('Cannot open folder on this platform');
      }
    } catch (e) {
      BotToast.showText(
        text: 'Failed to open data folder: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _selectInputDevice(BuildContext context) async {
    try {
      // Load input devices first
      context.read<SettingsBloc>().add(LoadInputDevices());

      // Show loading dialog while devices are being loaded
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading input devices...'),
            ],
          ),
        ),
      );

      // Wait a bit for the devices to load, then show the selection dialog
      await Future.delayed(const Duration(milliseconds: 1000));

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        final devices =
            context.read<SettingsBloc>().state.availableInputDevices;
        final selectedDevice =
            context.read<SettingsBloc>().state.selectedInputDevice;

        if (devices.isEmpty) {
          BotToast.showText(
            text:
                'No input devices found. Please ensure your microphone is connected.',
            duration: const Duration(seconds: 3),
          );
          return;
        }

        // Show dialog with radio buttons and OK button
        InputDevice? tempSelectedDevice = selectedDevice;

        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Select Input Device'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        // Option for system default
                        RadioListTile<InputDevice?>(
                          value: null,
                          groupValue: tempSelectedDevice,
                          title: const Text('System Default'),
                          subtitle: const Text('Use the default input device'),
                          onChanged: (InputDevice? value) {
                            setState(() {
                              tempSelectedDevice = value;
                            });
                          },
                        ),
                        const Divider(),
                        ...devices.map((device) {
                          return RadioListTile<InputDevice>(
                            value: device,
                            groupValue: tempSelectedDevice,
                            title: Text(device.label),
                            subtitle: Text('ID: ${device.id}'),
                            onChanged: (InputDevice? value) {
                              setState(() {
                                tempSelectedDevice = value;
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Update UI immediately
                        final deviceLabel =
                            tempSelectedDevice?.label ?? 'System Default';
                        _selectedInputDeviceNotifier.value = deviceLabel;

                        if (kDebugMode) {
                          print('UI: User confirmed selection: $deviceLabel');
                        }

                        // Close dialog
                        Navigator.of(context).pop();

                        // Update storage and bloc in background
                        if (tempSelectedDevice == null) {
                          context.read<SettingsBloc>().add(ClearInputDevice());
                        } else {
                          context
                              .read<SettingsBloc>()
                              .add(SelectInputDevice(tempSelectedDevice!));
                        }

                        // Show confirmation
                        BotToast.showText(
                          text: tempSelectedDevice == null
                              ? 'Using system default input device'
                              : 'Input device selected: ${tempSelectedDevice!.label}',
                          duration: const Duration(seconds: 2),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.vibrantCoral,
                        foregroundColor: DesignTokens.trueWhite,
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
      }
      BotToast.showText(
        text: 'Failed to load input devices: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }
}
