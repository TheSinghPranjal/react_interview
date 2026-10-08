import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Renders lightweight markdown-ish content used in lesson JSON:
///
/// * blank lines separate paragraphs
/// * lines starting with `- ` are bullets
/// * `inline code` and **bold** spans
class RichContent extends StatelessWidget {
  const RichContent(this.text, {this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge!;
    final blocks = text.trim().split(RegExp(r'\n\s*\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _block(context, blocks[i], base),
        ],
      ],
    );
  }

  Widget _block(BuildContext context, String block, TextStyle base) {
    final lines = block.split('\n');
    final isList = lines.every((l) => l.trimLeft().startsWith('- '));
    if (!isList) {
      return Text.rich(
        TextSpan(children: inlineSpans(context, lines.join(' '), base)),
        style: base,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: AppSpacing.sm),
                  child: Text('•', style: base),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: inlineSpans(
                        context,
                        l.trimLeft().substring(2),
                        base,
                      ),
                    ),
                    style: base,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static final RegExp _inline = RegExp(r'`([^`]+)`|\*\*([^*]+)\*\*');

  /// Splits [text] into spans with inline code and bold support.
  static List<InlineSpan> inlineSpans(
    BuildContext context,
    String text,
    TextStyle base,
  ) {
    final spans = <InlineSpan>[];
    var last = 0;
    final codeStyle = AppTextStyles.inlineCode(
      context,
    ).copyWith(fontSize: (base.fontSize ?? 15) - 1);
    for (final m in _inline.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      if (m[1] != null) {
        spans.add(TextSpan(text: ' ${m[1]} ', style: codeStyle));
      } else {
        spans.add(
          TextSpan(
            text: m[2],
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }
}

/// Text with inline-code formatting only (single paragraph).
class InlineRichText extends StatelessWidget {
  const InlineRichText(this.text, {this.style, this.maxLines, super.key});

  final String text;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium!;
    return Text.rich(
      TextSpan(children: RichContent.inlineSpans(context, text, base)),
      style: base,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
