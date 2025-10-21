import 'package:flutter/material.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';

import '../theme/app_text_styles.dart';
import '../widgets/bottom_sheet_.dart';
import 'constants.dart';

Future<DateTime?> selectDate(
  BuildContext context,
  TextEditingController controller,
  DateTime? initialDate, {
  bool? disableFutureDates,
  TextEditingController? controllerCalculated,
}) async {
  DateTime initialPickedDate = initialDate ?? DateTime.now();

  ValueNotifier<DateTime> valueListenable =
      ValueNotifier<DateTime>(initialPickedDate);

  var pickedDate = DateTime.now();
  await showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ValueListenableBuilder<DateTime>(
      valueListenable: valueListenable,
      builder: (context, value, child) {
        return AppBottomSheetWidget(
          hideInitials: true,
          height: 0.5,
          title: 'Select Date',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ScrollDatePicker(
                    selectedDate: valueListenable.value,
                    minimumDate: DateTime(DateTime.now().year - 20,
                        DateTime.now().month, DateTime.now().day),
                    maximumDate: disableFutureDates == true
                        ? DateTime.now()
                        : DateTime(3040),
                    locale: const Locale('en'),
                    onDateTimeChanged: (DateTime value) {
                      valueListenable.value = value;
                      pickedDate = value;
                    },
                    scrollViewOptions: DatePickerScrollViewOptions(
                        month: ScrollViewDetailOptions(
                            textStyle: poppinsStyle(),
                            selectedTextStyle:
                                poppinsStyle(fontWeight: FontWeight.w500)),
                        day: ScrollViewDetailOptions(
                            textStyle: poppinsStyle(),
                            selectedTextStyle:
                                poppinsStyle(fontWeight: FontWeight.w500)),
                        year: ScrollViewDetailOptions(
                            textStyle: poppinsStyle(),
                            selectedTextStyle:
                                poppinsStyle(fontWeight: FontWeight.w500)),
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly),
                    options: const DatePickerOptions(
                        diameterRatio: 6, itemExtent: 40)),
              ),
            ],
          ),
        );
      },
    ),
  ).then((v) {
    print('then v $v');
  });

  String formattedDate = kDateFormat.format(pickedDate);
  controller.text = formattedDate;

  if (controllerCalculated != null) {
    final duration = DateTime.now().difference(pickedDate).inDays;
    final years = duration ~/ 365;
    final days = duration % 365;
    final months = days ~/ 30;
    final pDays = days % 30;
    controllerCalculated.text = "$years Years $months Months $pDays Days";
  }
  return pickedDate; // Return the selected date
}
