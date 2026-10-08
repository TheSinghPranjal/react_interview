import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/rich_content.dart';

class _DocScreen extends StatelessWidget {
  const _DocScreen({required this.title, required this.sections});

  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          for (final (heading, body) in sections) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(heading, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            RichContent(body, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.blur_circular_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          Text(
            'Version ${AppConstants.appVersion}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          const RichContent(
            '${AppConstants.appName} helps you learn modern React and '
            'Next.js with structured lessons, 150 interview questions and '
            '250 randomized quiz questions — all available offline.\n\n'
            'Content focuses on current best practices: React 19 features such '
            'as Actions, `useActionState`, `useOptimistic` and Server '
            'Components, and the Next.js App Router with its caching and '
            'rendering model.\n\n'
            'React and Next.js are trademarks of their respective owners. This '
            'app is an independent learning resource and is not affiliated '
            'with or endorsed by Meta or Vercel.',
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.appVersion,
            ),
            child: const Text('Open-source licenses'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push(AppRoutes.privacy),
            child: const Text('Privacy policy'),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.terms),
            child: const Text('Terms of use'),
          ),
        ],
      ),
    );
  }
}

/// PLACEHOLDER — replace with your published privacy policy (and host it at a
/// public URL for the Play Console listing) before release.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocScreen(
      title: 'Privacy policy',
      sections: [
        (
          'Summary',
          '${AppConstants.appName} does not require an account and does not '
              'collect your name, email or other personal information. Your '
              'learning progress is stored only on your device.',
        ),
        (
          'Data stored on your device',
          '- Completed lessons, XP, streaks and achievements\n'
              '- Quiz history and interview progress\n'
              '- Bookmarks and settings (theme, optional display name)\n\n'
              'You can delete all of this at any time in Settings → Reset progress, '
              'or by uninstalling the app.',
        ),
        (
          'Advertising',
          'The free version shows ads served by Google AdMob. AdMob may '
              'collect device identifiers and usage data to serve and measure '
              'ads. Where required (for example in the EEA and UK) you are asked '
              'for consent through Google\'s consent form, and you can change '
              'your choice in Settings → Ad privacy choices.',
        ),
        (
          'Permissions',
          'The app only uses network access for ads. It does not request '
              'location, contacts, camera, microphone or notification '
              'permissions.',
        ),
        (
          'Contact',
          'Questions? Email ${AppConstants.supportEmail}.\n\n'
              'Note: this is a placeholder policy and must be reviewed before '
              'publishing.',
        ),
      ],
    );
  }
}

/// PLACEHOLDER — replace with your terms of use before release.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocScreen(
      title: 'Terms of use',
      sections: [
        (
          'Use of the app',
          '${AppConstants.appName} is provided for educational purposes. '
              'Content is written carefully but may contain mistakes or become '
              'outdated as React and Next.js evolve; always consult the '
              'official documentation for production decisions.',
        ),
        (
          'No warranty',
          'The app is provided "as is" without warranties of any kind.',
        ),
        (
          'Changes',
          'These terms may be updated with new versions of the app.\n\n'
              'Note: this is a placeholder and must be reviewed before publishing.',
        ),
      ],
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.path, super.key});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: EmptyState(
        icon: Icons.explore_off_rounded,
        title: 'Page not found',
        message: 'We couldn\'t find "$path".',
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Go home'),
        ),
      ),
    );
  }
}
