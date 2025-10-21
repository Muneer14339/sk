// lib/core/widgets/common_widgets.dart
import 'package:flutter/material.dart';

import '../../core/theme/user_app_theme.dart';

class CommonWidgets {
  // Status Chip Widget
  static Widget buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: AppDecorations.getStatusDecoration(status),
      child: Text(
        status,
        style: status.statusTextStyle,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Tag Widget (for caliber, category, etc.)
  static Widget buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppDecorations.tagDecoration,
      child: Text(
        text,
        style: AppTextStyles.tagText,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Count Badge Widget
  static Widget buildCountBadge(int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppDecorations.countBadgeDecoration,
      child: Text(
        '$count $label',
        style: AppTextStyles.countBadgeText,
      ),
    );
  }

  // Loading Widget
  static Widget buildLoading({String? message}) {
    return Center(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: AppSizes.loadingSize,
              height: AppSizes.loadingSize,
              child: CircularProgressIndicator(
                color: AppColors.accentText,
                strokeWidth: AppSizes.loadingStroke,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSizes.itemSpacing),
              Text(message, style: AppTextStyles.emptyStateText),
            ],
          ],
        ),
      ),
    );
  }

  // Error Widget
  static Widget buildError(String message) {
    return Center(
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.errorColor,
              size: AppSizes.largeIcon,
            ),
            const SizedBox(height: AppSizes.itemSpacing),
            Text(
              message,
              style: AppTextStyles.emptyStateText.copyWith(
                color: AppColors.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Info Badge Widget (like "Smart Dropdowns")
  static Widget buildInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppDecorations.accentBadgeDecoration,
      child: Text(text, style: AppTextStyles.badgeText),
    );
  }

  // Responsive Row Helper
  static Widget buildResponsiveRow(List<Widget> children, {double breakpoint = AppBreakpoints.tablet}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > breakpoint) {
          return Row(
            children: children
                .expand((child) => [Expanded(child: child), const SizedBox(width: 10)])
                .take(children.length * 2 - 1)
                .toList(),
          );
        } else {
          return Column(
            children: children
                .expand((child) => [child, const SizedBox(height: AppSizes.fieldSpacing)])
                .take(children.length * 2 - 1)
                .toList(),
          );
        }
      },
    );
  }

  // Action Button with Icon
  static Widget buildActionButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
        width: AppSizes.smallIcon,
        height: AppSizes.smallIcon,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.loadingStroke,
          color: AppColors.buttonText,
        ),
      )
          : Icon(icon ?? Icons.add, size: AppSizes.smallIcon),
      label: Text(label),
      style: AppButtonStyles.addButtonStyle,
    );
  }

  // Expandable Section Widget
  static Widget buildExpandableSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: AppSizes.itemMargin,
      decoration: AppDecorations.sectionBorderDecoration,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        iconColor: AppColors.secondaryText,
        collapsedIconColor: AppColors.secondaryText,
        initiallyExpanded: initiallyExpanded,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth - 40;

            return SizedBox(
              width: availableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.itemTitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: AppTextStyles.itemSubtitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        children: children.isEmpty
            ? [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'No items.',
              style: AppTextStyles.emptyStateText,
            ),
          )
        ]
            : children,
      ),
    );
  }

  // Data Table Wrapper
  static Widget buildDataTable({
    required List<DataColumn> columns,
    required List<DataRow> rows,
    String? emptyMessage,
  }) {
    if (rows.isEmpty && emptyMessage != null) {
      return Padding(
        padding: AppSizes.cardPadding,
        child: Text(
          emptyMessage,
          style: AppTextStyles.emptyStateText,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: AppDecorations.tableDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.itemSpacing),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(AppColors.headerBackground),
            dataRowMaxHeight: 50,
            columnSpacing: 12,
            horizontalMargin: 12,
            headingTextStyle: AppTextStyles.tableHeader,
            dataTextStyle: AppTextStyles.tableData,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }

  // Page Header
  static Widget buildPageHeader({
    required String title,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: AppDecorations.headerBorderDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.pageTitle),
                    if (subtitle != null)
                      Text(subtitle, style: AppTextStyles.pageSubtitle),
                  ],
                ),
              ),
              if (actions != null) ...actions,
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build responsive layout
  static Widget buildResponsiveLayout(List<Widget> children, bool _shouldUseGridLayout) {
    if (!_shouldUseGridLayout) {
      return Column(children: children);
    }

    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += 2) {
      if (i + 1 < children.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: AppSizes.fieldSpacing),
              Expanded(child: children[i + 1]),
            ],
          ),
        );
      } else {
        rows.add(children[i]);
      }
      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: AppSizes.fieldSpacing));
      }
    }
    return Column(children: rows);
  }
}