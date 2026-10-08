import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'syntax_highlighter.dart';

/// Reusable syntax-highlighted code block with a language label, copy button
/// and an expand/collapse toggle for long snippets.
class CodeBlock extends StatefulWidget {
  const CodeBlock({
    required this.code,
    this.language = 'jsx',
    this.title,
    this.collapsedLines = 14,
    this.showLineNumbers = true,
    super.key,
  });

  final String code;
  final String language;
  final String? title;

  /// Snippets longer than this start collapsed.
  final int collapsedLines;
  final bool showLineNumbers;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  late List<TextSpan> _spans;
  late int _lineCount;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void didUpdateWidget(CodeBlock old) {
    super.didUpdateWidget(old);
    if (old.code != widget.code || old.language != widget.language) _compute();
  }

  void _compute() {
    final code = widget.code.trimRight();
    _spans = SyntaxHighlighter.highlight(code, widget.language);
    _lineCount = '\n'.allMatches(code).length + 1;
  }

  bool get _collapsible => _lineCount > widget.collapsedLines;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code.trimRight()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  String get _languageLabel => switch (widget.language.toLowerCase()) {
    'js' || 'javascript' => 'JavaScript',
    'jsx' => 'JSX',
    'ts' || 'typescript' => 'TypeScript',
    'tsx' => 'TSX',
    'bash' || 'sh' || 'shell' => 'Terminal',
    'json' => 'JSON',
    'css' => 'CSS',
    'html' => 'HTML',
    _ => widget.language.toUpperCase(),
  };

  @override
  Widget build(BuildContext context) {
    const lineHeight = 13 * 1.55;
    final collapsedHeight = widget.collapsedLines * lineHeight + 24;
    final textScaler = MediaQuery.textScalerOf(context);

    final codeText = Text.rich(
      TextSpan(style: SyntaxHighlighter.base, children: _spans),
      softWrap: false,
    );

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showLineNumbers)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Text(
                    List.generate(_lineCount, (i) => '${i + 1}').join('\n'),
                    textAlign: TextAlign.right,
                    style: SyntaxHighlighter.base.copyWith(
                      color: AppColors.codeComment.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            SelectionArea(child: codeText),
          ],
        ),
      ),
    );

    return Semantics(
      label: '$_languageLabel code example',
      container: true,
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: ColoredBox(
          color: AppColors.codeBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                language: _languageLabel,
                title: widget.title,
                onCopy: _copy,
                expanded: _expanded,
                onToggleExpand: _collapsible
                    ? () => setState(() => _expanded = !_expanded)
                    : null,
              ),
              AnimatedSize(
                duration: AppDurations.medium,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _collapsible && !_expanded
                    ? Stack(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: textScaler.scale(collapsedHeight),
                            ),
                            child: ClipRect(child: body),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 56,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.codeBackground.withValues(
                                        alpha: 0,
                                      ),
                                      AppColors.codeBackground,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : body,
              ),
              if (_collapsible)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    color: AppColors.codeHeader,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: Text(
                      _expanded ? 'Show less' : 'Show all $_lineCount lines',
                      style: const TextStyle(
                        color: AppColors.codeFunction,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.language,
    required this.onCopy,
    required this.expanded,
    this.title,
    this.onToggleExpand,
  });

  final String language;
  final String? title;
  final VoidCallback onCopy;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.codeHeader,
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.35),
              borderRadius: AppRadius.smAll,
            ),
            child: Text(
              language,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.codeText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else
            const Spacer(),
          if (onToggleExpand != null)
            IconButton(
              tooltip: expanded ? 'Collapse code' : 'Expand code',
              onPressed: onToggleExpand,
              icon: Icon(
                expanded
                    ? Icons.unfold_less_rounded
                    : Icons.unfold_more_rounded,
                color: AppColors.codeText,
                size: 20,
              ),
            ),
          IconButton(
            tooltip: 'Copy code',
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              color: AppColors.codeText,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
