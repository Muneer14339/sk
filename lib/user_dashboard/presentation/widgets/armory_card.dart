// lib/user_dashboard/presentation/widgets/armory_card.dart
import 'package:flutter/material.dart';

import '../core/theme/user_app_theme.dart';
import 'common/common_widgets.dart';

class ArmoryCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onAddPressed;
  final Widget child;
  final int? itemCount;
  final bool isLoading;

  const ArmoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.onAddPressed,
    required this.child,
    this.itemCount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSizes.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(width: AppSizes.itemSpacing),
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.accentText,
                    size: AppSizes.smallIcon,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(description, style: AppTextStyles.cardDescription),
              const SizedBox(height: 10),
              Row(
                children: [
                  CommonWidgets.buildActionButton(
                    label: 'Add $title',
                    onPressed: onAddPressed,
                    isLoading: isLoading,
                  ),
                  const Spacer(),
                  if (itemCount != null)
                    CommonWidgets.buildCountBadge(itemCount!, 'items'),
                ],
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
