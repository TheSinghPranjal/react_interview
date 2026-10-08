import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/celebration.dart';
import '../../../shared/widgets/code_block.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../progress/providers/progress_provider.dart';
import '../providers/learn_providers.dart';
import 'widgets/interactive_widgets.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final _scroll = ScrollController();
  final _readProgress = ValueNotifier<double>(0);
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(progressProvider.notifier).openLesson(widget.lessonId);
      }
    });
  }

  @override
  void didUpdateWidget(LessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId) {
      _celebrate = false;
      ref.read(progressProvider.notifier).openLesson(widget.lessonId);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _readProgress.value = max <= 0 ? 1 : (_scroll.offset / max).clamp(0, 1);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _readProgress.dispose();
    super.dispose();
  }

  Future<void> _complete(Lesson lesson) async {
    final outcome = ref
        .read(progressProvider.notifier)
        .completeLesson(lesson.id);
    if (!outcome.hasNews) return;
    setState(() => _celebrate = true);
    await showActivityOutcome(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonByIdProvider(widget.lessonId));
    return Scaffold(
      appBar: AppBar(
        title: Text(lessonAsync.value?.category ?? 'Lesson'),
        actions: [
          BookmarkButton(type: BookmarkType.lesson, itemId: widget.lessonId),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: ValueListenableBuilder<double>(
            valueListenable: _readProgress,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 3,
              semanticsLabel: 'Reading progress',
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: AsyncValueView(
        value: lessonAsync,
        onRetry: () => ref.invalidate(allLessonsProvider),
        data: (lesson) {
          if (lesson == null) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Lesson not found',
              message: 'This lesson may have been moved or renamed.',
              action: FilledButton(
                onPressed: () => context.go(AppRoutes.learn),
                child: const Text('Browse lessons'),
              ),
            );
          }
          return Stack(
            children: [
              _LessonBody(
                lesson: lesson,
                controller: _scroll,
                onComplete: () => _complete(lesson),
              ),
              if (_celebrate) const Positioned.fill(child: ConfettiBurst()),
            ],
          );
        },
      ),
    );
  }
}

class _LessonBody extends ConsumerWidget {
  const _LessonBody({
    required this.lesson,
    required this.controller,
    required this.onComplete,
  });

  final Lesson lesson;
  final ScrollController controller;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: AppSpacing.lg);

    final blocks = <Widget>[
      _Header(lesson: lesson),
      if (lesson.keyConcepts.isNotEmpty) ...[
        gap,
        _KeyConcepts(concepts: lesson.keyConcepts),
      ],
      for (var i = 0; i < lesson.sections.length; i++) ...[
        const SizedBox(height: AppSpacing.md),
        ExpandableSection(
          title: lesson.sections[i].title,
          icon: _sectionIcon(lesson.sections[i].title),
          initiallyExpanded: i < 2,
          child: RichContent(lesson.sections[i].content),
        ),
      ],
      for (final example in lesson.codeExamples) ...[
        gap,
        _CodeExampleView(example: example),
      ],
      if (lesson.beforeAfter != null) ...[
        gap,
        BeforeAfterView(data: lesson.beforeAfter!),
      ],
      if (lesson.whenNotToUse.isNotEmpty) ...[
        gap,
        Callout(
          icon: Icons.do_not_disturb_on_outlined,
          title: 'When NOT to use it',
          color: AppColors.purple,
          child: RichContent(
            lesson.whenNotToUse.map((e) => '- $e').join('\n'),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
      if (lesson.commonMistakes.isNotEmpty) ...[
        gap,
        Callout(
          icon: Icons.warning_amber_rounded,
          title: 'Common mistakes',
          color: AppColors.warning,
          child: RichContent(
            lesson.commonMistakes.map((e) => '- $e').join('\n'),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
      if (lesson.realWorldExample.isNotEmpty) ...[
        gap,
        Callout(
          icon: Icons.public_rounded,
          title: 'Real-world example',
          color: AppColors.reactDeep,
          child: RichContent(
            lesson.realWorldExample,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
      if (lesson.interviewTip.isNotEmpty) ...[
        gap,
        Callout(
          icon: Icons.tips_and_updates_rounded,
          title: 'Interview tip',
          color: AppColors.indigo,
          child: RichContent(
            lesson.interviewTip,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
      if (lesson.interviewQuestion != null) ...[
        gap,
        RevealCard(
          question: lesson.interviewQuestion!.question,
          answer: lesson.interviewQuestion!.answer,
        ),
      ],
      if (lesson.flashcards.isNotEmpty) ...[
        const SectionHeader('Flashcards'),
        FlashcardDeck(cards: lesson.flashcards),
      ],
      if (lesson.quiz.isNotEmpty) ...[
        const SectionHeader('Quick quiz'),
        for (var i = 0; i < lesson.quiz.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          LessonQuizView(item: lesson.quiz[i], number: i + 1),
        ],
      ],
      const SizedBox(height: AppSpacing.xl),
      _CompletionSection(lesson: lesson, onComplete: onComplete),
      const SizedBox(height: AppSpacing.xxl),
    ];

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: blocks.length,
      itemBuilder: (context, i) => blocks[i],
    );
  }

  static IconData _sectionIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('what')) return Icons.help_outline_rounded;
    if (t.contains('why')) return Icons.psychology_alt_outlined;
    if (t.contains('when')) return Icons.schedule_rounded;
    if (t.contains('how')) return Icons.settings_suggest_outlined;
    if (t.contains('syntax')) return Icons.code_rounded;
    return Icons.article_outlined;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TrackBadge(lesson.track),
            DifficultyBadge(lesson.difficulty, lessonStyle: true),
            InfoChip(
              icon: Icons.schedule_rounded,
              label: '${lesson.estimatedMinutes} min read',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(lesson.title, style: theme.textTheme.headlineMedium),
        ),
        if (lesson.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineRichText(
            lesson.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyConcepts extends StatelessWidget {
  const _KeyConcepts({required this.concepts});
  final List<String> concepts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Key concepts', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in concepts)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.pillAll,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: InlineRichText(
                  c,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CodeExampleView extends StatelessWidget {
  const _CodeExampleView({required this.example});
  final CodeExample example;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(example.title ?? 'Example', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        CodeBlock(code: example.code, language: example.language),
        if (example.explanation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ExpandableSection(
            title: 'How this code works',
            icon: Icons.lightbulb_outline_rounded,
            initiallyExpanded: true,
            child: RichContent(
              example.explanation,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}

class _CompletionSection extends ConsumerWidget {
  const _CompletionSection({required this.lesson, required this.onComplete});

  final Lesson lesson;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(isLessonCompletedProvider(lesson.id));
    final adjacent = ref.watch(adjacentLessonsProvider(lesson.id)).value;
    final next = adjacent?.$2;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: AppDurations.medium,
          transitionBuilder: (child, a) =>
              ScaleTransition(scale: a, child: child),
          child: done
              ? Container(
                  key: const ValueKey('done'),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: theme.brightness == Brightness.dark
                            ? AppColors.successLight
                            : AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(child: Text('Lesson completed')),
                    ],
                  ),
                )
              : FilledButton.icon(
                  key: const ValueKey('todo'),
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Mark as complete  ·  +${XpRewards.lessonCompleted} XP',
                  ),
                ),
        ),
        if (next != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () =>
                context.pushReplacement(AppRoutes.lesson(next.track, next.id)),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text('Next: ${next.title}', overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );
  }
}
