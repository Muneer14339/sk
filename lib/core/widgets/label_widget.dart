import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/theme/app_colors.dart';
import 'package:pulse_skadi/core/widgets/custom_textfield.dart';
import 'package:pulse_skadi/features/gear_setup/presentation/bloc/gear_setup_bloc.dart';

class LabelWidget extends StatelessWidget {
  const LabelWidget({required this.label, this.color, super.key});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 14,
            color: color ?? AppColors.kPrimaryColor,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Enhanced LabelValueWidget with professional styling
class LabelValueWidget extends StatelessWidget {
  const LabelValueWidget({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.isImportant = false,
    super.key,
  });

  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final bool isImportant;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          // color: isImportant
          //     ? AppColors.kGreenColor.withValues(alpha: 0.3)
          //     : Colors.grey.shade200,
          color: Colors.grey.shade200,
          // width: isImportant ? 2 : 1,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: color ?? AppColors.kPrimaryColor,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color:
                    (color ?? AppColors.kPrimaryColor).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              style: TextStyle(
                fontSize: 14,
                color: value.isEmpty
                    ? Colors.grey.shade400
                    : color ?? AppColors.kPrimaryColor,
                fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w600,
                fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Section Header Widget
class SectionHeaderWidget extends StatelessWidget {
  const SectionHeaderWidget({
    required this.title,
    this.backgroundColor,
    this.textColor,
    this.icon,
    super.key,
  });

  final String title;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [
        //     backgroundColor ?? AppColors.kGreenColor,
        //     (backgroundColor ?? AppColors.kGreenColor).withValues(alpha: 0.8),
        //   ],
        //   begin: Alignment.centerLeft,
        //   end: Alignment.centerRight,
        // ),
        color: backgroundColor ?? AppColors.kGreenColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: (backgroundColor ?? AppColors.kGreenColor)
        //         .withValues(alpha: 0.3),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor ?? AppColors.kGreenColor,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor ?? AppColors.kGreenColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Professional Divider Widget
class ProfessionalDivider extends StatelessWidget {
  const ProfessionalDivider({
    this.color,
    this.thickness = 1,
    this.indent = 16,
    this.endIndent = 16,
    super.key,
  });

  final Color? color;
  final double thickness;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: indent,
        right: endIndent,
        top: 16,
        bottom: 16,
      ),
      height: thickness,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color ?? AppColors.kGreenColor.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// Enhanced Primary Button with better styling
class EnhancedPrimaryButton extends StatelessWidget {
  const EnhancedPrimaryButton({
    required this.title,
    required this.onTap,
    this.buttonColor,
    this.textColor,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String title;
  final VoidCallback onTap;
  final Color? buttonColor;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? AppColors.kGreenColor,
          foregroundColor: textColor ?? AppColors.white,
          elevation: 4,
          shadowColor: (buttonColor ?? AppColors.kGreenColor).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class GearSetupDisplayWidget extends StatelessWidget {
  GearSetupDisplayWidget({required this.state, super.key});
  final GearSetupState state;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        child: Column(
          children: [
            // Firearm Section
            SectionHeaderWidget(
              title: 'Firearm',
              icon: Icons.gps_fixed,
            ),
            LabelValueWidget(
              label: 'Type',
              value: state.gearSetup.firearm.type ?? '',
              icon: Icons.category,
              isImportant: true,
            ),
            LabelValueWidget(
              label: 'Brand',
              value: state.gearSetup.firearm.brand ?? '',
              icon: Icons.business,
            ),
            LabelValueWidget(
              label: 'Model',
              value: state.gearSetup.firearm.model ?? '',
              icon: Icons.model_training,
            ),
            LabelValueWidget(
              label: 'Generation',
              value: state.gearSetup.firearm.generation ?? '',
              icon: Icons.timeline,
            ),
            LabelValueWidget(
              label: 'Caliber',
              value: state.gearSetup.firearm.caliber ?? '',
              icon: Icons.straighten,
              isImportant: true,
            ),

            // Advanced Info (if expanded)
            if (state.gearSetup.firearm.advancedInfoExpanded == true) ...[
              const ProfessionalDivider(),
              LabelValueWidget(
                label: 'Serial Number',
                value: state.gearSetup.firearm.serialNumber ?? '',
                icon: Icons.qr_code,
              ),
              LabelValueWidget(
                label: 'Barrel Length',
                value: state.gearSetup.firearm.barrelLength ?? '',
                icon: Icons.straighten,
              ),
              LabelValueWidget(
                label: 'Overall Length',
                value: state.gearSetup.firearm.overallLength ?? '',
                icon: Icons.straighten,
              ),
              LabelValueWidget(
                label: 'Weight',
                value: state.gearSetup.firearm.weight ?? '',
                icon: Icons.scale,
              ),
              LabelValueWidget(
                label: 'Rifling Twist Rate',
                value: state.gearSetup.firearm.riflingTwistRate ?? '',
                icon: Icons.rotate_right,
              ),
              LabelValueWidget(
                  label: 'Capacity',
                  value: state.gearSetup.firearm.capacity ?? '',
                  icon: Icons.storage),
              LabelValueWidget(
                  label: 'Finish/Color',
                  value: state.gearSetup.firearm.finishColor ?? '',
                  icon: Icons.palette),
              LabelValueWidget(
                label: 'Sight Type',
                value: state.gearSetup.firearm.sightType ?? '',
                icon: Icons.visibility,
              ),
              LabelValueWidget(
                label: 'Sight/Optic Model',
                value: state.gearSetup.firearm.sightModel ?? '',
                icon: Icons.center_focus_strong,
              ),
              LabelValueWidget(
                label: 'Sight Height Over Bore',
                value: state.gearSetup.firearm.sightHeightOverBore ?? '',
                icon: Icons.height,
              ),
              LabelValueWidget(
                label: 'Trigger Pull Weight (lbs)',
                value: state.gearSetup.firearm.triggerPullWeight ?? '',
                icon: Icons.touch_app,
              ),
              LabelValueWidget(
                label: 'Purchase Date',
                value: state.gearSetup.firearm.purchaseDate ?? '',
                icon: Icons.calendar_today,
              ),
              LabelValueWidget(
                label: 'Round Count',
                value: state.gearSetup.firearm.roundCount ?? '',
                icon: Icons.countertops,
              ),
              LabelValueWidget(
                  label: 'Modifications/Attachments',
                  value: state.gearSetup.firearm.modificationsAttachments ?? '',
                  icon: Icons.build),
            ],
            SectionHeaderWidget(
              title: 'Ammunition',
              icon: Icons.scatter_plot,
            ),
            LabelValueWidget(
              label: 'Caliber',
              value: state.gearSetup.ammoModel.caliber ?? '',
              icon: Icons.straighten,
              isImportant: true,
            ),
            LabelValueWidget(
              label: 'Bullet Type',
              value: state.gearSetup.ammoModel.bulletType ?? '',
              icon: Icons.circle,
            ),
            LabelValueWidget(
              label: 'Bullet Weight',
              value: '${state.gearSetup.ammoModel.bulletWeight ?? ''}',
              icon: Icons.scale,
            ),

            // Advanced Ammo Info (if expanded)
            if (state.gearSetup.ammoModel.advancedExpanded == true) ...[
              const ProfessionalDivider(),
              LabelValueWidget(
                label: 'Notes',
                value: state.gearSetup.ammoModel.notes ?? '',
                icon: Icons.note,
              ),
              LabelValueWidget(
                label: 'Cartridge Type',
                value: state.gearSetup.ammoModel.cartridgeType ?? '',
                icon: Icons.category,
              ),
              LabelValueWidget(
                label: 'Case Material',
                value: state.gearSetup.ammoModel.caseMaterial ?? '',
                icon: Icons.circle,
              ),
              LabelValueWidget(
                label: 'Primer Type',
                value: state.gearSetup.ammoModel.primerType ?? '',
                icon: Icons.flash_on,
              ),
              LabelValueWidget(
                label: 'Pressure Class',
                value: state.gearSetup.ammoModel.pressureClass ?? '',
                icon: Icons.compress,
              ),
              LabelValueWidget(
                label: 'Muzzle Velocity',
                value: state.gearSetup.ammoModel.muzzleVelocity ?? '',
                icon: Icons.speed,
              ),
              LabelValueWidget(
                label: 'Ballistic Coefficient (G1)',
                value: state.gearSetup.ammoModel.ballisticCoefficient ?? '',
                icon: Icons.calculate,
              ),
              LabelValueWidget(
                label: 'Sectional Density',
                value: state.gearSetup.ammoModel.sectionalDensity ?? '',
                icon: Icons.density_medium,
              ),
              LabelValueWidget(
                label: 'Recoil Energy',
                value: state.gearSetup.ammoModel.recoilEnergy ?? '',
                icon: Icons.bolt,
              ),
              LabelValueWidget(
                label: 'Powder Charge',
                value: state.gearSetup.ammoModel.powderCharge ?? '',
                icon: Icons.grain,
              ),
              LabelValueWidget(
                label: 'Powder Type',
                value: state.gearSetup.ammoModel.powderType ?? '',
                icon: Icons.scatter_plot,
              ),
              LabelValueWidget(
                label: 'Lot Number',
                value: state.gearSetup.ammoModel.lotNumber ?? '',
                icon: Icons.numbers,
              ),
              LabelValueWidget(
                label: 'Chronograph FPS',
                value: state.gearSetup.ammoModel.chronographFPS ?? '',
                icon: Icons.speed,
              ),
            ],

            // Mode Section
            SectionHeaderWidget(
              title: 'Mode',
              icon: Icons.settings,
            ),
            LabelValueWidget(
              label: 'Mode',
              value: state.gearSetup.mode ?? '',
              icon: Icons.mode,
            ),
            LabelValueWidget(
              label: 'Location',
              value: state.gearSetup.location ?? '',
              icon: Icons.location_on,
            ),
            SectionHeaderWidget(
              title: 'Sights',
              icon: Icons.visibility,
            ),
            LabelValueWidget(
              label: 'Sights',
              value: state.gearSetup.sights?.join(', ') ?? '',
              icon: Icons.center_focus_strong,
            ),
            const Divider(),
            const SizedBox(height: 15),
            CustomTextField(
                controller: controller,
                hintText: 'Weapon Profile Name',
                isRequired: true),
            EnhancedPrimaryButton(
              title: 'Save Setup',
              icon: Icons.save,
              buttonColor: AppColors.kGreenColor,
              onTap: () {
                if (!formKey.currentState!.validate()) return;
                context.read<GearSetupBloc>().add(
                      AddFirearmSetup(
                          state.gearSetup.copyWith(name: controller.text)),
                    );
                context.read<GearSetupBloc>().add(GearSetupReset());
                context
                    .read<GearSetupBloc>()
                    .add(GearSetupPresetSelected(-2, state.gearSetup));
                Navigator.pop(context);
              },
            ),
          ],
        ));
  }
}
