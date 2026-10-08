import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/interview_question.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/dashboard.dart';
import '../../progress/providers/progress_provider.dart';

enum InterviewStatus { notStarted, known, practice }

final interviewStatusProvider = Provider.family<InterviewStatus, String>((
  ref,
  id,
) {
  return ref.watch(
    progressProvider.select(
      (p) => p.interviewKnown.contains(id)
          ? InterviewStatus.known
          : p.interviewPractice.contains(id)
          ? InterviewStatus.practice
          : InterviewStatus.notStarted,
    ),
  );
});

/// Icon and accent for an interview topic.
(IconData, Color) topicVisual(String topic) => switch (topic) {
  'Rendering' => (Icons.layers_rounded, const Color(0xFFEA7A0B)),
  'Hooks' => (Icons.link_rounded, const Color(0xFF7C3AED)),
  'Performance' => (Icons.speed_rounded, const Color(0xFFE11D48)),
  'Server Components' => (Icons.dns_rounded, const Color(0xFF0EA5E9)),
  'Routing' ||
  'Navigation' => (Icons.alt_route_rounded, const Color(0xFF16A34A)),
  'Caching' => (Icons.cached_rounded, const Color(0xFF0D9488)),
  'Data Fetching' => (Icons.cloud_download_rounded, const Color(0xFF2563EB)),
  'Architecture' => (Icons.account_tree_rounded, const Color(0xFFEA7A0B)),
  'Components' => (Icons.view_in_ar_rounded, const Color(0xFF7C3AED)),
  'Security' ||
  'Authentication' => (Icons.shield_rounded, const Color(0xFF475569)),
  'Testing' => (Icons.science_rounded, const Color(0xFF16A34A)),
  _ => (Icons.code_rounded, const Color(0xFF4F46E5)),
};

/// Indigo→violet "Random Interview" banner.
class RandomInterviewBanner extends StatelessWidget {
  const RandomInterviewBanner({
    required this.onTap,
    this.subtitle = '10 questions across all levels',
    super.key,
  });

  final VoidCallback onTap;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: onTap,
      gradient: const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF6D4BF0), Color(0xFF9A6CF6)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      shadows: [
        BoxShadow(
          color: const Color(0xFF5B4BEA).withValues(alpha: 0.3),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      semanticLabel: 'Start a random interview: $subtitle',
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Icon(
                Icons.shuffle_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Random Interview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF5B4BEA),
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered question card with track / difficulty / topic tags.
class InterviewQuestionCard extends ConsumerWidget {
  const InterviewQuestionCard({
    required this.question,
    required this.number,
    required this.onTap,
    super.key,
  });

  final InterviewQuestion question;
  final int number;
  final VoidCallback onTap;

  static const _numberColors = [
    Color(0xFF2563EB),
    Color(0xFF4338CA),
    Color(0xFFDB2777),
    Color(0xFFEA7A0B),
    Color(0xFF16A34A),
    Color(0xFF4F46E5),
    Color(0xFFDC2626),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(interviewStatusProvider(question.id));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = isDarkTheme(context);
    final numberColor = _numberColors[(number - 1) % _numberColors.length];
    final nc = dark
        ? Color.lerp(numberColor, Colors.white, 0.35)!
        : numberColor;
    final diff = DashColors.difficulty(question.difficulty, dark: dark);
    final blue = dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final purple = dark ? AppColors.purpleLight : const Color(0xFF6D3AED);
    final statusLabel = switch (status) {
      InterviewStatus.known => 'Known',
      InterviewStatus.practice => 'Needs practice',
      InterviewStatus.notStarted => 'Not reviewed',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapCard(
        onTap: onTap,
        radius: AppRadius.lgAll,
        borderColor: scheme.outlineVariant.withValues(alpha: dark ? 1 : 0.6),
        padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
        semanticLabel:
            'Question $number: ${question.question}. '
            '${question.category.label}, ${question.difficulty.label}, '
            '${question.topic}. $statusLabel',
        child: Row(
          children: [
            ExcludeSemantics(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: nc.withValues(alpha: dark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: nc,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (status != InterviewStatus.notStarted)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Icon(
                        status == InterviewStatus.known
                            ? Icons.check_circle_rounded
                            : Icons.replay_circle_filled_rounded,
                        size: 18,
                        color: status == InterviewStatus.known
                            ? DashColors.easy
                            : DashColors.medium,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.question,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniTag(question.category.label, blue),
                        _MiniTag(question.difficulty.label, diff),
                        _MiniTag(question.topic, purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            BookmarkButton(type: BookmarkType.interview, itemId: question.id),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkTheme(context) ? 0.2 : 0.1),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Difficulty filter/badge bars: Easy fills one bar, Hard all three.
Widget difficultyBars(Difficulty d, Color color, {double size = 14}) =>
    SignalBars(color: color, filled: d.index + 1, size: size);
