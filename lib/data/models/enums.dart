/// Learning track / content category.
enum Track {
  react('react', 'React', 'React.js'),
  next('next', 'Next.js', 'Next.js');

  const Track(this.slug, this.label, this.longLabel);

  /// URL slug used in routes (`/learn/react`, `/learn/next`).
  final String slug;

  /// Category label as stored in content JSON.
  final String label;
  final String longLabel;

  static Track? fromSlug(String? slug) {
    for (final t in values) {
      if (t.slug == slug) return t;
    }
    return null;
  }

  /// Parses JSON category values like "React", "Next.js", "next".
  static Track parse(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.startsWith('next')) return Track.next;
    if (v.startsWith('react')) return Track.react;
    throw FormatException('Unknown category "$raw"');
  }
}

enum Difficulty {
  easy('Easy', 'Beginner'),
  medium('Medium', 'Intermediate'),
  hard('Hard', 'Advanced');

  const Difficulty(this.label, this.lessonLabel);

  final String label;

  /// Label used for lessons (Beginner / Intermediate / Advanced).
  final String lessonLabel;

  String get slug => name;

  static Difficulty? fromSlug(String? slug) {
    for (final d in values) {
      if (d.slug == slug) return d;
    }
    return null;
  }

  /// Accepts Easy/Medium/Hard as well as Beginner/Intermediate/Advanced/Tough.
  static Difficulty parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'easy':
      case 'beginner':
        return Difficulty.easy;
      case 'medium':
      case 'intermediate':
        return Difficulty.medium;
      case 'hard':
      case 'tough':
      case 'advanced':
        return Difficulty.hard;
    }
    throw FormatException('Unknown difficulty "$raw"');
  }
}
