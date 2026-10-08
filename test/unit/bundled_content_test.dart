import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:react_interview/core/constants/app_constants.dart';
import 'package:react_interview/data/models/enums.dart';
import 'package:react_interview/data/models/interview_question.dart';
import 'package:react_interview/data/models/json_utils.dart';
import 'package:react_interview/data/models/lesson.dart';
import 'package:react_interview/data/models/mcq_question.dart';

/// Validates the real bundled content so content edits can't break the app.
List<JsonMap> _read(String asset) {
  final raw = File(asset).readAsStringSync();
  return (jsonDecode(raw) as List).cast<Map<String, Object?>>();
}

void main() {
  group('Bundled content', () {
    test('lessons: 50+ per track, unique ids, all parse', () {
      final ids = <String>{};
      for (final (asset, track) in [
        (AppConstants.reactLessonsAsset, Track.react),
        (AppConstants.nextLessonsAsset, Track.next),
      ]) {
        final raw = _read(asset);
        expect(raw.length, greaterThanOrEqualTo(50), reason: asset);
        for (final j in raw) {
          final l = Lesson.fromJson(j);
          expect(ids.add(l.id), isTrue, reason: 'duplicate lesson ${l.id}');
          expect(l.track, track);
          expect(l.sections, isNotEmpty, reason: l.id);
          expect(l.codeExamples, isNotEmpty, reason: l.id);
          expect(l.commonMistakes, isNotEmpty, reason: l.id);
          expect(l.interviewTip, isNotEmpty, reason: l.id);
          expect(l.realWorldExample, isNotEmpty, reason: l.id);
          expect(
            l.quiz.length,
            (j['quiz']! as List).length,
            reason: 'invalid quiz item in ${l.id}',
          );
        }
      }
    });

    test('interview: exactly 50 easy, 50 medium, 50 hard', () {
      final raw = _read(AppConstants.interviewQuestionsAsset);
      final qs = raw.map(InterviewQuestion.fromJson).toList();
      expect(qs, hasLength(150));
      expect(qs.map((q) => q.id).toSet(), hasLength(150));
      expect(qs.map((q) => q.question).toSet(), hasLength(150));
      for (final d in Difficulty.values) {
        final level = qs.where((q) => q.difficulty == d);
        expect(level, hasLength(50), reason: d.label);
        // Reasonably balanced between React and Next.js.
        expect(
          level.where((q) => q.category == Track.react).length,
          inInclusiveRange(20, 30),
        );
      }
      for (final q in qs) {
        expect(q.keyPoints, isNotEmpty, reason: q.id);
        expect(q.commonMistake, isNotEmpty, reason: q.id);
        expect(q.interviewTip, isNotEmpty, reason: q.id);
      }
    });

    test('mcq: 200+ unique questions, 4 options, valid answers', () {
      final raw = _read(AppConstants.mcqQuestionsAsset);
      final qs = raw.map(McqQuestion.fromJson).toList();
      expect(qs.length, greaterThanOrEqualTo(200));
      expect(qs.map((q) => q.id).toSet(), hasLength(qs.length));
      expect(
        qs.map((q) => q.question.trim().toLowerCase()).toSet(),
        hasLength(qs.length),
        reason: 'duplicate question text',
      );
      for (final q in qs) {
        expect(q.options, hasLength(4), reason: q.id);
        expect(
          q.options.toSet(),
          hasLength(4),
          reason: 'duplicate options ${q.id}',
        );
        expect(q.correctAnswer, inInclusiveRange(0, 3));
        expect(q.explanation, isNotEmpty, reason: q.id);
        for (final o in q.options) {
          expect(o.toLowerCase(), isNot(contains('all of the above')));
          expect(o.toLowerCase(), isNot(contains('none of the above')));
        }
      }
      expect(
        qs.where((q) => q.category == Track.react).length,
        greaterThanOrEqualTo(100),
      );
      expect(
        qs.where((q) => q.category == Track.next).length,
        greaterThanOrEqualTo(100),
      );
      for (final d in Difficulty.values) {
        expect(
          qs.where((q) => q.difficulty == d).length,
          greaterThanOrEqualTo(50),
        );
      }
    });
  });
}
