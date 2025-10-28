// // lib/armory/presentation/widgets/common/item_details_dialog.dart
// import 'package:flutter/material.dart';
// import '../../../../core/theme/app_theme.dart';
// import 'armory_constants.dart';
// import 'entity_field_helper.dart';
//
// class ItemDetailsDialog extends StatefulWidget {
//   final dynamic item;
//
//   const ItemDetailsDialog({super.key, required this.item});
//
//   static void show(BuildContext context, dynamic item) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) => ItemDetailsDialog(item: item),
//     );
//   }
//
//   @override
//   State<ItemDetailsDialog> createState() => _ItemDetailsDialogState();
// }
//
// class _ItemDetailsDialogState extends State<ItemDetailsDialog> {
//   bool _isExpanded = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final details = EntityFieldHelper.extractDetails(widget.item);
//     final orientation = MediaQuery.of(context).orientation;
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     final isLandscape = orientation == Orientation.landscape;
//     final isMobile = screenWidth < 400;
//     final isTablet = screenWidth >= 520 && screenWidth < 800;
//
//     return Dialog(
//       backgroundColor: AppTheme.surface(context),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(ArmoryConstants.cardBorderRadius),
//       ),
//       child: Container(
//         constraints: BoxConstraints(
//           maxWidth: isLandscape ? 750 : (isTablet ? 600 : screenWidth * 0.95),
//           maxHeight: MediaQuery.of(context).size.height *
//               (isLandscape ? 0.85 : (_isExpanded ? 0.85 : 0.5)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(details, context),
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
//                 child: _buildContent(details, isLandscape, isMobile),
//               ),
//             ),
//             if (!isLandscape) _buildExpandableWidget(details),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader(EntityDetailsData details, BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: AppTheme.border(context)),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   details.title,
//                   style: AppTheme.titleMedium(context).copyWith(fontSize: 15),
//                   maxLines: 2,
//                 ),
//                 if (details.subtitle.isNotEmpty) ...[
//                   const SizedBox(height: 1),
//                   Text(
//                     details.subtitle,
//                     style: AppTheme.labelMedium(context).copyWith(
//                       color: AppTheme.secondary(context),
//                       fontWeight: FontWeight.w500,
//                       fontSize: 11,
//                     ),
//                     maxLines: 1,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: () => Navigator.of(context).pop(),
//             icon: Icon(
//               Icons.close,
//               color: AppTheme.textPrimary(context),
//               size: 18,
//             ),
//             constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//             padding: EdgeInsets.zero,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildContent(EntityDetailsData details, bool isLandscape, bool isMobile) {
//     final requiredFields = details.sections.where((f) => f.isImportant).toList();
//     final additionalFields = details.sections.where((f) => !f.isImportant).toList();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (requiredFields.isNotEmpty) ...[
//           _buildSectionHeader('Key Information'),
//           const SizedBox(height: 4),
//           _buildFieldsGrid(requiredFields, isLandscape, isMobile, isRequired: true),
//         ],
//         if (additionalFields.isNotEmpty && (isLandscape || _isExpanded)) ...[
//           if (requiredFields.isNotEmpty) const SizedBox(height: 12),
//           _buildSectionHeader('Additional Details'),
//           const SizedBox(height: 4),
//           _buildFieldsGrid(additionalFields, isLandscape, isMobile),
//           const SizedBox(height: 8),
//         ],
//       ],
//     );
//   }
//
//   Widget _buildExpandableWidget(EntityDetailsData details) {
//     final additionalFields = details.sections.where((f) => !f.isImportant).toList();
//     if (additionalFields.isEmpty) return const SizedBox.shrink();
//
//     return Container(
//       decoration: BoxDecoration(
//         border: Border(
//           top: BorderSide(color: AppTheme.border(context).withOpacity(0.3)),
//         ),
//         color: AppTheme.secondary(context).withOpacity(0.1),
//       ),
//       child: InkWell(
//         onTap: () => setState(() => _isExpanded = !_isExpanded),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//           child: Row(
//             children: [
//               const SizedBox(width: 8),
//               Text(
//                 _isExpanded ? 'Show Less' : 'Show More Details',
//                 style: AppTheme.labelMedium(context).copyWith(
//                   color: AppTheme.secondary(context),
//                   fontWeight: FontWeight.w600,
//                   fontSize: 13,
//                 ),
//               ),
//               const Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: AppTheme.secondary(context).withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   '${additionalFields.length}',
//                   style: TextStyle(
//                     color: AppTheme.secondary(context),
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               Icon(
//                 _isExpanded ? Icons.expand_less : Icons.expand_more,
//                 color: AppTheme.secondary(context),
//                 size: 20,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: AppTheme.border(context)),
//         ),
//       ),
//       child: Text(
//         title,
//         style: AppTheme.labelMedium(context).copyWith(
//           fontSize: 12,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFieldsGrid(
//       List<EntityField> fields, bool isLandscape, bool isMobile,
//       {bool isRequired = false}) {
//     int columns;
//     if (isMobile) {
//       columns = 1;
//     } else if (isLandscape) {
//       columns = 3;
//     } else {
//       columns = 2;
//     }
//
//     return _buildGridLayout(fields, columns, isRequired);
//   }
//
//   Widget _buildGridLayout(
//       List<EntityField> fields, int columns, bool isRequired) {
//     final rows = <Widget>[];
//     for (int i = 0; i < fields.length; i += columns) {
//       final rowChildren = <Widget>[];
//       for (int j = 0; j < columns; j++) {
//         if (i + j < fields.length) {
//           rowChildren.add(Expanded(child: _buildFieldCard(fields[i + j], isRequired)));
//         } else {
//           rowChildren.add(const Expanded(child: SizedBox()));
//         }
//         if (j < columns - 1) {
//           rowChildren.add(const SizedBox(width: 4));
//         }
//       }
//       rows.add(
//         Padding(
//           padding: const EdgeInsets.only(bottom: 4),
//           child: IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: rowChildren,
//             ),
//           ),
//         ),
//       );
//     }
//
//     return Column(children: rows);
//   }
//
//   Widget _buildFieldCard(EntityField field, bool isRequired) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: isRequired
//             ? AppTheme.secondary(context).withOpacity(0.1)
//             : AppTheme.surfaceVariant(context),
//         border: Border.all(
//           color: isRequired
//               ? AppTheme.secondary(context).withOpacity(0.2)
//               : AppTheme.border(context),
//         ),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             field.label,
//             style: AppTheme.labelSmall(context).copyWith(
//               color: isRequired
//                   ? AppTheme.secondary(context)
//                   : AppTheme.textSecondary(context),
//               fontWeight: FontWeight.w600,
//               fontSize: 10,
//             ),
//           ),
//           const SizedBox(height: 3),
//           _buildFieldValue(field, isRequired),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFieldValue(EntityField field, bool isRequired) {
//     if (field.value == null || field.value!.trim().isEmpty) {
//       return Text(
//         '—',
//         style: AppTheme.bodySmall(context).copyWith(
//           color: AppTheme.textSecondary(context),
//           fontStyle: FontStyle.italic,
//           fontSize: 13,
//         ),
//       );
//     }
//
//     final String value = field.value!.trim();
//     final baseStyle = AppTheme.bodySmall(context).copyWith(
//       fontWeight: isRequired ? FontWeight.w600 : FontWeight.normal,
//       fontSize: 13,
//     );
//
//     switch (field.type) {
//       case EntityFieldType.status:
//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//           decoration: BoxDecoration(
//             color: value.statusColor(context).withOpacity(0.1),
//             border: Border.all(
//               color: value.statusColor(context).withOpacity(0.2),
//             ),
//             borderRadius: BorderRadius.circular(999),
//           ),
//           child: Text(
//             value,
//             style: value.statusTextStyle(context).copyWith(
//               fontWeight: isRequired ? FontWeight.w600 : FontWeight.w500,
//               fontSize: 10,
//             ),
//           ),
//         );
//       case EntityFieldType.multiline:
//         return Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: AppTheme.surface(context),
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: Text(value, style: baseStyle),
//         );
//       case EntityFieldType.date:
//         return Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.calendar_today_outlined,
//               size: 12,
//               color: isRequired
//                   ? AppTheme.secondary(context)
//                   : AppTheme.textSecondary(context),
//             ),
//             const SizedBox(width: 3),
//             Expanded(child: Text(value, style: baseStyle)),
//           ],
//         );
//       case EntityFieldType.number:
//       case EntityFieldType.text:
//       default:
//         return Text(value, style: baseStyle);
//     }
//   }
// }