import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/ad_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import '../../progress/providers/progress_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'This permanently clears XP, streaks, completed lessons, quiz '
          'history, interview progress and bookmarks on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(progressProvider.notifier).resetAll();
    await ref.read(bookmarksProvider.notifier).clearAll();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progress reset')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final privacyRequired =
        ref.watch(privacyOptionsRequiredProvider).value ?? false;
    final theme = Theme.of(context);

    Widget header(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        t,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest_outlined),
                  label: Text('System'),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => notifier.setThemeMode(s.first),
            ),
          ),
          header('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none_rounded),
            title: const Text('Daily study reminder'),
            subtitle: const Text(
              'Coming soon. The app never asks for notification permission '
              'until reminders are available.',
            ),
            value: settings.dailyReminder,
            onChanged: null,
          ),
          header('Privacy'),
          if (privacyRequired)
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Ad privacy choices'),
              subtitle: const Text('Review or change your consent'),
              onTap: () => ref.read(adServiceProvider).showPrivacyOptions(),
            ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of use'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.terms),
          ),
          header('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About ${AppConstants.appName}'),
            subtitle: const Text('Version ${AppConstants.appVersion}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.about),
          ),
          header('Data'),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Reset progress',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Clears all local learning data'),
            onTap: () => _reset(context, ref),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
