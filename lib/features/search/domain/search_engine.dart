import 'package:flutter/foundation.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/interview_question.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/mcq_question.dart';

enum SearchResultType {
  lesson('Lesson'),
  interview('Interview'),
  mcq('Quiz');

  const SearchResultType(this.label);
  final String label;
}

@immutable
class SearchResult {
  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.snippet,
    required this.track,
    required this.meta,
    required this.score,
  });

  final SearchResultType type;
  final String id;
  final String title;
  final String snippet;
  final Track track;

  /// Secondary label (category, topic, difficulty).
  final String meta;
  final int score;
}

class _Entry {
  _Entry({
    required this.type,
    required this.id,
    required this.title,
    required this.tags,
    required this.body,
    required this.track,
    required this.meta,
  }) : titleLower = title.toLowerCase(),
       tagsLower = tags.toLowerCase(),
       bodyLower = body.toLowerCase();

  final SearchResultType type;
  final String id;
  final String title;
  final String tags;
  final String body;
  final Track track;
  final String meta;
  final String titleLower;
  final String tagsLower;
  final String bodyLower;
}

/// Pre-lowercased in-memory index over all local content. Building it once
/// keeps each keystroke cheap (a linear scan over ~500 small entries).
class SearchIndex {
  SearchIndex._(this._entries);

  factory SearchIndex.build({
    required List<Lesson> lessons,
    required List<InterviewQuestion> interview,
    required List<McqQuestion> mcqs,
  }) {
    return SearchIndex._([
      for (final l in lessons)
        _Entry(
          type: SearchResultType.lesson,
          id: l.id,
          title: l.title,
          tags: '${l.category} ${l.keyConcepts.join(' ')} ${l.track.label}',
          body: l.searchBody,
          track: l.track,
          meta: '${l.track.label} · ${l.category}',
        ),
      for (final q in interview)
        _Entry(
          type: SearchResultType.interview,
          id: q.id,
          title: q.question,
          tags: '${q.topic} ${q.category.label} ${q.keyPoints.join(' ')}',
          body: '${q.shortAnswer} ${q.detailedAnswer}',
          track: q.category,
          meta: '${q.category.label} · ${q.difficulty.label} · ${q.topic}',
        ),
      for (final q in mcqs)
        _Entry(
          type: SearchResultType.mcq,
          id: q.id,
          title: q.question,
          tags: '${q.topic} ${q.category.label}',
          body: '${q.options.join(' ')} ${q.explanation}',
          track: q.category,
          meta: '${q.category.label} · ${q.difficulty.label} · ${q.topic}',
        ),
    ]);
  }

  final List<_Entry> _entries;

  int get size => _entries.length;

  /// Returns results where every query term appears somewhere in the item,
  /// ranked by where the terms matched (title > tags > body).
  List<SearchResult> search(
    String query, {
    int limit = 80,
    SearchResultType? type,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    final results = <SearchResult>[];
    for (final e in _entries) {
      if (type != null && e.type != type) continue;
      var score = 0;
      var allMatch = true;
      for (final t in terms) {
        if (e.titleLower.contains(t)) {
          score += e.titleLower.startsWith(t) ? 30 : 20;
        } else if (e.tagsLower.contains(t)) {
          score += 10;
        } else if (e.bodyLower.contains(t)) {
          score += 3;
        } else {
          allMatch = false;
          break;
        }
      }
      if (!allMatch) continue;
      if (e.titleLower == q) score += 200;
      if (e.titleLower.contains(q)) score += 60;
      if (e.type == SearchResultType.lesson) score += 5;
      results.add(
        SearchResult(
          type: e.type,
          id: e.id,
          title: e.title,
          snippet: snippetFor(e.body, terms.first),
          track: e.track,
          meta: e.meta,
          score: score,
        ),
      );
    }
    results.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.title.length.compareTo(b.title.length);
    });
    return results.length > limit ? results.sublist(0, limit) : results;
  }

  /// A short excerpt of [body] around the first occurrence of [term].
  static String snippetFor(String body, String term, {int radius = 70}) {
    final clean = body.replaceAll(RegExp(r'\s+'), ' ').replaceAll('`', '');
    final i = clean.toLowerCase().indexOf(term.toLowerCase());
    if (i < 0) {
      return clean.length <= radius * 2
          ? clean
          : '${clean.substring(0, radius * 2).trimRight()}…';
    }
    final start = (i - radius).clamp(0, clean.length);
    final end = (i + term.length + radius).clamp(0, clean.length);
    return '${start > 0 ? '…' : ''}${clean.substring(start, end).trim()}'
        '${end < clean.length ? '…' : ''}';
  }
}
