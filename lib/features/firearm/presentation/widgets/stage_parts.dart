import 'package:flutter/material.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/widgets/modified_container.dart';

class StageSection extends StatefulWidget {
  final String title;

  final Widget iconWidget;
  final String selectionText;
  final bool isDropdown;
  final bool isDropDownOpen;
  final VoidCallback? onTap;

  final List<String>? dropdownItems;
  const StageSection(
      {super.key,
      required this.title,
      required this.selectionText,
      this.onTap,
      this.isDropdown = false,
      this.isDropDownOpen = false,
      required this.iconWidget,
      this.dropdownItems});

  @override
  State<StageSection> createState() => _StageSectionState();
}

class _StageSectionState extends State<StageSection> {
  @override
  void initState() {
    super.initState();
    if (widget.dropdownItems != null && widget.dropdownItems!.isNotEmpty) {
      selectedValue = widget.dropdownItems!.first;
    }
  }

  String? selectedValue;
  @override
  Widget build(BuildContext context) {
    return ModifiedContainer(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: widget.onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
              color: Theme.of(context).highlightColor,
              width: 1.0), // Grey outline
          borderRadius: BorderRadius.circular(10.0), // Rounded corners
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              widget.iconWidget,
              SizedBox(width: 15),
              Text(widget.title,
                  style: TextStyle(letterSpacing: 0.6, fontSize: 16)),
              const Spacer(),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 100, minWidth: 70),
                child: Text(
                  textAlign: TextAlign.end,
                  widget.selectionText,
                  style:
                      TextStyle(color: AppColors.greyTextColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              if (!widget.isDropdown) ...[
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                ),
              ] else ...[
                widget.isDropDownOpen
                    ? Transform.rotate(
                        angle: -1.57, // Rotate 90 degrees (π/2 radians)
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          // color: AppColors.black,
                          size: 18,
                        ),
                      )
                    : Transform.rotate(
                        angle: 1.57, // Rotate 90 degrees (π/2 radians)
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          // color: AppColors.black,
                          size: 18,
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
