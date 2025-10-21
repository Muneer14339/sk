import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

TextStyle poppinsStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
}) {
  return GoogleFonts.poppins(
      textStyle: TextStyle(
          height: height ?? 1.2,
          fontWeight: fontWeight,
          fontFamily: GoogleFonts.poppins().fontFamily,
          color: color ?? AppColors.black,
          fontSize: fontSize));
}

TextStyle bottomSheetTitle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
}) {
  return GoogleFonts.poppins(
      textStyle: TextStyle(
          height: height ?? 1.2,
          fontWeight: fontWeight ?? FontWeight.w600,
          fontFamily: GoogleFonts.poppins().fontFamily,
          color: color ?? AppColors.black,
          fontSize: fontSize));
}
