import 'package:flutter/material.dart';

/// Displays [text] with every case-insensitive occurrence of each word in
/// [query] highlighted.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    required this.query,
    this.style,
    this.maxLines,
    super.key,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  /// Computes highlight ranges; exposed for testing.
  static List<(int, int)> matchRanges(String text, String query) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return const [];
    final lower = text.toLowerCase();
    final ranges = <(int, int)>[];
    for (final t in terms) {
      var i = lower.indexOf(t);
      while (i >= 0) {
        ranges.add((i, i + t.length));
        i = lower.indexOf(t, i + t.length);
      }
    }
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    // Merge overlaps.
    final merged = <(int, int)>[];
    for (final r in ranges) {
      if (merged.isNotEmpty && r.$1 <= merged.last.$2) {
        final last = merged.removeLast();
        merged.add((last.$1, r.$2 > last.$2 ? r.$2 : last.$2));
      } else {
        merged.add(r);
      }
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = style ?? DefaultTextStyle.of(context).style;
    final highlight = base.copyWith(
      backgroundColor: scheme.primary.withValues(alpha: 0.18),
      fontWeight: FontWeight.w700,
      color: scheme.primary,
    );
    final ranges = matchRanges(text, query);
    final spans = <TextSpan>[];
    var last = 0;
    for (final (start, end) in ranges) {
      if (start > last) spans.add(TextSpan(text: text.substring(last, start)));
      spans.add(TextSpan(text: text.substring(start, end), style: highlight));
      last = end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
