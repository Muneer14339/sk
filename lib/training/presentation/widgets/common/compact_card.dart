// lib/training/presentation/widgets/common/compact_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CompactCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets? padding;

  const CompactCard({
    super.key,
    this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.border(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: title != null
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title!,
            style: AppTheme.titleMedium(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      )
          : child,
    );
  }
}