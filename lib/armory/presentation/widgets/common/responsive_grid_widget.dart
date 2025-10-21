import 'package:flutter/material.dart';

class ResponsiveGridWidget extends StatelessWidget {
  final List<Widget> children;
  final bool forceGrid;
  final double spacing;

  const ResponsiveGridWidget({
    super.key,
    required this.children,
    this.forceGrid = false,
    this.spacing = 0,
  });

  bool _shouldUseGridLayout(BuildContext context) {
    if (forceGrid) return true;
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Agar koi item nahi hai to directly "No items" show karo
    if (children.isEmpty) {
      return const Center(
        child: Text(
          'No items',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // 🔹 Portrait (or non-grid) layout
    if (!_shouldUseGridLayout(context)) {
      return Column(
        children: children.expand((child) => [
          child,
          if (child != children.last) SizedBox(height: spacing),
        ]).toList(),
      );
    }

    // 🔹 Landscape/grid layout
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += 2) {
      if (i + 1 < children.length) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                SizedBox(width: spacing),
                Expanded(child: children[i + 1]),
              ],
            ),
          ),
        );
      } else {
        rows.add(
          Row(
            children: [
              Expanded(child: children[i]),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
      }

      if (i + 2 < children.length) {
        rows.add(SizedBox(height: spacing));
      }
    }

    return Column(children: rows);
  }
}
