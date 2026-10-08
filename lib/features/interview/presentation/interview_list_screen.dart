import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/interview_question.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/common.dart';
import '../providers/interview_providers.dart';
import 'interview_widgets.dart';

/// Questions of one difficulty, with an optional React / Next.js filter.
class InterviewListScreen extends ConsumerStatefulWidget {
  const InterviewListScreen({required this.difficulty, super.key});
  final Difficulty difficulty;

  @override
  ConsumerState<InterviewListScreen> createState() =>
      _InterviewListScreenState();
}

class _InterviewListScreenState extends ConsumerState<InterviewListScreen> {
  Track? _track;

  void _open(List<InterviewQuestion> list, String id) {
    ref
        .read(interviewSessionProvider.notifier)
        .startWith('${widget.difficulty.label} questions', list);
    context.push(AppRoutes.interviewQuestion(id));
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(
      interviewByDifficultyProvider(widget.difficulty),
    );
    final summary = ref
        .watch(interviewProgressProvider(widget.difficulty))
        .value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.difficulty.label} questions')),
      bottomNavigationBar: const BannerAdWidget(),
      body: AsyncValueView(
        value: questions,
        onRetry: () => ref.invalidate(interviewQuestionsProvider),
        data: (all) {
          final list = _track == null
              ? all
              : all.where((q) => q.category == _track).toList();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverList.list(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              DifficultyBadge(widget.difficulty),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  '${summary?.done ?? 0} / ${summary?.total ?? all.length} reviewed',
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AnimatedProgressBar(value: summary?.fraction ?? 0),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: list.isEmpty
                                  ? null
                                  : () => _open(list, list.first.id),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start practice'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<Track?>(
                      segments: const [
                        ButtonSegment(value: null, label: Text('All')),
                        ButtonSegment(value: Track.react, label: Text('React')),
                        ButtonSegment(
                          value: Track.next,
                          label: Text('Next.js'),
                        ),
                      ],
                      selected: {_track},
                      onSelectionChanged: (s) =>
                          setState(() => _track = s.first),
                    ),
                  ],
                ),
              ),
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
                    onTap: () => _open(list, list[i].id),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
