import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import '../services/lock_service.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? const _IOSSettingsScreen()
        : const _AndroidSettingsScreen();
  }
}

class _AndroidSettingsScreen extends StatefulWidget {
  const _AndroidSettingsScreen();

  @override
  State<_AndroidSettingsScreen> createState() => _AndroidSettingsScreenState();
}

class _AndroidSettingsScreenState extends State<_AndroidSettingsScreen> {
  String _version = 'Loading...';
  bool _checkingForUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingForUpdates = true;
    });

    final updateChecked = await UpdateService().checkForUpdate();

    setState(() {
      _checkingForUpdates = false;
    });

    if (mounted && !updateChecked) {
      // If no update was found or check failed, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are using the latest version'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Presentation'),
          SwitchListTile(
            title: const Text('Pinch to Zoom'),
            subtitle: const Text('Allow zooming photos during presentation'),
            value: settings.pinchToZoom,
            onChanged: (value) {
              provider.updateSettings(settings.copyWith(pinchToZoom: value));
            },
          ),
          SwitchListTile(
            title: const Text('Show Photo Counter'),
            subtitle: const Text('Display "3 of 10" during presentation'),
            value: settings.showPhotoCounter,
            onChanged: (value) {
              provider.updateSettings(settings.copyWith(showPhotoCounter: value));
            },
          ),
          SwitchListTile(
            title: const Text('Confirm Photo Removal'),
            subtitle: const Text('Ask for confirmation before removing photos'),
            value: settings.confirmPhotoRemoval,
            onChanged: (value) {
              provider.updateSettings(settings.copyWith(confirmPhotoRemoval: value));
            },
          ),
          SwitchListTile(
            title: const Text('Swipe to Delete'),
            subtitle: const Text('Enable swipe up gesture to remove photos'),
            value: settings.swipeToDelete,
            onChanged: (value) {
              provider.updateSettings(settings.copyWith(swipeToDelete: value));
            },
          ),
          SwitchListTile(
            title: const Text('Auto-advance Slideshow'),
            subtitle: settings.autoAdvance
                ? Text('${settings.autoAdvanceInterval}s interval')
                : const Text('Manually swipe through photos'),
            value: settings.autoAdvance,
            onChanged: (value) {
              provider.updateSettings(settings.copyWith(autoAdvance: value));
            },
          ),
          if (settings.autoAdvance)
            ListTile(
              title: const Text('Slideshow Interval'),
              trailing: DropdownButton<int>(
                value: settings.autoAdvanceInterval,
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 seconds')),
                  DropdownMenuItem(value: 5, child: Text('5 seconds')),
                  DropdownMenuItem(value: 10, child: Text('10 seconds')),
                  DropdownMenuItem(value: 30, child: Text('30 seconds')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    provider.updateSettings(
                      settings.copyWith(autoAdvanceInterval: value),
                    );
                  }
                },
              ),
            ),
          SwitchListTile(
            title: const Text('Auto-lock Timer'),
            subtitle: settings.autoLockEnabled
                ? Text('Lock after ${settings.autoLockMinutes} min')
                : const Text('Disabled'),
            value: settings.autoLockEnabled,
            onChanged: (value) {
              provider.updateSettings(settings.copyWith(autoLockEnabled: value));
            },
          ),
          if (settings.autoLockEnabled)
            ListTile(
              title: const Text('Auto-lock Duration'),
              trailing: DropdownButton<int>(
                value: settings.autoLockMinutes,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 minute')),
                  DropdownMenuItem(value: 2, child: Text('2 minutes')),
                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    provider.updateSettings(
                      settings.copyWith(autoLockMinutes: value),
                    );
                  }
                },
              ),
            ),
          _buildSectionHeader(context, 'Display'),
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(value: AppThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: AppThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (value) {
                if (value != null) {
                  provider.updateSettings(settings.copyWith(themeMode: value));
                }
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Transition Animations'),
            subtitle: const Text('Enable smooth transitions between photos'),
            value: settings.transitionAnimations,
            onChanged: (value) {
              provider.updateSettings(settings.copyWith(transitionAnimations: value));
            },
          ),
          _buildSectionHeader(context, 'Security (Android Only)'),
          if (Platform.isAndroid)
            FutureBuilder<bool>(
              future: LockService().isDeviceAdminEnabled(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? false;
                return ListTile(
                  title: const Text('Device Admin'),
                  subtitle: Text(
                    isEnabled
                        ? 'Enabled - allows locking device on exit'
                        : 'Not enabled - tap to enable device locking',
                  ),
                  trailing: isEnabled
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.warning, color: Colors.orange),
                  onTap: isEnabled
                      ? null
                      : () {
                          LockService().requestDeviceAdmin();
                        },
                );
              },
            ),
          if (Platform.isIOS)
            ListTile(
              title: const Text('Guided Access'),
              subtitle: const Text(
                'iOS requires Guided Access for full lock mode. '
                'Enable in Settings > Accessibility > Guided Access',
              ),
              trailing: const Icon(Icons.info_outline),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('How to Enable Guided Access'),
                    content: const Text(
                      '1. Go to Settings > Accessibility\n'
                      '2. Tap Guided Access\n'
                      '3. Turn on Guided Access\n'
                      '4. Set a passcode\n\n'
                      'When viewing photos:\n'
                      '- Triple-click home/side button to start\n'
                      '- Triple-click again to exit',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          _buildSectionHeader(context, 'About'),
          ListTile(
            title: const Text('Version'),
            trailing: Text(_version),
          ),
          if (Platform.isAndroid)
            ListTile(
              title: const Text('Check for Updates'),
              subtitle: const Text('Check for new app versions'),
              trailing: _checkingForUpdates
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update),
              onTap: _checkingForUpdates ? null : _checkForUpdates,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _IOSSettingsScreen extends StatefulWidget {
  const _IOSSettingsScreen();

  @override
  State<_IOSSettingsScreen> createState() => _IOSSettingsScreenState();
}

class _IOSSettingsScreenState extends State<_IOSSettingsScreen> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = provider.settings;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            _buildSectionHeader('PRESENTATION'),
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              children: [
                CupertinoListTile(
                  title: const Text('Pinch to Zoom'),
                  subtitle: const Text('Allow zooming photos during presentation'),
                  trailing: CupertinoSwitch(
                    value: settings.pinchToZoom,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(pinchToZoom: value));
                    },
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Show Photo Counter'),
                  subtitle: const Text('Display "3 of 10" during presentation'),
                  trailing: CupertinoSwitch(
                    value: settings.showPhotoCounter,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(showPhotoCounter: value));
                    },
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Confirm Photo Removal'),
                  subtitle: const Text('Ask for confirmation before removing photos'),
                  trailing: CupertinoSwitch(
                    value: settings.confirmPhotoRemoval,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(confirmPhotoRemoval: value));
                    },
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Swipe to Delete'),
                  subtitle: const Text('Enable swipe up gesture to remove photos'),
                  trailing: CupertinoSwitch(
                    value: settings.swipeToDelete,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(swipeToDelete: value));
                    },
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Auto-advance Slideshow'),
                  subtitle: Text(
                    settings.autoAdvance
                        ? '${settings.autoAdvanceInterval}s interval'
                        : 'Manually swipe through photos',
                  ),
                  trailing: CupertinoSwitch(
                    value: settings.autoAdvance,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(autoAdvance: value));
                    },
                  ),
                ),
                if (settings.autoAdvance)
                  CupertinoListTile(
                    title: const Text('Slideshow Interval'),
                    trailing: _buildIntervalPicker(context, settings, provider),
                  ),
                CupertinoListTile(
                  title: const Text('Auto-lock Timer'),
                  subtitle: Text(
                    settings.autoLockEnabled
                        ? 'Lock after ${settings.autoLockMinutes} min'
                        : 'Disabled',
                  ),
                  trailing: CupertinoSwitch(
                    value: settings.autoLockEnabled,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(autoLockEnabled: value));
                    },
                  ),
                ),
                if (settings.autoLockEnabled)
                  CupertinoListTile(
                    title: const Text('Auto-lock Duration'),
                    trailing: _buildDurationPicker(context, settings, provider),
                  ),
              ],
            ),
            _buildSectionHeader('DISPLAY'),
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              children: [
                CupertinoListTile(
                  title: const Text('Theme'),
                  trailing: _buildThemePicker(context, settings, provider),
                ),
                CupertinoListTile(
                  title: const Text('Transition Animations'),
                  subtitle: const Text('Enable smooth transitions between photos'),
                  trailing: CupertinoSwitch(
                    value: settings.transitionAnimations,
                    onChanged: (value) {
                      provider.updateSettings(
                        settings.copyWith(transitionAnimations: value),
                      );
                    },
                  ),
                ),
              ],
            ),
            _buildSectionHeader('SECURITY'),
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              children: [
                CupertinoListTile(
                  title: const Text('Guided Access'),
                  subtitle: const Text(
                    'Enable in Settings > Accessibility > Guided Access',
                  ),
                  trailing: const Icon(CupertinoIcons.info_circle),
                  onTap: () => _showGuidedAccessInfo(context),
                ),
              ],
            ),
            _buildSectionHeader('ABOUT'),
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              children: [
                CupertinoListTile(
                  title: const Text('Version'),
                  trailing: Text(_version),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: CupertinoColors.systemGrey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildIntervalPicker(BuildContext context, AppSettings settings, AppProvider provider) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Text('${settings.autoAdvanceInterval}s'),
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => _buildPicker(
            context,
            [3, 5, 10, 30],
            settings.autoAdvanceInterval,
            (value) => provider.updateSettings(
              settings.copyWith(autoAdvanceInterval: value),
            ),
            (value) => '$value seconds',
          ),
        );
      },
    );
  }

  Widget _buildDurationPicker(BuildContext context, AppSettings settings, AppProvider provider) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Text('${settings.autoLockMinutes} min'),
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => _buildPicker(
            context,
            [1, 2, 5, 10, 15],
            settings.autoLockMinutes,
            (value) => provider.updateSettings(
              settings.copyWith(autoLockMinutes: value),
            ),
            (value) => '$value minute${value != 1 ? 's' : ''}',
          ),
        );
      },
    );
  }

  Widget _buildThemePicker(BuildContext context, AppSettings settings, AppProvider provider) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Text(_themeModeName(settings.themeMode)),
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => _buildPicker(
            context,
            [AppThemeMode.system, AppThemeMode.light, AppThemeMode.dark],
            settings.themeMode,
            (value) => provider.updateSettings(settings.copyWith(themeMode: value)),
            _themeModeName,
          ),
        );
      },
    );
  }

  String _themeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  Widget _buildPicker<T>(
    BuildContext context,
    List<T> items,
    T selectedItem,
    void Function(T) onChanged,
    String Function(T) itemLabel,
  ) {
    return Container(
      height: 250,
      color: CupertinoColors.systemBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(
                initialItem: items.indexOf(selectedItem),
              ),
              onSelectedItemChanged: (index) {
                onChanged(items[index]);
              },
              children: items.map((item) => Center(child: Text(itemLabel(item)))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuidedAccessInfo(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('How to Enable Guided Access'),
        content: const Text(
          '\n1. Go to Settings > Accessibility\n'
          '2. Tap Guided Access\n'
          '3. Turn on Guided Access\n'
          '4. Set a passcode\n\n'
          'When viewing photos:\n'
          '- Triple-click home/side button to start\n'
          '- Triple-click again to exit',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
