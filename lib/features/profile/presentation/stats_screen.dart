import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_progress.dart';
import '../../../shared/widgets/common.dart';
import '../../progress/providers/progress_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quizStatsProvider);
    final now = ref.watch(clockProvider)();

    final last7 = [
      for (var i = 6; i >= 0; i--)
        () {
          final d = DateTime(now.year, now.month, now.day - i);
          return (
            label: AppDates.weekdayShort[d.weekday - 1],
            value: (s.quizzesByDay[AppDates.dayKey(d)] ?? 0).toDouble(),
          );
        }(),
    ];
    final recentScores = [
      for (final (i, h) in s.history.take(10).toList().reversed.indexed)
        (label: '#${i + 1}', value: h.percent.toDouble()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          ResponsiveGrid(
            minItemWidth: 100,
            children: [
              StatTile(
                icon: Icons.quiz_rounded,
                label: 'Total quizzes',
                value: '${s.totalQuizzes}',
              ),
              StatTile(
                icon: Icons.help_outline_rounded,
                label: 'Answered',
                value: '${s.questionsAnswered}',
              ),
              StatTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Correct',
                value: '${s.correctAnswers}',
              ),
              StatTile(
                icon: Icons.cancel_outlined,
                label: 'Incorrect',
                value: '${s.incorrectAnswers}',
              ),
              StatTile(
                icon: Icons.emoji_events_outlined,
                label: 'Best score',
                value: '${s.bestScorePercent}%',
              ),
              StatTile(
                icon: Icons.functions_rounded,
                label: 'Average score',
                value: '${s.averageScorePercent.round()}%',
              ),
            ],
          ),
          const SectionHeader('Accuracy by topic'),
          AppCard(
            child: Column(
              children: [
                for (final t in Track.values)
                  _AccuracyRow(label: t.label, counter: s.category(t.slug)),
              ],
            ),
          ),
          const SectionHeader('Accuracy by difficulty'),
          AppCard(
            child: Column(
              children: [
                for (final d in Difficulty.values)
                  _AccuracyRow(label: d.label, counter: s.difficulty(d.slug)),
              ],
            ),
          ),
          const SectionHeader('Quizzes per day (last 7 days)'),
          AppCard(
            child: _BarChart(
              data: last7,
              valueLabel: (v) => '${v.round()}',
              unit: 'quizzes',
            ),
          ),
          const SectionHeader('Recent scores'),
          AppCard(
            child: recentScores.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('Finish a quiz to see your score history.'),
                  )
                : _BarChart(
                    data: recentScores,
                    maxValue: 100,
                    valueLabel: (v) => '${v.round()}%',
                    unit: 'score',
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _AccuracyRow extends StatelessWidget {
  const _AccuracyRow({required this.label, required this.counter});
  final String label;
  final AccuracyCounter counter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (counter.accuracy * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              Text(
                counter.answered == 0
                    ? 'No answers yet'
                    : '$pct%  ·  ${counter.correct}/${counter.answered}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedProgressBar(
            value: counter.accuracy,
            semanticsLabel: '$label accuracy',
          ),
        ],
      ),
    );
  }
}

/// Minimal single-series vertical bar chart. One hue (primary), thin bars
/// with rounded data-ends on a recessive baseline, values printed above bars
/// in text color, and a tooltip per bar.
class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.data,
    required this.valueLabel,
    required this.unit,
    this.maxValue,
  });

  final List<({String label, double value})> data;
  final String Function(double) valueLabel;
  final String unit;
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max =
        maxValue ??
        data
            .fold<double>(0, (m, e) => e.value > m ? e.value : m)
            .clamp(1, double.infinity);
    const chartHeight = 120.0;
    return Column(
      children: [
        SizedBox(
          height: chartHeight + 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final e in data)
                Expanded(
                  child: Tooltip(
                    message: '${e.label}: ${valueLabel(e.value)} $unit',
                    triggerMode: TooltipTriggerMode.tap,
                    child: Semantics(
                      label: '${e.label}: ${valueLabel(e.value)} $unit',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (e.value > 0)
                            Text(
                              valueLabel(e.value),
                              style: theme.textTheme.labelSmall,
                            ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: e.value / max),
                            duration: AppDurations.slow,
                            curve: Curves.easeOutCubic,
                            builder: (context, f, _) => Container(
                              width: 14,
                              height: (chartHeight * f).clamp(2, chartHeight),
                              decoration: BoxDecoration(
                                color: e.value > 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final e in data)
              Expanded(
                child: Text(
                  e.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
