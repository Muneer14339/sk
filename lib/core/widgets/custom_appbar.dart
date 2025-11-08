import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'battery_indicator_widget.dart';



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
                  AppTheme.primary(context).withValues(alpha: .22),
                  AppTheme.primary(context).withValues(alpha: .22)
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
              child: Row(
                children: [
                   // ✅ Add this
                  IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          color: showBackButton ?? true
                              ? AppTheme.textPrimary(context)
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
                              AppTheme.textPrimary(context).withValues(alpha: .9))),
                  ...actions ?? [Spacer()],
                  const BatteryIndicatorWidget(),
                ],
              ),
            )));
