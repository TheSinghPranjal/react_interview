import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/lesson.dart';
import '../../../../shared/widgets/code_block.dart';
import '../../../../shared/widgets/rich_content.dart';

/// Card with a header that expands / collapses its body.
class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    required this.title,
    required this.child,
    this.icon,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final bool initiallyExpanded;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              borderRadius: AppRadius.lgAll,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: theme.colorScheme.primary),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppDurations.fast,
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// "Tap to reveal" card used for interview questions and hidden answers.
class RevealCard extends StatefulWidget {
  const RevealCard({
    required this.question,
    required this.answer,
    this.label = 'Interview question',
    super.key,
  });

  final String question;
  final String answer;
  final String label;

  @override
  State<RevealCard> createState() => _RevealCardState();
}

class _RevealCardState extends State<RevealCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          InlineRichText(widget.question, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AnimatedCrossFade(
            duration: AppDurations.medium,
            crossFadeState: _revealed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _revealed = true),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Tap to reveal answer'),
              ),
            ),
            secondChild: RichContent(
              widget.answer,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Before / after code comparison with a segmented toggle.
class BeforeAfterView extends StatefulWidget {
  const BeforeAfterView({required this.data, super.key});
  final BeforeAfter data;

  @override
  State<BeforeAfterView> createState() => _BeforeAfterViewState();
}

class _BeforeAfterViewState extends State<BeforeAfterView> {
  bool _after = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(d.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.close_rounded),
              label: Text('Before'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.check_rounded),
              label: Text('After'),
            ),
          ],
          selected: {_after},
          onSelectionChanged: (s) => setState(() => _after = s.first),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: AppDurations.medium,
          child: CodeBlock(
            key: ValueKey(_after),
            code: _after ? d.after : d.before,
            language: d.language,
            title: _after ? 'Improved' : 'Problematic',
          ),
        ),
        if (d.explanation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          RichContent(d.explanation, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// Horizontal deck of flip cards.
class FlashcardDeck extends StatefulWidget {
  const FlashcardDeck({required this.cards, super.key});
  final List<Flashcard> cards;

  @override
  State<FlashcardDeck> createState() => _FlashcardDeckState();
}

class _FlashcardDeckState extends State<FlashcardDeck> {
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.textScalerOf(context).scale(190);
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.cards.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: FlipCard(card: widget.cards[i]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Card ${_page + 1} of ${widget.cards.length} · tap to flip',
          style: theme.textTheme.labelMedium,
        ),
      ],
    );
  }
}

class FlipCard extends StatefulWidget {
  const FlipCard({required this.card, super.key});
  final Flashcard card;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.medium + const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _flip() =>
      _c.isCompleted || _c.velocity > 0 ? _c.reverse() : _c.forward();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Flashcard. ${widget.card.front}',
      hint: 'Double tap to flip',
      child: GestureDetector(
        onTap: _flip,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final angle = _c.value * math.pi;
            final showBack = angle > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _face(
                        context,
                        widget.card.back,
                        theme.colorScheme.secondary,
                        'Answer',
                      ),
                    )
                  : _face(
                      context,
                      widget.card.front,
                      theme.colorScheme.primary,
                      'Question',
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _face(BuildContext context, String text, Color color, String label) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: InlineRichText(text, style: theme.textTheme.titleMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual state of an answer option after submission.
enum OptionState { idle, correct, incorrect, revealedCorrect, dimmed }

/// Large, accessible answer button. Correctness is conveyed by icon + label,
/// not color alone.
class AnswerOptionButton extends StatelessWidget {
  const AnswerOptionButton({
    required this.label,
    required this.text,
    required this.state,
    this.onTap,
    super.key,
  });

  final String label;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final success = dark ? AppColors.successLight : AppColors.success;
    final error = dark ? AppColors.errorLight : AppColors.error;

    final (
      Color border,
      Color bg,
      IconData? icon,
      String? status,
    ) = switch (state) {
      OptionState.correct => (
        success,
        success.withValues(alpha: 0.12),
        Icons.check_circle_rounded,
        'Your answer, correct',
      ),
      OptionState.revealedCorrect => (
        success,
        success.withValues(alpha: 0.08),
        Icons.check_circle_outline_rounded,
        'Correct answer',
      ),
      OptionState.incorrect => (
        error,
        error.withValues(alpha: 0.1),
        Icons.cancel_rounded,
        'Your answer, incorrect',
      ),
      OptionState.dimmed => (
        theme.colorScheme.outlineVariant,
        theme.colorScheme.surface,
        null,
        null,
      ),
      OptionState.idle => (
        theme.colorScheme.outlineVariant,
        theme.colorScheme.surface,
        null,
        null,
      ),
    };

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: 'Option $label: $text${status == null ? '' : '. $status'}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: border,
            width: state == OptionState.idle || state == OptionState.dimmed
                ? 1.2
                : 2,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: border.withValues(alpha: 0.15),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                              state == OptionState.idle ||
                                  state == OptionState.dimmed
                              ? theme.colorScheme.primary
                              : border,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Opacity(
                        opacity: state == OptionState.dimmed ? 0.6 : 1,
                        child: InlineRichText(
                          text,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(icon, color: border),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Feedback banner shown after answering.
class AnswerFeedback extends StatelessWidget {
  const AnswerFeedback({
    required this.correct,
    required this.explanation,
    this.correctAnswer,
    this.xp,
    super.key,
  });

  final bool correct;
  final String explanation;
  final String? correctAnswer;
  final int? xp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final color = correct
        ? (dark ? AppColors.successLight : AppColors.success)
        : (dark ? AppColors.warningLight : AppColors.warning);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: AppDurations.slow,
                  curve: Curves.elasticOut,
                  builder: (context, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: Icon(
                    correct
                        ? Icons.check_circle_rounded
                        : Icons.lightbulb_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    correct ? 'Correct!' : 'Not quite.',
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                ),
                if (xp != null && xp! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: AppRadius.pillAll,
                    ),
                    child: Text(
                      '+$xp XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (!correct && correctAnswer != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineRichText(
                'Correct answer: $correctAnswer',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (explanation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              RichContent(explanation, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// In-lesson knowledge check (MCQ, true/false, predict-the-output, ordering).
class LessonQuizView extends StatelessWidget {
  const LessonQuizView({required this.item, required this.number, super.key});

  final LessonQuizItem item;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (item.type) {
      LessonQuizType.mcq => 'Which option is correct?',
      LessonQuizType.trueFalse => 'True or false?',
      LessonQuizType.predictOutput => 'Predict the output',
      LessonQuizType.ordering => 'Put these in order',
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Check $number · $label'.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InlineRichText(item.prompt, style: theme.textTheme.titleMedium),
          if (item.code != null) ...[
            const SizedBox(height: AppSpacing.md),
            CodeBlock(code: item.code!, showLineNumbers: false),
          ],
          const SizedBox(height: AppSpacing.md),
          if (item.type == LessonQuizType.ordering)
            OrderingQuiz(item: item)
          else
            _ChoiceQuiz(item: item),
        ],
      ),
    );
  }
}

class _ChoiceQuiz extends StatefulWidget {
  const _ChoiceQuiz({required this.item});
  final LessonQuizItem item;

  @override
  State<_ChoiceQuiz> createState() => _ChoiceQuizState();
}

class _ChoiceQuizState extends State<_ChoiceQuiz> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final answered = _selected != null;
    final isTf = item.type == LessonQuizType.trueFalse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isTf)
          Row(
            children: [
              for (var i = 0; i < item.options.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: _option(i, answered)),
              ],
            ],
          )
        else
          for (var i = 0; i < item.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _option(i, answered),
            ),
        AnimatedSize(
          duration: AppDurations.medium,
          child: answered
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: AnswerFeedback(
                    correct: _selected == item.correctAnswer,
                    correctAnswer: item.options[item.correctAnswer],
                    explanation: item.explanation,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (answered)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Try again'),
            ),
          ),
      ],
    );
  }

  Widget _option(int i, bool answered) {
    final item = widget.item;
    final state = !answered
        ? OptionState.idle
        : i == _selected
        ? (i == item.correctAnswer
              ? OptionState.correct
              : OptionState.incorrect)
        : i == item.correctAnswer
        ? OptionState.revealedCorrect
        : OptionState.dimmed;
    return AnswerOptionButton(
      label: item.type == LessonQuizType.trueFalse
          ? (i == 0 ? 'T' : 'F')
          : String.fromCharCode(65 + i),
      text: item.options[i],
      state: state,
      onTap: answered ? null : () => setState(() => _selected = i),
    );
  }
}

/// Drag-and-drop ordering exercise.
class OrderingQuiz extends StatefulWidget {
  const OrderingQuiz({required this.item, super.key});
  final LessonQuizItem item;

  @override
  State<OrderingQuiz> createState() => _OrderingQuizState();
}

class _OrderingQuizState extends State<OrderingQuiz> {
  late List<String> _order;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    final items = widget.item.items;
    // Deterministic rotation + reverse so the start is never already correct.
    _order = [...items.reversed];
    if (items.length > 2) {
      _order = [..._order.sublist(1), _order.first];
    }
    if (_listEquals(_order, items)) _order = [...items.reversed];
    _correct = null;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Drag the handles to reorder, then check.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: _correct == true
              ? (_, _) {}
              : (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _order.removeAt(oldIndex);
                    _order.insert(newIndex, item);
                    _correct = null;
                  });
                },
          children: [
            for (var i = 0; i < _order.length; i++)
              Padding(
                key: ValueKey(_order[i]),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: AppRadius.mdAll,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    title: InlineRichText(
                      _order[i],
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          semanticLabel: 'Drag to reorder',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => setState(
                  () => _correct = _listEquals(_order, widget.item.items),
                ),
                child: const Text('Check order'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => setState(_shuffle),
              child: const Text('Reset'),
            ),
          ],
        ),
        if (_correct != null) ...[
          const SizedBox(height: AppSpacing.md),
          AnswerFeedback(
            correct: _correct!,
            correctAnswer: _correct!
                ? null
                : widget.item.items
                      .asMap()
                      .entries
                      .map((e) => '${e.key + 1}. ${e.value}')
                      .join('  '),
            explanation: widget.item.explanation,
          ),
        ],
      ],
    );
  }
}

/// Highlighted callout (tips, mistakes, real-world examples).
class Callout extends StatelessWidget {
  const Callout({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final c = dark ? Color.lerp(color, Colors.white, 0.4)! : color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.16 : 0.07),
        borderRadius: AppRadius.lgAll,
        border: Border(left: BorderSide(color: c, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: c),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
