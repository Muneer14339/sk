// lib/user_dashboard/presentation/widgets/common/form_wrapper_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../../core/theme/user_app_theme.dart';
import '../tab_widgets/armory_tab_view.dart';
import 'inline_form_wrapper.dart';
import 'common_widgets.dart';

/// Centralized widget to handle form display logic
/// Prevents form from closing when dropdown options are loaded
class FormWrapperWidget extends StatefulWidget {
  final String userId;
  final ArmoryTabType tabType;
  final Widget Function(ArmoryState state) listBuilder;
  final Widget Function(String userId) formBuilder;
  final String formTitle;
  final String? formBadge;
  final String cardTitle;
  final String cardDescription;
  final Function(BuildContext)? onAddPressed;
  final int? Function(ArmoryState)? getItemCount;

  const FormWrapperWidget({
    super.key,
    required this.userId,
    required this.tabType,
    required this.listBuilder,
    required this.formBuilder,
    required this.formTitle,
    this.formBadge,
    required this.cardTitle,
    required this.cardDescription,
    this.onAddPressed,
    this.getItemCount,
  });

  @override
  State<FormWrapperWidget> createState() => _FormWrapperWidgetState();
}

class _FormWrapperWidgetState extends State<FormWrapperWidget> {
  bool _showingForm = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        // Only hide form on explicit actions
        if (state is ArmoryActionSuccess) {
          setState(() => _showingForm = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.successColor,
            ),
          );
        } else if (state is ArmoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorColor,
            ),
          );
        } else if (state is ShowingAddForm && state.tabType == widget.tabType) {
          // Show form when ShowAddFormEvent is triggered
          setState(() => _showingForm = true);
        } else if (state is ArmoryInitial) {
          // Hide form when HideFormEvent is triggered
          setState(() => _showingForm = false);
        }
      },
      builder: (context, state) {
        // Show form based on local state, not bloc state
        if (_showingForm) {
          return InlineFormWrapper(
            title: widget.formTitle,
            badge: widget.formBadge,
            onCancel: () {
              context.read<ArmoryBloc>().add(const HideFormEvent());
            },
            child: widget.formBuilder(widget.userId),
          );
        }

        // Show normal list view
        return _buildCard(state);
      },
    );
  }

  Widget _buildCard(ArmoryState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(state),
        widget.listBuilder(state),
      ],
    );
  }

  Widget _buildHeader(ArmoryState state) {
    final itemCount = widget.getItemCount?.call(state);

    return Container(
      padding: AppSizes.cardPadding,
      decoration: AppDecorations.headerBorderDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.cardTitle,
                        style: AppTextStyles.cardTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (itemCount != null) ...[
                      const SizedBox(width: 8),
                      CommonWidgets.buildCountBadge(itemCount, 'items'),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.cardDescription,
                  style: AppTextStyles.cardDescription,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: state is ArmoryLoadingAction
                ? null
                : () {
              if (widget.onAddPressed != null) {
                widget.onAddPressed!(context);
              } else {
                context.read<ArmoryBloc>().add(
                  ShowAddFormEvent(tabType: widget.tabType),
                );
              }
            },
            icon: state is ArmoryLoadingAction
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.buttonText,
              ),
            )
                : const Icon(Icons.add, size: AppSizes.smallIcon),
            label: const Text('Add'),
            style: AppButtonStyles.addButtonStyle,
          ),
        ],
      ),
    );
  }
}
