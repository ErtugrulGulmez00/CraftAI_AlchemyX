import 'package:flutter/material.dart';

import '../core/constants/game_language.dart';
import '../core/haptics.dart';
import '../core/localization/app_strings.dart';
import '../core/services/combination_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sound_service.dart';
import '../core/services/supabase_service.dart';
import '../models/element_model.dart';

enum ElementSortMode { time, name, emoji, random }

/// A single instance of an element placed on the crafting canvas.
class CanvasItem {
  CanvasItem({required this.id, required this.element, required this.position});

  final int id;
  final GameElement element;
  Offset position;
}

/// Central state holder for the game: discovered elements, the items
/// currently on the canvas, and the combine pipeline.
class GameProvider extends ChangeNotifier {
  GameProvider(
    this._localStorage,
    this._combinationService,
    this._sound,
    this.sessionId, {
    required this.language,
    this.targetWord,
  });

  final LocalStorageService _localStorage;
  final CombinationService _combinationService;
  final SoundService _sound;

  final String sessionId;
  final GameLanguage language;
  final String? targetWord;

  bool targetReached = false;

  void clearTargetReached() {
    targetReached = false;
  }

  final List<CanvasItem> _canvasItems = [];
  int _nextId = 0;

  /// Ids of canvas items currently awaiting a combination result.
  /// Multiple combinations can be in flight simultaneously; each pending
  /// item shows a shimmer placeholder card instead of its element.
  final Set<int> _pendingItemIds = {};
  Set<int> get pendingItemIds => Set.unmodifiable(_pendingItemIds);
  bool get isLoading => _pendingItemIds.isNotEmpty;

  String? lastError;
  GameElement? lastFirstDiscovery;

  List<CanvasItem> get canvasItems => List.unmodifiable(_canvasItems);

  ElementSortMode _sortMode = ElementSortMode.time;
  ElementSortMode get sortMode => _sortMode;
  List<GameElement>? _randomOrderCache;

  void setSortMode(ElementSortMode mode) {
    _sortMode = mode;
    if (mode == ElementSortMode.random) {
      _randomOrderCache = [..._localStorage.getDiscoveredElements()]..shuffle();
    }
    notifyListeners();
  }

  List<GameElement> get discoveredElements {
    final list = _localStorage.getDiscoveredElements();
    switch (_sortMode) {
      case ElementSortMode.time:
        return list;
      case ElementSortMode.name:
        return [
          ...list,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ElementSortMode.emoji:
        return [...list]..sort((a, b) => a.emoji.compareTo(b.emoji));
      case ElementSortMode.random:
        final cache = _randomOrderCache;
        if (cache == null || cache.length != list.length) {
          _randomOrderCache = [...list]..shuffle();
          return _randomOrderCache!;
        }
        return cache;
    }
  }

  /// Encyclopedia data: recipes known on this device for [element], plus a
  /// key lookup so the sheet can show each ingredient's emoji.
  List<(String, String)> recipesFor(GameElement element) =>
      _localStorage.getRecipesFor(element.key);

  GameElement? elementByKey(String key) => _localStorage.getElementByKey(key);

  bool isFavorite(GameElement element) => _localStorage.isFavorite(element.key);

  Future<void> toggleFavorite(GameElement element) async {
    await _localStorage.toggleFavorite(element.key);
    notifyListeners();
  }

  void addToCanvas(GameElement element, Offset position) {
    _canvasItems.add(
      CanvasItem(id: _nextId++, element: element, position: position),
    );
    notifyListeners();
  }

  void moveItem(int id, Offset newPosition) {
    for (final item in _canvasItems) {
      if (item.id == id) {
        item.position = newPosition;
        notifyListeners();
        return;
      }
    }
  }

  void removeFromCanvas(int id) {
    _canvasItems.removeWhere((item) => item.id == id);
    Haptics.drop();
    notifyListeners();
  }

  void duplicateItem(int id) {
    final item = _canvasItems.firstWhere((item) => item.id == id);
    _canvasItems.add(
      CanvasItem(
        id: _nextId++,
        element: item.element,
        position: item.position + const Offset(28, 28),
      ),
    );
    Haptics.drop();
    notifyListeners();
  }

  Future<void> combineItems(int draggedId, int targetId) async {
    // Skip if either item is already in a pending combination.
    if (_pendingItemIds.contains(draggedId) ||
        _pendingItemIds.contains(targetId)) {
      return;
    }
    final dragged = _canvasItems.firstWhere((item) => item.id == draggedId);
    final target = _canvasItems.firstWhere((item) => item.id == targetId);
    await _combineInto(dragged.element, target, removeId: draggedId);
  }

  Future<void> combineWithNew(GameElement element, int targetId) async {
    if (_pendingItemIds.contains(targetId)) return;
    final target = _canvasItems.firstWhere((item) => item.id == targetId);
    await _combineInto(element, target);
  }

  Future<void> _combineInto(
    GameElement other,
    CanvasItem target, {
    int? removeId,
  }) async {
    lastError = null;

    // Save originals for restoration on error.
    final savedTargetElement = target.element;
    final savedTargetPos = target.position;
    CanvasItem? savedDragged;
    if (removeId != null) {
      try {
        savedDragged = _canvasItems.firstWhere((i) => i.id == removeId);
      } catch (_) {}
    }

    // Immediately show a pending placeholder and remove the dragged item.
    if (removeId != null) {
      _canvasItems.removeWhere((i) => i.id == removeId);
    }
    final targetIndex = _canvasItems.indexWhere((i) => i.id == target.id);
    if (targetIndex == -1) return;
    _canvasItems[targetIndex] = CanvasItem(
      id: target.id,
      element: GameElement(name: '', emoji: ''),
      position: savedTargetPos,
    );
    _pendingItemIds.add(target.id);
    notifyListeners();

    try {
      final result = await _combinationService.combine(
        other,
        savedTargetElement,
        language,
      );

      final resultIndex = _canvasItems.indexWhere((i) => i.id == target.id);
      if (resultIndex != -1) {
        _canvasItems[resultIndex] = CanvasItem(
          id: target.id,
          element: result,
          position: savedTargetPos,
        );
      }

      if (result.isFirstDiscovery) {
        lastFirstDiscovery = result;
        _sound.playDiscovery();
        Haptics.combine();
      } else {
        _sound.playPop();
        Haptics.combine();
      }

      if (targetWord != null && result.key == targetWord) {
        targetReached = true;
      }
    } on NoCombinationException {
      lastError = AppStrings.of(language).noCombinationMessage;
      _restoreOnError(
        target.id,
        savedTargetElement,
        savedTargetPos,
        savedDragged,
      );
      _sound.playError();
      Haptics.error();
    } catch (e) {
      lastError = _combineErrorMessage(e);
      _restoreOnError(
        target.id,
        savedTargetElement,
        savedTargetPos,
        savedDragged,
      );
      _sound.playError();
      Haptics.error();
    } finally {
      _pendingItemIds.remove(target.id);
      notifyListeners();
    }
  }

  /// Combines two arbitrary elements directly, with no canvas item
  /// involved — used by Quick Combine mode's tube + mortar interaction.
  /// Returns the result, or `null` if they don't combine or the request
  /// failed (in which case [lastError] is set).
  Future<GameElement?> combineElements(GameElement a, GameElement b) async {
    lastError = null;
    try {
      final result = await _combinationService.combine(a, b, language);

      if (result.isFirstDiscovery) {
        lastFirstDiscovery = result;
        _sound.playDiscovery();
        Haptics.combine();
      } else {
        _sound.playPop();
        Haptics.combine();
      }

      if (targetWord != null && result.key == targetWord) {
        targetReached = true;
      }

      notifyListeners();
      return result;
    } on NoCombinationException {
      lastError = AppStrings.of(language).noCombinationMessage;
      _sound.playError();
      Haptics.error();
      notifyListeners();
      return null;
    } catch (e) {
      lastError = _combineErrorMessage(e);
      _sound.playError();
      Haptics.error();
      notifyListeners();
      return null;
    }
  }

  /// Localized message for an unexpected combine failure. Network drops are
  /// by far the most common cause, so sniff the exception text for the
  /// usual connectivity markers and show a dedicated "you're offline"
  /// message instead of a generic one. Never leaks the raw exception.
  String _combineErrorMessage(Object error) {
    final t = AppStrings.of(language);
    final text = error.toString();
    final isOffline =
        text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection refused') ||
        text.contains('Connection reset') ||
        text.contains('Network is unreachable');
    return isOffline ? t.offlineError : t.combineFailedError;
  }

  void _restoreOnError(
    int targetId,
    GameElement originalElement,
    Offset originalPos,
    CanvasItem? originalDragged,
  ) {
    final idx = _canvasItems.indexWhere((i) => i.id == targetId);
    if (idx != -1) {
      _canvasItems[idx] = CanvasItem(
        id: targetId,
        element: originalElement,
        position: originalPos,
      );
    }
    if (originalDragged != null) {
      _canvasItems.add(originalDragged);
    }
  }

  @override
  void dispose() {
    _sound.dispose();
    super.dispose();
  }

  void clearFirstDiscoveryFlag() {
    lastFirstDiscovery = null;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
  }

  void clearCanvas() {
    _canvasItems.clear();
    notifyListeners();
  }
}
