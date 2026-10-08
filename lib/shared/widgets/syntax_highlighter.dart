import 'package:flutter/painting.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Lightweight, dependency-free highlighter for JS/JSX/TS/TSX, JSON and shell
/// snippets. It is a single regex pass, fast enough to run on every build of
/// a code block, and produces [TextSpan]s styled for the dark code theme.
abstract final class SyntaxHighlighter {
  static const Set<String> _keywords = {
    'const',
    'let',
    'var',
    'function',
    'return',
    'if',
    'else',
    'for',
    'while',
    'do',
    'switch',
    'case',
    'break',
    'continue',
    'new',
    'this',
    'class',
    'extends',
    'super',
    'import',
    'from',
    'export',
    'default',
    'async',
    'await',
    'try',
    'catch',
    'finally',
    'throw',
    'typeof',
    'instanceof',
    'in',
    'of',
    'null',
    'undefined',
    'true',
    'false',
    'void',
    'yield',
    'interface',
    'type',
    'enum',
    'implements',
    'as',
    'satisfies',
    'readonly',
    'public',
    'private',
    'protected',
    'static',
    'get',
    'set',
    'keyof',
    'declare',
    'delete',
    'debugger',
    'with',
  };

  static const Set<String> _shellKeywords = {
    'npm',
    'npx',
    'pnpm',
    'yarn',
    'bun',
    'cd',
    'export',
    'git',
    'node',
    'echo',
    'mkdir',
    'vercel',
    'docker',
    'run',
    'install',
    'create',
  };

  static final RegExp _jsPattern = RegExp(
    r'(?<comment>//[^\n]*|/\*[\s\S]*?\*/|\{/\*[\s\S]*?\*/\})'
    r'|(?<string>"(?:\\.|[^"\\\n])*"|'
    r"'(?:\\.|[^'\\\n])*'"
    r'|`(?:\\.|[^`\\])*`)'
    r'|(?<tag></?[A-Za-z][\w.\-]*|/?>)'
    r'|(?<number>\b\d+(?:\.\d+)?\b)'
    r'|(?<ident>[A-Za-z_$][\w$]*)'
    r'|(?<punct>=>|===|!==|==|&&|\|\||\?\?|[{}()\[\];,.=+\-*!&|?:%])',
  );

  static final RegExp _shellPattern = RegExp(
    r'(?<comment>#[^\n]*)'
    r'|(?<string>"(?:\\.|[^"\\\n])*"|'
    r"'(?:\\.|[^'\\\n])*')"
    r'|(?<flag>\s--?[\w-]+)'
    r'|(?<ident>[A-Za-z_][\w\-]*)',
  );

  static const TextStyle base = TextStyle(
    color: AppColors.codeText,
    fontFamily: AppTextStyles.codeFontFamily,
    fontFamilyFallback: AppTextStyles.codeFontFallback,
    fontSize: 13,
    height: 1.55,
  );

  static const _comment = TextStyle(
    color: AppColors.codeComment,
    fontStyle: FontStyle.italic,
  );
  static const _string = TextStyle(color: AppColors.codeString);
  static const _keyword = TextStyle(
    color: AppColors.codeKeyword,
    fontWeight: FontWeight.w600,
  );
  static const _number = TextStyle(color: AppColors.codeNumber);
  static const _function = TextStyle(color: AppColors.codeFunction);
  static const _tag = TextStyle(color: AppColors.codeTag);
  static const _type = TextStyle(color: AppColors.codeAttr);
  static const _punct = TextStyle(color: AppColors.codePunctuation);

  static bool _isShell(String language) => const {
    'bash',
    'sh',
    'shell',
    'terminal',
    'zsh',
  }.contains(language.toLowerCase());

  /// Highlights [code] into a list of spans (to be wrapped in a parent span
  /// using [base]).
  static List<TextSpan> highlight(String code, String language) {
    final lang = language.toLowerCase();
    if (lang == 'text' || lang == 'plaintext') return [TextSpan(text: code)];
    final shell = _isShell(lang);
    final pattern = shell ? _shellPattern : _jsPattern;
    final spans = <TextSpan>[];
    var last = 0;

    for (final m in pattern.allMatches(code)) {
      if (m.start > last) {
        spans.add(TextSpan(text: code.substring(last, m.start)));
      }
      final text = m[0]!;
      spans.add(TextSpan(text: text, style: _styleFor(m, code, shell)));
      last = m.end;
    }
    if (last < code.length) spans.add(TextSpan(text: code.substring(last)));
    return spans;
  }

  static TextStyle? _styleFor(RegExpMatch m, String code, bool shell) {
    if (m.namedGroup('comment') != null) return _comment;
    if (m.namedGroup('string') != null) return _string;
    if (shell) {
      if (m.namedGroup('flag') != null) return _type;
      final word = m.namedGroup('ident');
      if (word != null && _shellKeywords.contains(word)) return _keyword;
      return null;
    }
    if (m.namedGroup('tag') != null) return _tag;
    if (m.namedGroup('number') != null) return _number;
    if (m.namedGroup('punct') != null) return _punct;
    final ident = m.namedGroup('ident');
    if (ident != null) {
      if (_keywords.contains(ident)) return _keyword;
      final nextChar = _nextNonSpace(code, m.end);
      if (nextChar == '(') return _function;
      if (ident[0].toUpperCase() == ident[0] &&
          ident[0].toLowerCase() != ident[0]) {
        return _type;
      }
    }
    return null;
  }

  static String? _nextNonSpace(String s, int from) {
    for (var i = from; i < s.length; i++) {
      final c = s[i];
      if (c != ' ' && c != '\t') return c;
    }
    return null;
  }
}
