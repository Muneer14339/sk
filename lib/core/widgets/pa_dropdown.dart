// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../theme/app_colors.dart';
// import 'custom_textfield.dart';
// import 'dropdown_custom.dart';
// import 'smart_drop_down.dart';
//
// class PaDropdown extends StatefulWidget {
//   final List<String> items;
//   final String initialValue;
//   final String? hint;
//   final bool allowCustomItem;
//   final bool isStageSection;
//   final String? stageTitle;
//   final Widget? stageWidget;
//   final bool showSearch;
//   final Function(String)? selectItemCall;
//   final String? selectedValue;
//   final bool? isPreviousSelected;
//
//   const PaDropdown({
//     super.key,
//     required this.items,
//     this.hint,
//     this.initialValue = '',
//     this.stageTitle,
//     this.stageWidget,
//     this.allowCustomItem = false,
//     this.isStageSection = false,
//     required this.selectItemCall,
//     this.selectedValue,
//     this.showSearch = false,
//     this.isPreviousSelected,
//   });
//
//   @override
//   State<PaDropdown> createState() => _PaDropdownState();
// }
//
// class _PaDropdownState extends State<PaDropdown> {
//   final OverlayPortalController _controller = OverlayPortalController();
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         if (widget.isPreviousSelected == true) {
//           // toast('Select above field first!');
//         }
//       },
//       child: AbsorbPointer(
//         absorbing: widget.isPreviousSelected == true,
//         child: BlocProvider(
//           create: (context) => DropDownCubit(widget.items),
//           child: SmartDropdown(
//             itemLength: widget.allowCustomItem
//                 ? widget.items.length + 1
//                 : widget.items.length,
//             isStage: widget.isStageSection,
//             controller: _controller,
//             buttonBuilder: (context, onTap, isOpen) {
//               return widget.isStageSection
//                   ? StageSection(
//                       iconWidget: widget.stageWidget!,
//                       title: widget.stageTitle!,
//                       onTap: onTap,
//                       isDropdown: true,
//                       isDropDownOpen: isOpen,
//                       selectionText: widget.selectedValue!,
//                     )
//                   : DropdownCustom(
//                       controller:
//                           TextEditingController(text: widget.selectedValue),
//                       dropDownOpen: isOpen,
//                       hint: widget.hint ?? '',
//                       selectedValue: widget.selectedValue,
//                       onTap: onTap,
//                     );
//             },
//             menuBuilder: (context, toggleDropDown, width) {
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: MenuWidget(
//                   width: width,
//                   items: widget.items,
//                   allowCustomItem: widget.allowCustomItem,
//                   selectedItem: widget.selectedValue,
//                   onItemSelected: (value) {
//                     toggleDropDown();
//                     widget.selectItemCall!(value);
//                   },
//                   showSearch: widget.showSearch,
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class MenuWidget extends StatefulWidget {
//   const MenuWidget({
//     super.key,
//     this.width,
//     required this.items,
//     required this.onItemSelected,
//     this.allowCustomItem = false,
//     required this.selectedItem,
//     this.hint,
//     this.showSearch = false,
//   });
//
//   final double? width;
//   final List<String> items;
//   final Function(String) onItemSelected;
//   final bool allowCustomItem;
//   final String? selectedItem;
//   final String? hint;
//   final bool showSearch;
//
//   @override
//   State<MenuWidget> createState() => _MenuWidgetState();
// }
//
// class _MenuWidgetState extends State<MenuWidget> {
//   final TextEditingController _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.showSearch) {
//       _searchController.addListener(_filterItems);
//     }
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _filterItems() {
//     final query = _searchController.text.toLowerCase();
//     context.read<DropDownCubit>().filterItems(query);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Theme.of(context).canvasColor,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: isDark
//                 ? Colors.black.withOpacity(0.3)
//                 : Colors.grey.withOpacity(0.15),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//             spreadRadius: 0,
//           ),
//         ],
//       ),
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxHeight: 280),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (widget.showSearch) ...[
//               Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: CustomTextField(
//                   hintText: 'Search items...',
//                   controller: _searchController,
//                 ),
//               ),
//             ],
//             Flexible(
//               child: Scrollbar(
//                 radius: const Radius.circular(8),
//                 child: BlocBuilder<DropDownCubit, List<String>>(
//                   builder: (context, filteredItems) {
//                     return ListView.separated(
//                       shrinkWrap: true,
//                       padding: EdgeInsets.zero,
//                       separatorBuilder: (context, index) =>
//                           const SizedBox(height: 4),
//                       itemCount: filteredItems.length +
//                           (widget.allowCustomItem ? 1 : 0),
//                       itemBuilder: (context, index) {
//                         if (index < filteredItems.length) {
//                           final item = filteredItems[index];
//                           return _ModernDropdownItem(
//                             isSelected: widget.selectedItem == item,
//                             text: item,
//                             onTap: () {
//                               widget.onItemSelected(item);
//                               _searchController.text = '';
//                             },
//                           );
//                         } else {
//                           return _ModernDropdownItem(
//                             text: 'Other...',
//                             isCustom: true,
//                             onTap: () {
//                               _showCustomItemDialog(context);
//                             },
//                           );
//                         }
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showCustomItemDialog(BuildContext context) {
//     final TextEditingController customItemController = TextEditingController();
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           child: Container(
//             width: 400,
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Theme.of(context).canvasColor,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: isDark
//                       ? Colors.black.withOpacity(0.4)
//                       : Colors.grey.withOpacity(0.2),
//                   blurRadius: 30,
//                   offset: const Offset(0, 12),
//                   spreadRadius: 0,
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         Icons.add_circle_outline,
//                         color: AppColors.kPrimaryColor,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       'Other...',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Theme.of(context).textTheme.titleLarge?.color,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 CustomTextField(
//                   labelText: 'Enter custom value',
//                   controller: customItemController,
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             side: BorderSide(
//                               color: Colors.grey.shade300,
//                               width: 1,
//                             ),
//                           ),
//                         ),
//                         child: Text(
//                           'Cancel',
//                           style: TextStyle(
//                             color:
//                                 Theme.of(context).textTheme.bodyMedium?.color,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           if (customItemController.text.isNotEmpty) {
//                             widget.onItemSelected(customItemController.text);
//                             Navigator.of(context).pop();
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.kPrimaryColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 0,
//                         ),
//                         child: const Text(
//                           'Add Item',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _ModernDropdownItem extends StatelessWidget {
//   const _ModernDropdownItem({
//     required this.text,
//     required this.onTap,
//     this.isSelected = false,
//     this.isCustom = false,
//   });
//
//   final bool isSelected;
//   final bool isCustom;
//   final String text;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: isSelected
//             ? AppColors.kPrimaryColor
//             : isCustom
//                 ? (isDark ? Colors.grey.shade800 : Colors.grey.shade50)
//                 : Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSelected
//               ? AppColors.kPrimaryColor
//               : isCustom
//                   ? AppColors.kPrimaryColor.withOpacity(0.3)
//                   : Colors.transparent,
//           width: 1,
//         ),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: onTap,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             child: Row(
//               children: [
//                 if (isCustom) ...[
//                   Icon(
//                     Icons.add_circle_outline,
//                     size: 18,
//                     color: AppColors.kPrimaryColor,
//                   ),
//                   const SizedBox(width: 8),
//                 ],
//                 Expanded(
//                   child: Text(
//                     text,
//                     style: TextStyle(
//                       color: isSelected
//                           ? Colors.white
//                           : isCustom
//                               ? AppColors.kPrimaryColor
//                               : Theme.of(context).textTheme.bodyMedium?.color,
//                       fontSize: 16,
//                       fontWeight: isSelected || isCustom
//                           ? FontWeight.w500
//                           : FontWeight.w400,
//                     ),
//                   ),
//                 ),
//                 if (isSelected)
//                   Icon(
//                     Icons.check_circle,
//                     size: 18,
//                     color: Colors.white,
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // -------------------------------- Generics
//
// class PaDropdownGen<T> extends StatefulWidget {
//   final List<T> items;
//   final T initialValue;
//   final String? hint;
//   final bool allowCustomItem;
//   final bool isStageSection;
//   final String? stageTitle;
//   final String? fieldName;
//   final String? stageIcon;
//   final bool showSearch;
//   final Function(T)? selectItemCall;
//   final T? selectedValue;
//   final String Function(T) getLabel;
//   final void Function(T) onDelTap;
//   final void Function(bool)? itemTapped;
//   final bool? isPreviousSelected;
//   final bool? showDelIcon;
//   final bool? noPadding;
//   final double? menuHorizontalPadding;
//   final ScrollController? scrollController;
//
//   const PaDropdownGen({
//     super.key,
//     required this.items,
//     this.hint,
//     required this.initialValue,
//     this.stageTitle,
//     this.stageIcon,
//     this.allowCustomItem = false,
//     this.isStageSection = false,
//     required this.selectItemCall,
//     this.selectedValue,
//     required this.getLabel,
//     this.fieldName,
//     this.showSearch = false,
//     this.isPreviousSelected = false,
//     this.showDelIcon = false,
//     this.noPadding = false,
//     this.menuHorizontalPadding,
//     this.scrollController,
//     required this.onDelTap,
//     this.itemTapped,
//   });
//
//   @override
//   State<PaDropdownGen<T>> createState() => _PaDropdownGenState<T>();
// }
//
// class _PaDropdownGenState<T> extends State<PaDropdownGen<T>> {
//   final OverlayPortalController _controller = OverlayPortalController();
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         if (widget.isPreviousSelected == true) {
//           // toast('Select above field first!');
//         } else if (widget.items.isEmpty) {
//           // toast('No items found');
//         }
//       },
//       child: AbsorbPointer(
//         absorbing: widget.isPreviousSelected == true || widget.items.isEmpty,
//         child: BlocProvider(
//           create: (context) =>
//               DropDownCubitGen<T>(widget.items, widget.getLabel),
//           child: SmartDropdown(
//             itemLength: widget.items.length,
//             isStage: widget.isStageSection,
//             controller: _controller,
//             scrollController: widget.scrollController,
//             buttonBuilder: (context, onTap, isOpen) {
//               return widget.isStageSection
//                   ? StageSection(
//                       iconWidget: const Icon(Icons.travel_explore),
//                       title: widget.stageTitle ?? '',
//                       onTap: onTap,
//                       isDropdown: true,
//                       isDropDownOpen: isOpen,
//                       selectionText: widget.getLabel(widget.initialValue),
//                     )
//                   : DropdownCustom(
//                       noPadding: widget.noPadding ?? false,
//                       controller: TextEditingController(
//                           text: widget.getLabel(
//                               widget.selectedValue ?? widget.initialValue)),
//                       dropDownOpen: isOpen,
//                       hint: widget.hint ?? '',
//                       selectedValue: widget.getLabel(
//                           widget.selectedValue ?? widget.initialValue),
//                       onTap: onTap,
//                     );
//             },
//             menuBuilder: (context, toggleDropDown, width) {
//               return Padding(
//                 padding: EdgeInsets.symmetric(
//                     horizontal: widget.menuHorizontalPadding ?? 24),
//                 child: MenuWidgetGen<T>(
//                   width: width,
//                   items: widget.items,
//                   fieldName: widget.fieldName,
//                   allowCustomItem: widget.allowCustomItem,
//                   selectedItem: widget.selectedValue,
//                   getLabel: widget.getLabel,
//                   onDelTap: widget.onDelTap,
//                   itemTapped: widget.itemTapped ?? (v) {},
//                   showDelIcon: widget.showDelIcon ?? true,
//                   onItemSelected: (value) {
//                     toggleDropDown();
//                     widget.selectItemCall?.call(value);
//                   },
//                   showSearch: widget.showSearch,
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class MenuWidgetGen<T> extends StatefulWidget {
//   const MenuWidgetGen({
//     super.key,
//     this.width,
//     required this.items,
//     required this.onItemSelected,
//     this.allowCustomItem = false,
//     required this.selectedItem,
//     this.fieldName,
//     this.hint,
//     this.showSearch = false,
//     this.showDelIcon = true,
//     required this.getLabel,
//     required this.onDelTap,
//     required this.itemTapped,
//   });
//
//   final double? width;
//   final List<T> items;
//   final Function(T) onItemSelected;
//   final bool allowCustomItem;
//   final T? selectedItem;
//   final String? hint;
//   final String? fieldName;
//   final bool showSearch;
//   final bool showDelIcon;
//   final String Function(T) getLabel;
//   final void Function(T) onDelTap;
//   final void Function(bool) itemTapped;
//
//   @override
//   State<MenuWidgetGen<T>> createState() => _MenuWidgetGenState<T>();
// }
//
// class _MenuWidgetGenState<T> extends State<MenuWidgetGen<T>> {
//   final TextEditingController _searchController = TextEditingController();
//   Timer? _debounce;
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.showSearch) {
//       // Debounced search will be handled in _filterItems
//     }
//   }
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _filterItems(BuildContext context) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 300), () {
//       final query = _searchController.text.trim().toLowerCase();
//       context.read<DropDownCubitGen<T>>().filterItems(query);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Container(
//       width: widget.width,
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Theme.of(context).canvasColor,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: isDark
//                 ? Colors.black.withValues(alpha: 0.3)
//                 : Colors.grey.withValues(alpha: 0.15),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//             spreadRadius: 0,
//           ),
//         ],
//       ),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxHeight:
//               widget.items.any((p) => widget.getLabel(p) == 'Male') ? 120 : 280,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (widget.showSearch) ...[
//               Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: CustomTextField(
//                   onChanged: (_) => _filterItems(context),
//                   hintText: 'Search items...',
//                   controller: _searchController,
//                 ),
//               ),
//             ],
//             Flexible(
//               child: Scrollbar(
//                 radius: const Radius.circular(8),
//                 child: BlocBuilder<DropDownCubitGen<T>, List<T>>(
//                   builder: (context, filteredItems) {
//                     return ListView.separated(
//                       shrinkWrap: true,
//                       padding: EdgeInsets.zero,
//                       separatorBuilder: (context, index) =>
//                           const SizedBox(height: 4),
//                       itemCount: filteredItems.length +
//                           (widget.allowCustomItem ? 1 : 0),
//                       itemBuilder: (context, index) {
//                         if (index < filteredItems.length) {
//                           final item = filteredItems[index];
//                           return _DropdownItemGen<T>(
//                             isSelected: widget.selectedItem == item,
//                             text: widget.getLabel(item),
//                             onDelTap: widget.onDelTap,
//                             showDelIcon: widget.showDelIcon,
//                             item: item,
//                             onTap: () {
//                               widget.itemTapped(true);
//                               widget.onItemSelected(item);
//                               _searchController.text = '';
//                             },
//                           );
//                         } else {
//                           return _DropdownItemGen<T>(
//                             text: 'Other...',
//                             // isCustom: true,
//                             item: filteredItems.isNotEmpty
//                                 ? filteredItems.first
//                                 : widget.items.first,
//                             onTap: () {
//                               _showCustomItemDialog(
//                                   context, widget.fieldName ?? '');
//                             },
//                             showDelIcon: false,
//                             onDelTap: widget.onDelTap,
//                           );
//                         }
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showCustomItemDialog(BuildContext context, String fieldName) {
//     final TextEditingController customItemController = TextEditingController();
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           child: Container(
//             width: 400,
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Theme.of(context).canvasColor,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: isDark
//                       ? Colors.black.withOpacity(0.4)
//                       : Colors.grey.withOpacity(0.2),
//                   blurRadius: 30,
//                   offset: const Offset(0, 12),
//                   spreadRadius: 0,
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         Icons.add_circle_outline,
//                         color: AppColors.kPrimaryColor,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'Add Custom ${fieldName.isEmpty ? 'Item' : fieldName}',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: Theme.of(context).textTheme.titleLarge?.color,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 CustomTextField(
//                   hintText:
//                       'Enter custom value for ${fieldName.isEmpty ? 'item' : fieldName}',
//                   controller: customItemController,
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             side: BorderSide(
//                               color: Colors.grey.shade300,
//                               width: 1,
//                             ),
//                           ),
//                         ),
//                         child: Text(
//                           'Cancel',
//                           style: TextStyle(
//                             color:
//                                 Theme.of(context).textTheme.bodyMedium?.color,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           if (customItemController.text.isNotEmpty) {
//                             final newItem = _createUpdatedModel(
//                               fieldName,
//                               customItemController.text,
//                             );
//                             if (newItem != null) {
//                               log('new custom item ---- ${jsonEncode(newItem)}');
//                               widget.onItemSelected(newItem);
//                               widget.itemTapped(false);
//                             }
//                             Navigator.of(context).pop();
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.kPrimaryColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 0,
//                         ),
//                         child: const Text(
//                           'Add Item',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // T? _mapInputToType(String input) {
//   //   if (T == String) {
//   //     return input as T;
//   //   } else if (T == FirearmEntity) {
//   //     return FirearmEntity(
//   //       brand: input,
//   //       addedByUser: 1,
//   //     ) as T;
//   //   }
//   //   return null;
//   // }
//
//   T? _createUpdatedModel(String? fieldName, String inputValue) {
//     if (T == String) {
//       return inputValue as T;
//     } else if (T == FirearmEntity && fieldName != null) {
//       print('message--- $fieldName ---value ---$inputValue');
//       final FirearmEntity existingModel = widget.selectedItem as FirearmEntity;
//       existingModel.addedByUser = 1;
//       final Map<String, dynamic> updatedJson = existingModel.toJson();
//       updatedJson[fieldName] = inputValue;
//
//       if (fieldName == 'ammo_type') {
//         existingModel.ammoTypeMacIsCustom = true;
//       } else if (fieldName == 'brand') {
//         existingModel.brandIsCustom = true;
//       } else if (fieldName == 'model') {
//         existingModel.modelIsCustom = true;
//       } else if (fieldName == 'generation') {
//         existingModel.generationIsCustom = true;
//       } else if (fieldName == 'caliber') {
//         existingModel.caliberIsCustom = true;
//       } else if (fieldName == 'firing_machanism') {
//         existingModel.firingMacIsCustom = true;
//       }
//
//       return FirearmEntity.fromJson(updatedJson) as T;
//     }
//     return null;
//   }
// }
//
// class _DropdownItemGen<T> extends StatelessWidget {
//   const _DropdownItemGen({
//     required this.text,
//     required this.onTap,
//     required this.onDelTap,
//     this.showDelIcon = true,
//     required this.item,
//     this.isSelected = false,
//     this.customColor,
//   });
//
//   final bool isSelected;
//   final Color? customColor;
//   final String text;
//   final bool showDelIcon;
//   final T item;
//   final VoidCallback onTap;
//   final void Function(T) onDelTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 6),
//       child: Material(
//         color: customColor ??
//             (isSelected
//                 ? AppColors.kPrimaryColor
//                 : Theme.of(context).cardColor),
//         shape: RoundedRectangleBorder(
//           side: BorderSide(
//             width: 1,
//             color: Theme.of(context).canvasColor,
//           ),
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(6),
//           onTap: onTap,
//           child: SizedBox(
//             width: double.infinity,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     text,
//                     style: TextStyle(
//                       color: isSelected ? AppColors.white : null,
//                       fontSize: 16,
//                     ),
//                   ),
//                   if (showDelIcon)
//                     InkWell(
//                       onTap: () {
//                         onDelTap(item);
//                       },
//                       child: Icon(
//                         Icons.delete_outline,
//                         color: AppColors.kRedColor,
//                       ),
//                     )
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
