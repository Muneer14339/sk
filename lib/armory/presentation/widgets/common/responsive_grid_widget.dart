// lib/armory/presentation/widgets/common/responsive_grid_widget.dart
import 'package:flutter/material.dart';

class ResponsiveGridWidget extends StatelessWidget {
  final List<Widget> children;
  final bool forceGrid;
  final double spacing;

  const ResponsiveGridWidget({
    super.key,
    required this.children,
    this.forceGrid = false,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final orientation = MediaQuery.of(context).orientation;
    final shouldUseGrid = forceGrid || orientation == Orientation.landscape;

    if (!shouldUseGrid) {
      return Column(
        children: children.expand((child) => [
          child,
          if (child != children.last) SizedBox(height: spacing),
        ]).toList(),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      final rowChildren = <Widget>[
        Expanded(child: children[i]),
      ];

      if (i + 1 < children.length) {
        rowChildren.add(SizedBox(width: spacing));
        rowChildren.add(Expanded(child: children[i + 1]));
      } else {
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < children.length ? spacing : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rowChildren,
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}