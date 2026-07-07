import 'package:hive/hive.dart';

part 'element_model.g.dart';

/// A single craftable element (e.g. "Su", "Ateş", "Buhar").
@HiveType(typeId: 0)
class GameElement {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String emoji;

  /// True if this player was the first in the world to discover it.
  @HiveField(2)
  final bool isFirstDiscovery;

  GameElement({
    required this.name,
    required this.emoji,
    this.isFirstDiscovery = false,
  });

  /// Two elements are the same if they share a name (case-insensitive).
  String get key => name.toLowerCase().trim();

  factory GameElement.fromJson(Map<String, dynamic> json) {
    return GameElement(
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      isFirstDiscovery: json['is_first_discovery'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    'is_first_discovery': isFirstDiscovery,
  };

  @override
  bool operator ==(Object other) => other is GameElement && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
