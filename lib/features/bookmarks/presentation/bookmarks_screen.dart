import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/models/mcq_question.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../learn/presentation/widgets/interactive_widgets.dart';
import '../providers/bookmarks_provider.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: BookmarkType.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookmarks'),
          bottom: TabBar(
            tabs: [for (final t in BookmarkType.values) Tab(text: t.label)],
          ),
        ),
        body: const TabBarView(
          children: [
            _LessonBookmarks(),
            _InterviewBookmarks(),
            _McqBookmarks(),
          ],
        ),
      ),
    );
  }
}

Widget _empty(String what) => EmptyState(
  icon: Icons.bookmark_border_rounded,
  title: 'No saved $what yet',
  message: 'Tap the bookmark icon on any $what to save it here.',
);

class _LessonBookmarks extends ConsumerWidget {
  const _LessonBookmarks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks = ref.watch(bookmarksByTypeProvider(BookmarkType.lesson));
    if (marks.isEmpty) return _empty('lessons');
    return AsyncValueView(
      value: ref.watch(allLessonsProvider),
      data: (all) {
        final byId = {for (final l in all) l.id: l};
        final items = [for (final b in marks) ?byId[b.itemId]];
        if (items.isEmpty) return _empty('lessons');
        return ListView.separated(
          padding: AppSpacing.screen,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final l = items[i];
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(l.title),
                subtitle: Text('${l.track.label} · ${l.category}'),
                trailing: BookmarkButton(
                  type: BookmarkType.lesson,
                  itemId: l.id,
                ),
                onTap: () => context.push(AppRoutes.lesson(l.track, l.id)),
              ),
            );
          },
        );
      },
    );
  }
}

class _InterviewBookmarks extends ConsumerWidget {
  const _InterviewBookmarks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks = ref.watch(bookmarksByTypeProvider(BookmarkType.interview));
    if (marks.isEmpty) return _empty('interview questions');
    return AsyncValueView(
      value: ref.watch(interviewQuestionsProvider),
      data: (all) {
        final byId = {for (final q in all) q.id: q};
        final items = [for (final b in marks) ?byId[b.itemId]];
        return ListView.separated(
          padding: AppSpacing.screen,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final q = items[i];
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(q.question),
                subtitle: Text(
                  '${q.category.label} · ${q.difficulty.label} · ${q.topic}',
                ),
                trailing: BookmarkButton(
                  type: BookmarkType.interview,
                  itemId: q.id,
                ),
                onTap: () => context.push(AppRoutes.interviewQuestion(q.id)),
              ),
            );
          },
        );
      },
    );
  }
}

class _McqBookmarks extends ConsumerWidget {
  const _McqBookmarks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks = ref.watch(bookmarksByTypeProvider(BookmarkType.mcq));
    if (marks.isEmpty) return _empty('quiz questions');
    return AsyncValueView(
      value: ref.watch(mcqQuestionsProvider),
      data: (all) {
        final byId = {for (final q in all) q.id: q};
        final items = [for (final b in marks) ?byId[b.itemId]];
        return ListView.separated(
          padding: AppSpacing.screen,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final q = items[i];
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(q.question),
                subtitle: Text(
                  '${q.category.label} · ${q.difficulty.label} · ${q.topic}',
                ),
                trailing: BookmarkButton(type: BookmarkType.mcq, itemId: q.id),
                onTap: () => showMcqSheet(context, q),
              ),
            );
          },
        );
      },
    );
  }
}

/// Shows an MCQ with its answer highlighted (used by bookmarks & search).
Future<void> showMcqSheet(BuildContext context, McqQuestion q) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      TrackBadge(q.category),
                      DifficultyBadge(q.difficulty),
                    ],
                  ),
                ),
                BookmarkButton(type: BookmarkType.mcq, itemId: q.id),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            InlineRichText(q.question, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AnswerOptionButton(
                  label: String.fromCharCode(65 + i),
                  text: q.options[i],
                  state: i == q.correctAnswer
                      ? OptionState.revealedCorrect
                      : OptionState.dimmed,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            RichContent(q.explanation, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    },
  );
}
