import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {required this.title,
      this.onTap,
      this.buttonColor,
      this.width,
      this.height,
      this.circularRadius,
      this.textColor,
      this.margin,
      this.addBottomMargin,
      this.isLoading,
      super.key});
  final String title;
  final Function()? onTap;
  final Color? buttonColor;
  final Color? textColor;
  final double? width;
  final double? circularRadius;
  final double? height;
  final EdgeInsets? margin;
  final bool? addBottomMargin;
  final bool? isLoading;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading == true ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              margin: margin,
              height: height ?? 50,
              width: width,
              decoration: BoxDecoration(
                  color: buttonColor ?? AppColors.kPrimaryTeal,
                  borderRadius:
                      BorderRadius.all(Radius.circular(circularRadius ?? 6))),
              child: Center(
                  child: isLoading == true
                      ? CircularProgressIndicator(color: AppColors.white)
                      : Text(title,
                          style: TextStyle(
                              color: textColor ?? AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)))),
          if (addBottomMargin == true) const SizedBox(height: 20)
        ],
      ),
    );
  }
}
