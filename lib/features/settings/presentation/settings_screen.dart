import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/ad_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/dashboard.dart';
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
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    final red = dark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

    final children = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.canPop())
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Settings',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'Customize your app experience',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _Section(
        icon: Icons.palette_rounded,
        color: const Color(0xFF7C3AED),
        title: 'Appearance',
        subtitle: 'Choose your preferred theme',
        child: _ThemePicker(
          value: settings.themeMode,
          onChanged: notifier.setThemeMode,
        ),
      ),
      _Section(
        icon: Icons.notifications_none_rounded,
        color: const Color(0xFF2563EB),
        title: 'Notifications',
        subtitle: 'Manage how you receive notifications',
        child: _Group(
          children: [
            _Row(
              icon: Icons.notifications_none_rounded,
              color: const Color(0xFF6D3AED),
              title: 'Daily study reminder',
              subtitle:
                  'Coming soon. The app never asks for notification '
                  'permission until reminders are available.',
              trailing: Switch(value: settings.dailyReminder, onChanged: null),
            ),
          ],
        ),
      ),
      _Section(
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF059669),
        title: 'Privacy',
        subtitle: 'Manage your privacy and data',
        child: _Group(
          children: [
            if (privacyRequired)
              _Row(
                icon: Icons.tune_rounded,
                color: const Color(0xFF4F46E5),
                title: 'Ad privacy choices',
                subtitle: 'Review or change your consent',
                onTap: () => ref.read(adServiceProvider).showPrivacyOptions(),
              ),
            _Row(
              icon: Icons.privacy_tip_outlined,
              color: const Color(0xFF4F46E5),
              title: 'Privacy policy',
              subtitle: 'Read our privacy policy',
              onTap: () => context.push(AppRoutes.privacy),
            ),
            _Row(
              icon: Icons.description_outlined,
              color: const Color(0xFF6D3AED),
              title: 'Terms of use',
              subtitle: 'Read our terms of use',
              onTap: () => context.push(AppRoutes.terms),
            ),
          ],
        ),
      ),
      _Section(
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF2563EB),
        title: 'About',
        subtitle: 'App information and support',
        child: _Group(
          children: [
            _Row(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: DashColors.button,
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white),
              ),
              title: 'About ${AppConstants.appName}',
              subtitle: 'Version ${AppConstants.appVersion}',
              onTap: () => context.push(AppRoutes.about),
            ),
          ],
        ),
      ),
      _Section(
        icon: Icons.delete_outline_rounded,
        color: red,
        title: 'Data',
        subtitle: 'Manage your app data',
        child: _Group(
          tint: red,
          children: [
            _Row(
              icon: Icons.delete_forever_outlined,
              color: red,
              title: 'Reset progress',
              titleColor: red,
              subtitle: 'Clears all local learning data',
              chevronColor: red,
              onTap: () => _reset(context, ref),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(padding: AppSpacing.screen, children: children),
      ),
    );
  }
}

/// White section card: icon disc + title/subtitle header above [child].
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TapCard(
        radius: AppRadius.xlAll,
        borderColor: scheme.outlineVariant.withValues(
          alpha: isDarkTheme(context) ? 1 : 0.5,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Row(
                children: [
                  IconDisc(icon: icon, color: color, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bordered inner container holding rows separated by dividers.
class _Group extends StatelessWidget {
  const _Group({required this.children, this.tint});

  final List<Widget> children;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = isDarkTheme(context);
    final t = tint;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t == null
            ? scheme.surface
            : t.withValues(alpha: dark ? 0.12 : 0.05),
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: t == null
              ? scheme.outlineVariant.withValues(alpha: dark ? 1 : 0.7)
              : t.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    this.icon,
    this.color,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.chevronColor,
  });

  final IconData? icon;
  final Color? color;
  final Widget? leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? chevronColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              leading ??
                  IconDisc(
                    icon: icon!,
                    color: color ?? scheme.primary,
                    size: 44,
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: chevronColor ?? scheme.onSurface,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light / Dark / System tiles; the selected one is filled indigo.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = isDarkTheme(context);
    const options = [
      (ThemeMode.light, Icons.wb_sunny_outlined, 'Light', Color(0xFFF59E0B)),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark', Color(0xFF4F46E5)),
      (
        ThemeMode.system,
        Icons.desktop_windows_outlined,
        'System',
        Color(0xFF4F46E5),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 1 : 0.7),
        ),
      ),
      child: Row(
        children: [
          for (final (i, (mode, icon, label, color)) in options.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _ThemeTile(
                icon: icon,
                label: label,
                color: color,
                darkTile: mode == ThemeMode.dark,
                selected: value == mode,
                onTap: () => onChanged(mode),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.darkTile,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool darkTile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = isDarkTheme(context);
    final idle = darkTile && !dark ? const Color(0xFFEEEDFB) : scheme.surface;
    final fg = selected
        ? Colors.white
        : (dark && color == const Color(0xFF4F46E5) ? scheme.primary : color);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Ink(
            height: 84,
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFF5B5BF0), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : idle,
              borderRadius: AppRadius.mdAll,
              boxShadow: selected ? null : DashColors.softShadow(context),
            ),
            child: Stack(
              children: [
                if (selected)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Color(0xFF5B4BEA),
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: fg, size: 30),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected ? Colors.white : scheme.onSurface,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
