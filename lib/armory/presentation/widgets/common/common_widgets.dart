import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'armory_constants.dart';

class CommonWidgets {
  static Widget buildStatusChip(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status.statusColor(context).withOpacity(0.1),
        border: Border.all(color: status.statusColor(context).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: status.statusTextStyle(context),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Widget buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        border: Border.all(color: AppTheme.border(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTheme.labelSmall(context),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Widget buildCountBadge(BuildContext context, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        border: Border.all(color: AppTheme.border(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count $label',
        style: AppTheme.labelSmall(context),
      ),
    );
  }

  static Widget buildLoading({String? message}) {
    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: ArmoryConstants.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: ArmoryConstants.loadingSize,
                height: ArmoryConstants.loadingSize,
                child: CircularProgressIndicator(
                  color: AppTheme.primary(context),
                  strokeWidth: ArmoryConstants.loadingStroke,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: ArmoryConstants.itemSpacing),
                Text(message, style: AppTheme.bodySmall(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildError(String message) {
    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: ArmoryConstants.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.error(context),
                size: ArmoryConstants.largeIcon,
              ),
              const SizedBox(height: ArmoryConstants.itemSpacing),
              Text(
                message,
                style: AppTheme.bodySmall(context).copyWith(
                  color: AppTheme.error(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildInfoBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary(context).withOpacity(0.1),
        border: Border.all(color: AppTheme.primary(context).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(ArmoryConstants.badgeBorderRadius),
      ),
      child: Text(
        text,
        style: AppTheme.labelMedium(context).copyWith(color: AppTheme.primary(context)),
      ),
    );
  }

  static Widget buildResponsiveRow(BuildContext context, List<Widget> children, {double breakpoint = 520}) {
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
                .expand((child) => [child, const SizedBox(height: ArmoryConstants.fieldSpacing)])
                .take(children.length * 2 - 1)
                .toList(),
          );
        }
      },
    );
  }

  static Widget buildActionButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
        width: ArmoryConstants.smallIcon,
        height: ArmoryConstants.smallIcon,
        child: CircularProgressIndicator(
          strokeWidth: ArmoryConstants.loadingStroke,
          color: AppTheme.textPrimary(context),
        ),
      )
          : Icon(icon ?? Icons.add,color: AppTheme.textPrimary(context), size: ArmoryConstants.smallIcon),
      label: Text(label, style: AppTheme.bodyMedium(context)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary(context),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static Widget buildExpandableSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Widget> children,
    bool initiallyExpanded = false,
    int? count, // ✅ ADD count parameter
  }) {
    return Container(
      margin: ArmoryConstants.itemMargin,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          iconColor: AppTheme.textSecondary(context),
          collapsedIconColor: AppTheme.textSecondary(context),
          initiallyExpanded: initiallyExpanded,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Title + Subtitle left side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTheme.titleMedium(context),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: AppTheme.labelMedium(context),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),

              // ✅ Count badge right side inline
              if (count != null) ...[
                const SizedBox(width: 8),
                buildCountBadge(context, count, 'items'),
              ],
            ],
          ),

          children: children.isEmpty
              ? [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'No items.',
                style: AppTheme.bodySmall(context),
              ),
            )
          ]
              : children,
        )

    );
  }

  static Widget buildDataTable(BuildContext context, {
    required List<DataColumn> columns,
    required List<DataRow> rows,
    String? emptyMessage,
  })
  {
    if (rows.isEmpty && emptyMessage != null) {
      return Padding(
        padding: ArmoryConstants.cardPadding,
        child: Text(
          emptyMessage,
          style: AppTheme.bodySmall(context),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ArmoryConstants.itemSpacing),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(AppTheme.surfaceVariant(context)),
            dataRowMaxHeight: 50,
            columnSpacing: 12,
            horizontalMargin: 12,
            headingTextStyle: AppTheme.titleSmall(context),
            dataTextStyle: AppTheme.bodySmall(context),
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }

  static Widget buildPageHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    List<Widget>? actions,
  })
  {
    return Container(
      padding: ArmoryConstants.cardPadding,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.headingMedium(context)),
                    if (subtitle != null)
                      Text(subtitle, style: AppTheme.labelMedium(context)),
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

  static Widget buildResponsiveLayout(BuildContext context, List<Widget> children, bool _shouldUseGridLayout) {
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
              const SizedBox(width: ArmoryConstants.fieldSpacing),
              Expanded(child: children[i + 1]),
            ],
          ),
        );
      } else {
        rows.add(children[i]);
      }
      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: ArmoryConstants.fieldSpacing));
      }
    }
    return Column(children: rows);
  }
}