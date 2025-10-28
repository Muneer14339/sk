import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import 'armory_constants.dart';
import 'common_delete_dilogue.dart';
import 'inline_form_wrapper.dart';
import 'common_widgets.dart';

class FormWrapperWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocConsumer<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        if (state is ArmoryActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.success(context),
            ),
          );
        } else if (state is ArmoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error(context),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ShowingAddForm && state.tabType == tabType) {
          return InlineFormWrapper(
            title: formTitle,
            badge: formBadge,
            onCancel: () {
              context.read<ArmoryBloc>().add(const HideFormEvent());
            },
            child: formBuilder(userId),
          );
        }

        return _buildCard(context, state);
      },
    );
  }

  Widget _buildCard(BuildContext context, ArmoryState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, state),
        listBuilder(state),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ArmoryState state) {
    final itemCount = getItemCount?.call(state);

    return Container(
      padding: ArmoryConstants.cardPadding,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
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
                        cardTitle,
                        style: AppTheme.titleLarge(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (itemCount != null) ...[
                      const SizedBox(width: 8),
                      CommonWidgets.buildCountBadge(context, itemCount, 'items'),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  cardDescription,
                  style: AppTheme.labelMedium(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: state is ArmoryLoadingAction
                ? null
                : () {
              if (onAddPressed != null) {
                onAddPressed!(context);
              } else {
                context.read<ArmoryBloc>().add(
                  ShowAddFormEvent(tabType: tabType),
                );
              }
            },
            icon: state is ArmoryLoadingAction
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary(context),
              ),
            )
                : const Icon(Icons.add, size: ArmoryConstants.smallIcon),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}