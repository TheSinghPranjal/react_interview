import 'package:flutter/foundation.dart';

import 'json_utils.dart';

enum BookmarkType {
  lesson('Lessons'),
  interview('Interview'),
  mcq('Quiz');

  const BookmarkType(this.label);
  final String label;
}

@immutable
class Bookmark {
  const Bookmark({
    required this.type,
    required this.itemId,
    required this.createdAt,
  });

  final BookmarkType type;
  final String itemId;
  final DateTime createdAt;

  String get key => '${type.name}:$itemId';

  static Bookmark? tryParse(JsonMap json) {
    final type = BookmarkType.values
        .where((t) => t.name == json.optString('type'))
        .firstOrNull;
    final id = json.optString('itemId');
    if (type == null || id.isEmpty) return null;
    return Bookmark(
      type: type,
      itemId: id,
      createdAt:
          DateTime.tryParse(json.optString('createdAt')) ?? DateTime(2024),
    );
  }

  JsonMap toJson() => {
    'type': type.name,
    'itemId': itemId,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Bookmark && other.type == type && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(type, itemId);
}
