import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/element_model.dart';

/// Size (width and height) of a card while it's on the crafting canvas or
/// being dragged. Shared between [ElementGrid] and [CraftCanvas] so the
/// drag feedback and the drop target math agree on the same dimensions.
const double kCraftItemSize = 130;

/// A [DragAnchorStrategy] that keeps the feedback widget centered on the
/// pointer, regardless of where on the original widget the drag started.
///
/// Used for every draggable element card so that picking one up never
/// makes it visually "jump" to some other offset, and dropping it places
/// its center exactly under the finger - matching where the user is
/// actually looking.
Offset centerDragAnchorStrategy(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) {
  return const Offset(kCraftItemSize / 2, kCraftItemSize / 2);
}

/// A curated palette of soft accent colors. Each element gets a stable
/// color derived from its name, so the grid feels lively without being
/// random/inconsistent between rebuilds.
const List<Color> _accentColors = [
  Color(0xFF6C5CE7),
  Color(0xFF00B894),
  Color(0xFFE17055),
  Color(0xFF0984E3),
  Color(0xFFE84393),
  Color(0xFFFDCB6E),
  Color(0xFF00CEC9),
  Color(0xFFD63031),
];

/// Public accessor so other widgets (e.g. Quick Combine mode's tubes) can
/// tint themselves with the same stable per-element color as [ElementCard].
Color elementAccentColor(String name) => _accentFor(name);

Color _accentFor(String name) =>
    _accentColors[name.toLowerCase().hashCode % _accentColors.length];

/// Card showing an element's emoji (in a colored badge) and name. Used
/// both in the discovered-elements grid and on the crafting canvas.
class ElementCard extends StatelessWidget {
  const ElementCard({
    super.key,
    required this.element,
    this.highlighted = false,
  });

  final GameElement element;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(element.name);
    final colors = AppColors.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? accent
              : colors.textMuted.withValues(alpha: 0.15),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlighted
                ? accent.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: highlighted ? 16 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                element.emoji,
                style: const TextStyle(fontSize: 17),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              element.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: colors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
