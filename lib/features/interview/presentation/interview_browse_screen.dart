import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/interview_question.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/dashboard.dart';
import '../providers/interview_providers.dart';
import 'interview_home_screen.dart' show startRandomInterview;
import 'interview_widgets.dart';

enum _Sort {
  recommended('Recommended'),
  easiest('Easiest first'),
  hardest('Hardest first'),
  alphabetical('A → Z');

  const _Sort(this.label);
  final String label;
}

/// All interview questions with track / difficulty / topic filters.
class InterviewBrowseScreen extends ConsumerStatefulWidget {
  const InterviewBrowseScreen({super.key});

  @override
  ConsumerState<InterviewBrowseScreen> createState() =>
      _InterviewBrowseScreenState();
}

class _InterviewBrowseScreenState extends ConsumerState<InterviewBrowseScreen> {
  _Sort _sort = _Sort.recommended;

  List<InterviewQuestion> _sorted(List<InterviewQuestion> list) {
    final out = [...list];
    switch (_sort) {
      case _Sort.recommended:
        break;
      case _Sort.easiest:
        out.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
      case _Sort.hardest:
        out.sort((a, b) => b.difficulty.index.compareTo(a.difficulty.index));
      case _Sort.alphabetical:
        out.sort(
          (a, b) =>
              a.question.toLowerCase().compareTo(b.question.toLowerCase()),
        );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredInterviewQuestionsProvider);
    final filter = ref.watch(interviewFilterProvider);
    final theme = Theme.of(context);
    final canPop = context.canPop();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  DashHero(
                    badge: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canPop) ...[
                          IconButton(
                            tooltip: 'Back',
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 4),
                        ],
                        const ScreenBadge(
                          icon: Icon(Icons.record_voice_over_rounded),
                          label: 'Interview',
                        ),
                      ],
                    ),
                    action: SquareIconButton(
                      icon: Icons.bookmarks_outlined,
                      tooltip: 'Bookmarks',
                      onPressed: () => context.push(AppRoutes.bookmarks),
                    ),
                    semanticTitle: 'Browse interview questions',
                    title: const [TextSpan(text: 'Browse interview questions')],
                    subtitle:
                        'Practice hand-picked questions and improve your '
                        'problem-solving skills.',
                    art: 'assets/images/browse_hero.png',
                    artWidth: 140,
                    artTop: 30,
                    titleFontSize: 24,
                    titleWidthFactor: 1,
                    subtitleWidthFactor: 0.62,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RandomInterviewBanner(
                    subtitle: filter.isEmpty
                        ? '10 questions across all levels'
                        : '10 questions from your filters',
                    onTap: () =>
                        startRandomInterview(context, ref, filter: filter),
                  ),
                  const DashSectionHeader('Filter questions'),
                  const _FilterPills(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${filtered.value?.length ?? '…'} Questions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _SortButton(
                        value: _sort,
                        onChanged: (s) => setState(() => _sort = s),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            ...filtered.when(
              skipLoadingOnReload: true,
              data: (raw) {
                final list = _sorted(raw);
                if (list.isEmpty) {
                  return [
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        title: 'No questions match',
                        message: 'Try removing a filter.',
                        action: TextButton(
                          onPressed: () => ref
                              .read(interviewFilterProvider.notifier)
                              .clear(),
                          child: const Text('Clear filters'),
                        ),
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) => InterviewQuestionCard(
                        question: list[i],
                        number: i + 1,
                        onTap: () {
                          ref
                              .read(interviewSessionProvider.notifier)
                              .startWith('Filtered questions', list);
                          context.push(AppRoutes.interviewQuestion(list[i].id));
                        },
                      ),
                    ),
                  ),
                ];
              },
              loading: () => [
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverToBoxAdapter(
                  child: ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(interviewQuestionsProvider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPills extends ConsumerWidget {
  const _FilterPills();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(interviewFilterProvider);
    final notifier = ref.read(interviewFilterProvider.notifier);
    final dark = isDarkTheme(context);
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        ChoicePill(
          label: 'All',
          selected: filter.isEmpty,
          outlinedSelection: true,
          onTap: notifier.clear,
        ),
        ChoicePill(
          label: 'React',
          leading: const ReactLogo(size: 22, color: Color(0xFF0EA5E9)),
          selected: filter.categories.contains(Track.react),
          outlinedSelection: true,
          onTap: () => notifier.toggleCategory(Track.react),
        ),
        ChoicePill(
          label: 'Next.js',
          leading: const NextLogo(size: 24),
          selected: filter.categories.contains(Track.next),
          outlinedSelection: true,
          onTap: () => notifier.toggleCategory(Track.next),
        ),
        for (final d in Difficulty.values)
          ChoicePill(
            label: d.label,
            leading: difficultyBars(
              d,
              DashColors.difficulty(d, dark: dark),
              size: 16,
            ),
            selected: filter.difficulties.contains(d),
            outlinedSelection: true,
            onTap: () => notifier.toggleDifficulty(d),
          ),
        if (filter.topic != null)
          ChoicePill(
            label: '${filter.topic}  ✕',
            selected: true,
            outlinedSelection: true,
            onTap: () => notifier.setTopic(null),
          ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.value, required this.onChanged});

  final _Sort value;
  final ValueChanged<_Sort> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<_Sort>(
      tooltip: 'Sort questions',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final s in _Sort.values)
          PopupMenuItem(value: s, child: Text(s.label)),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
