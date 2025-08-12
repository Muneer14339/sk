import 'package:flutter/material.dart';

class ModifiedContainer extends StatelessWidget {
  const ModifiedContainer(
      {this.color,
      this.borderColor,
      this.borderRadius,
      this.isBorderOnly,
      this.borderSize,
      this.borderRadiusOnly,
      this.width,
      this.height,
      this.padding,
      this.margin,
      this.child,
      this.onTap,
      this.boxShadow,
      this.borderSide,
      super.key});
  final double? borderRadius, borderSize, width, height;
  final Color? color, borderColor;
  final EdgeInsets? padding, margin;
  final Widget? child;
  final bool? isBorderOnly;
  final BorderRadiusGeometry? borderRadiusOnly;
  final void Function()? onTap;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? borderSide;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
            boxShadow: boxShadow,
            color: color,
            border: borderSide ??
                (borderColor != null
                    ? Border.all(color: borderColor!, width: borderSize ?? 1)
                    : null),
            borderRadius: isBorderOnly == true
                ? borderRadiusOnly
                : BorderRadius.all(Radius.circular(borderRadius ?? 12))),
        child: child,
      ),
    );
  }
}
