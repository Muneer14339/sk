import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

PreferredSizeWidget customAppBar({
  required String title,
  required BuildContext context,
  List<Widget>? actions,
  bool? showBackButton,
}) =>
    PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.kPrimaryTeal.withValues(alpha: .22),
                  AppColors.kPrimaryTeal.withValues(alpha: .22)
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .35),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: showBackButton ?? true
                                ? AppColors.kTextPrimary
                                : Colors.transparent,
                            size: 20),
                        onPressed: showBackButton ?? true
                            ? () => Navigator.pop(context)
                            : null),
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                AppColors.kTextPrimary.withValues(alpha: .9))),
                    ...actions ?? [],
                  ],
                ),
              ),
            )));
