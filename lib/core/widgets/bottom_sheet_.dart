import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';
import 'modified_container.dart';

// ignore: must_be_immutable
class AppBottomSheetOld extends StatelessWidget {
  const AppBottomSheetOld(
      {required this.children,
      this.height,
      this.title,
      this.formKey,
      super.key});
  final List<Widget> children;
  final Key? formKey;
  final double? height;
  final String? title;
  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.001),
      child: DraggableScrollableSheet(
        initialChildSize: height ?? 0.90,
        minChildSize: 0.3,
        maxChildSize: height ?? 0.90,
        builder: (_, controller) {
          return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.0),
                  topRight: Radius.circular(25.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove,
                    color: Colors.grey[600],
                  ),
                  Text(title ?? 'Select Action', style: bottomSheetTitle()),
                  Divider(color: Colors.grey.shade500),
                  Flexible(
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                          padding: hPadding,
                          controller: controller,
                          // shrinkWrap: true,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children)),
                    ),
                  ),
                ],
              ));
        },
      ),
    );
  }
}

class AppBottomSheet extends StatefulWidget {
  const AppBottomSheet(
      {required this.children,
      this.height,
      this.initialHeight,
      this.title,
      this.paddding,
      this.formKey,
      this.scrollWidget,
      this.hideInitials,
      this.scrollable,
      super.key});

  final List<Widget> children;
  final Key? formKey;
  final double? height, initialHeight;
  final String? title;
  final EdgeInsets? paddding;
  final Widget? scrollWidget;
  final bool? hideInitials;
  final bool? scrollable;

  @override
  State<AppBottomSheet> createState() => _AppBottomSheetState();
}

class _AppBottomSheetState extends State<AppBottomSheet> {
  late DraggableScrollableController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = DraggableScrollableController();
    // Add focus listener for when the keyboard is activated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addFocusListeners();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addFocusListeners() {
    for (var child in widget.children) {
      log('child: ${widget.scrollWidget} -- ${widget.scrollWidget.runtimeType} -- ${child.runtimeType == widget.scrollWidget.runtimeType}');
      if (child.runtimeType == widget.scrollWidget.runtimeType ||
          child is FocusableActionDetector) {
        FocusScope.of(context).children.forEach((focusNode) {
          focusNode.addListener(() {
            if (focusNode.hasFocus) {
              // Expand the bottom sheet when a TextField is focused
              _scrollController.animateTo(
                widget.height ?? 0.9,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.001),
      child: DraggableScrollableSheet(
        controller: _scrollController,
        initialChildSize: widget.initialHeight ?? widget.height ?? 0.80,
        minChildSize: 0.2,
        maxChildSize: widget.height ?? 0.90,
        builder: (_, controller) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25.0),
                topRight: Radius.circular(25.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.hideInitials == true)
                  ModifiedContainer(
                    color: AppColors.black.withValues(alpha: 0.12),
                    borderRadius: 100,
                    height: 4,
                    width: 32,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                  ),
                if (widget.hideInitials != true)
                  Icon(
                    Icons.remove,
                    color: Colors.grey[600],
                  ),
                if (widget.hideInitials != true)
                  Text(
                    widget.title ?? 'Select Action',
                    style: bottomSheetTitle(),
                  ),
                if (widget.hideInitials != true)
                  Divider(
                    color: Colors.grey.shade500,
                  ),
                Flexible(
                  child: Form(
                    key: widget.formKey,
                    child: SingleChildScrollView(
                      padding: widget.paddding ?? hPadding,
                      controller: controller,
                      physics: widget.scrollable == false
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.children),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AppBottomSheetWidget extends StatelessWidget {
  const AppBottomSheetWidget(
      {required this.child,
      this.height,
      this.formKey,
      this.title,
      this.hideInitials,
      super.key});
  final Widget child;
  final Key? formKey;
  final double? height;
  final String? title;
  final bool? hideInitials;
  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;
    return Container(
        color: const Color.fromRGBO(0, 0, 0, 0.001),
        child: DraggableScrollableSheet(
            initialChildSize: height ?? 0.90,
            minChildSize: 0.2,
            maxChildSize: height ?? 0.90,
            builder: (_, controller) {
              return Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hideInitials == true)
                        ModifiedContainer(
                          color: AppColors.black.withValues(alpha: 0.12),
                          borderRadius: 100,
                          height: 4,
                          width: 32,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      if (hideInitials != true)
                        Icon(
                          Icons.remove,
                          color: Colors.grey[600],
                        ),
                      if (hideInitials != true)
                        Text(
                          title ?? 'Select Action',
                          style: bottomSheetTitle(),
                        ),
                      if (hideInitials != true)
                        Divider(
                          color: Colors.grey.shade500,
                        ),
                      Flexible(
                        child: child,
                      ),
                    ],
                  ));
            }));
  }
}

//
class AppBottomSheetWidgetStripe extends StatelessWidget {
  const AppBottomSheetWidgetStripe(
      {required this.child, this.height, this.formKey, this.title, super.key});
  final Widget child;
  final Key? formKey;
  final double? height;
  final String? title;
  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;
    return Container(
        color: const Color.fromRGBO(0, 0, 0, 0.001),
        child: DraggableScrollableSheet(
            initialChildSize: height ?? 0.90,
            minChildSize: 0.2,
            maxChildSize: height ?? 0.90,
            builder: (_, controller) {
              return Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.remove,
                        color: Colors.grey[600],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title ?? 'Select Action',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: Colors.grey.shade500,
                      ),
                      Flexible(
                        child: child,
                      ),
                    ],
                  ));
            }));
  }
}

//
