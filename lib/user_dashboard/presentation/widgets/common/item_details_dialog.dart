// lib/user_dashboard/presentation/widgets/common/item_details_dialog.dart
import 'package:flutter/material.dart';
import '../../core/theme/user_app_theme.dart';
import 'dialog_widgets.dart';
import 'entity_field_helper.dart';

class ItemDetailsDialog extends StatefulWidget {
  final dynamic item;

  const ItemDetailsDialog({super.key, required this.item});

  static void show(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ItemDetailsDialog(item: item),
    );
  }

  @override
  State<ItemDetailsDialog> createState() => _ItemDetailsDialogState();
}

class _ItemDetailsDialogState extends State<ItemDetailsDialog> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final details = EntityFieldHelper.extractDetails(widget.item);
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine layout strategy
    final isLandscape = orientation == Orientation.landscape;
    final isMobile = screenWidth < AppBreakpoints.mobile;
    final isTablet = screenWidth >= AppBreakpoints.tablet && screenWidth < AppBreakpoints.desktop;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 750 : (isTablet ? 600 : screenWidth * 0.95),
          maxHeight: MediaQuery.of(context).size.height * (isLandscape ? 0.85 : (_isExpanded ? 0.85 : 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(details, context),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: _buildContent(details, isLandscape, isMobile),
              ),
            ),
            // Expandable Widget at bottom (only in portrait)
            if (!isLandscape) _buildExpandableWidget(details),
            // Footer
            //_buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(EntityDetailsData details, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: AppDecorations.headerBorderDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  details.title,
                  style: AppTextStyles.dialogTitle.copyWith(
                    fontSize: 15,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 2,
                ),
                if (details.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    details.subtitle,
                    style: AppTextStyles.itemSubtitle.copyWith(
                      color: AppColors.accentText,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.primaryText, size: 18),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EntityDetailsData details, bool isLandscape, bool isMobile) {
    final requiredFields = details.sections.where((f) => f.isImportant).toList();
    final additionalFields = details.sections.where((f) => !f.isImportant).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (requiredFields.isNotEmpty) ...[
          _buildSectionHeader('Key Information'),
          const SizedBox(height: 4),
          _buildFieldsGrid(requiredFields, isLandscape, isMobile, isRequired: true),
        ],
        // Show additional fields in landscape OR when expanded in portrait
        if (additionalFields.isNotEmpty && (isLandscape || _isExpanded)) ...[
          if (requiredFields.isNotEmpty) const SizedBox(height: 12),
          _buildSectionHeader('Additional Details'),
          const SizedBox(height: 4),
          _buildFieldsGrid(additionalFields, isLandscape, isMobile),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildExpandableWidget(EntityDetailsData details) {
    final additionalFields = details.sections.where((f) => !f.isImportant).toList();
    if (additionalFields.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.primaryBorder.withOpacity(0.3))),
        color: AppColors.accentBackgroundWithOpacity,
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [

              const SizedBox(width: 8),
              Text(
                _isExpanded ? 'Show Less' : 'Show More Details',
                style: AppTextStyles.fieldLabel.copyWith(
                  color: AppColors.accentText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentText.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${additionalFields.length}',
                  style: TextStyle(
                    color: AppColors.accentText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.accentText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: AppDecorations.sectionBorderDecoration,
      child: Text(
        title,
        style: AppTextStyles.fieldLabel.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  Widget _buildFieldsGrid(List<EntityField> fields, bool isLandscape, bool isMobile, {bool isRequired = false}) {
    // Determine columns based on layout
    int columns;
    if (isMobile) {
      columns = 1; // Single column on small screens
    } else if (isLandscape) {
      columns = 3; // Three columns in landscape
    } else {
      columns = 2; // Two columns in portrait
    }

    return _buildGridLayout(fields, columns, isRequired);
  }

  Widget _buildGridLayout(List<EntityField> fields, int columns, bool isRequired) {
    final rows = <Widget>[];
    for (int i = 0; i < fields.length; i += columns) {
      final rowChildren = <Widget>[];
      for (int j = 0; j < columns; j++) {
        if (i + j < fields.length) {
          rowChildren.add(Expanded(child: _buildFieldCard(fields[i + j], isRequired)));
        } else {
          rowChildren.add(const Expanded(child: SizedBox()));
        }
        if (j < columns - 1) {
          rowChildren.add(const SizedBox(width: 4));
        }
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildFieldCard(EntityField field, bool isRequired) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isRequired ? AppColors.accentBackgroundWithOpacity : AppColors.inputBackground,
        border: Border.all(
          color: isRequired ? AppColors.accentBorderWithOpacity : AppColors.primaryBorder,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: AppTextStyles.fieldLabel.copyWith(
              color: isRequired ? AppColors.accentText : AppColors.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          _buildFieldValue(field, isRequired),
        ],
      ),
    );
  }

  Widget _buildFieldValue(EntityField field, bool isRequired) {
    if (field.value == null || field.value!.trim().isEmpty) {
      return Text(
        '—',
        style: AppTextStyles.inputText.copyWith(
          color: AppColors.secondaryText,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      );
    }

    final String value = field.value!.trim();
    final baseStyle = AppTextStyles.inputText.copyWith(
      fontWeight: isRequired ? FontWeight.w600 : FontWeight.normal,
      fontSize: 13,
    );

    switch (field.type) {
      case EntityFieldType.status:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: AppDecorations.getStatusDecoration(value),
          child: Text(
            value,
            style: value.statusTextStyle.copyWith(
              fontWeight: isRequired ? FontWeight.w600 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        );
      case EntityFieldType.multiline:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.sectionBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: baseStyle),
        );
      case EntityFieldType.date:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: isRequired ? AppColors.accentText : AppColors.secondaryText,
            ),
            const SizedBox(width: 3),
            Expanded(child: Text(value, style: baseStyle)),
          ],
        );
      case EntityFieldType.number:
        return Text(
          value,
          // style: baseStyle.copyWith(
          //   fontVariant: [FontVariant.tabularNums],
          // ),
        );
      case EntityFieldType.text:
      default:
        return Text(value, style: baseStyle);
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: AppDecorations.footerBorderDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.cancelButtonStyle,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}