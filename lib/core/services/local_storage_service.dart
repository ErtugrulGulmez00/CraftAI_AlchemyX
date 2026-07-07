import 'package:hive_flutter/hive_flutter.dart';

import '../../models/element_model.dart';
import '../constants/app_constants.dart';
import '../constants/game_language.dart';
import '../utils/combination_key.dart';

/// Stage 1 of the craft pipeline: everything that can be answered
/// instantly from the device's local Hive storage.
///
/// Each instance is bound to a single session/save-slot (see
/// [AppConstants.sessionIds]) so different "worlds" don't share progress.
class LocalStorageService {
  late Box<GameElement> _elementsBox;
  late Box<String> _combinationsBox;
  late Box<bool> _favoritesBox;

  /// Must be called once at app startup, before any [LocalStorageService]
  /// is created or [getElementCount]/[resetSession] are used.
  static Future<void> initHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(GameElementAdapter().typeId)) {
      Hive.registerAdapter(GameElementAdapter());
    }
  }

  /// Opens the boxes for [sessionId], seeding [startingElements] if this
  /// is a brand new save slot.
  Future<void> init(
    String sessionId, {
    required List<GameElement> startingElements,
  }) async {
    _elementsBox = await Hive.openBox<GameElement>(
      AppConstants.discoveredElementsBox(sessionId),
    );
    _combinationsBox = await Hive.openBox<String>(
      AppConstants.combinationsCacheBox(sessionId),
    );
    _favoritesBox = await Hive.openBox<bool>(
      AppConstants.favoritesBox(sessionId),
    );

    if (_elementsBox.isEmpty) {
      for (final element in startingElements) {
        _elementsBox.put(element.key, element);
      }
    }
  }

  /// Opens [boxName], runs [action], and closes the box again — but ONLY
  /// if it wasn't already open. Hive boxes are singletons, so closing one
  /// that a live game session is holding would break that session's next
  /// read/write with a HiveError.
  static Future<T> _withElementsBox<T>(
    String boxName,
    T Function(Box<GameElement> box) action,
  ) async {
    final wasAlreadyOpen = Hive.isBoxOpen(boxName);
    final box = await Hive.openBox<GameElement>(boxName);
    final result = action(box);
    if (!wasAlreadyOpen) await box.close();
    return result;
  }

  /// Number of elements discovered in [sessionId], without keeping its
  /// boxes open. Returns 0 for a save slot that has never been played.
  static Future<int> getElementCount(String sessionId) async {
    final boxName = AppConstants.discoveredElementsBox(sessionId);
    if (!await Hive.boxExists(boxName)) return 0;
    return _withElementsBox(boxName, (box) => box.length);
  }

  /// Number of world-first discoveries made in [sessionId] (elements this
  /// player was the first to ever combine), without keeping boxes open.
  static Future<int> getFirstDiscoveryCount(String sessionId) async {
    final boxName = AppConstants.discoveredElementsBox(sessionId);
    if (!await Hive.boxExists(boxName)) return 0;
    return _withElementsBox(
      boxName,
      (box) => box.values.where((e) => e.isFirstDiscovery).length,
    );
  }

  /// Wipes a save slot's local data so it starts fresh next time.
  static Future<void> resetSession(String sessionId) async {
    await Hive.deleteBoxFromDisk(AppConstants.discoveredElementsBox(sessionId));
    await Hive.deleteBoxFromDisk(AppConstants.combinationsCacheBox(sessionId));
    await Hive.deleteBoxFromDisk(AppConstants.favoritesBox(sessionId));
  }

  /// Adds [elements] (e.g. fetched from a cloud progress backup) into
  /// [sessionId]'s local box, keyed by [GameElement.key]. Never removes
  /// anything — existing local elements are left untouched and elements
  /// already present are simply overwritten with the same data, so this is
  /// always safe to call without confirmation.
  static Future<void> mergeElementsIntoSession(
    String sessionId,
    List<GameElement> elements,
  ) async {
    final boxName = AppConstants.discoveredElementsBox(sessionId);
    final wasAlreadyOpen = Hive.isBoxOpen(boxName);
    final box = await Hive.openBox<GameElement>(boxName);
    for (final element in elements) {
      await box.put(element.key, element);
    }
    // Only close if this call opened it — closing a box a live game
    // session still holds would break that session (boxes are singletons).
    if (!wasAlreadyOpen) await box.close();
  }

  List<GameElement> getDiscoveredElements() =>
      _elementsBox.values.toList(growable: false);

  bool hasElement(String name) =>
      _elementsBox.containsKey(name.toLowerCase().trim());

  Future<void> saveElement(GameElement element) async {
    await _elementsBox.put(element.key, element);
  }

  /// Returns the cached result name for [a] + [b], or null if unknown.
  String? getCachedCombination(String a, String b, GameLanguage language) {
    return _combinationsBox.get(combinationKey(a, b, language));
  }

  Future<void> cacheCombination(
    String a,
    String b,
    String resultElementKey,
    GameLanguage language,
  ) async {
    await _combinationsBox.put(
      combinationKey(a, b, language),
      resultElementKey,
    );
  }

  GameElement? getElementByKey(String key) => _elementsBox.get(key);

  /// Every locally-known recipe that produces [elementKey], parsed back out
  /// of the combination-cache keys (`[lang:]a+b` → result key). Powers the
  /// encyclopedia sheet in Discoveries; an empty list usually means a
  /// starting element (or one restored from cloud without its recipe).
  List<(String, String)> getRecipesFor(String elementKey) {
    final recipes = <(String, String)>[];
    for (final entry in _combinationsBox.toMap().entries) {
      if (entry.value != elementKey) continue;
      var pair = entry.key as String;
      final colon = pair.indexOf(':');
      if (colon != -1) pair = pair.substring(colon + 1);
      final parts = pair.split('+');
      if (parts.length == 2) recipes.add((parts[0], parts[1]));
    }
    return recipes;
  }

  bool isFavorite(String elementKey) => _favoritesBox.containsKey(elementKey);

  Set<String> getFavoriteKeys() => _favoritesBox.keys.cast<String>().toSet();

  Future<void> toggleFavorite(String elementKey) async {
    if (_favoritesBox.containsKey(elementKey)) {
      await _favoritesBox.delete(elementKey);
    } else {
      await _favoritesBox.put(elementKey, true);
    }
  }
}
