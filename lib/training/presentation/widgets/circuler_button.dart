import 'package:flutter/material.dart';

class CustomCircularButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const CustomCircularButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = Colors.blue,
    this.size = 120.0,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: borderWidth)
              : null,
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
