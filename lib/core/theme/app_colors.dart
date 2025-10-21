import 'package:flutter/material.dart';

class AppColors {
  // Palette constants
  static Color kPrimaryTeal = Color(0xFF00CED1);
  static Color kBackground = Color(0xFF121212);
  static Color kSurface = Color(0xFF1E1E1E);
  static Color kSuccess = Color(0xFF4CAF50);
  static Color kError = Color(0xFFFF5252);
  static Color kTextPrimary = Color(0xFFFFFFFF);
  static Color kTextSecondary = Color(0xFFB0B0B0);
//test_home
// static Color whiteColor = Colors.white;
  static Color black = Colors.black;
  static Color kRedColor = Colors.red;
  static Color cancelText = HexColor('#DE0C00');
  static Color kPrimaryColor = HexColor('#FF0F1830');
  static Color kSecondaryColor = HexColor('#0B1220');
  static Color kTertiaryColor = HexColor('#535C91');
  static Color kQuaternaryColor = HexColor('#9290C3');
  static Color scaffoldBackgroundColor = kSecondaryColor;

  static Color deepOrange = HexColor('#FE6B40');
  static Color greyTextColor = HexColor('#7C7C7C');
  static Color blackTextColor = HexColor('#101010');
  static Color borderOutline = HexColor('#EEEEEE');
  static Color dividerColor = HexColor('#000000').withValues(alpha: .1);
  static Color greyColor = Colors.grey;
  static Color greenColor = HexColor('#0DB30D');
  static Color greyTextfieldBack = HexColor('#F1EFEE');
  static Color profileTilesBack = HexColor('#F2F5F8');
  static Color switchColor = HexColor('#6F9C3D');
  static Color countBaseColor = HexColor('#F2F5F8');
  static Color timeClearColor = HexColor('#FF0000');
  static Color sliderDotsColor = HexColor('#D9D9D9');

  //
  static Color white = HexColor('FFFFFF');
  static Color kGreenColor = HexColor('#0DB30D');
  static const secondary = Color(0xff323335);
  static const lightGray = Color(0xffc0c1c3);
  static const lighterGray = Color(0xffe0e0e0);
  // static const black = Colors.black; const Color(0xff2c3e50)
  static const primary = Color(0xfffdc912);
  static const tertiary = Color(0xfff36b6b);

  static Color kDarkPrimary = HexColor("#000000");
  static Color kDarkTextColor = HexColor("#FFFFFF");

  static Color bacgroundPaintColorDark = HexColor("#101010");
  static Color bacgroundPaintShadowDark = HexColor("#24242480");
  static Color bacgroundPaintColorLight = countBaseColor;
  static Color bacgroundPaintShadowLight = Colors.grey.shade100;

  static Color creamColor = const Color(0xfff5f5ff);
  static Color rawSienna = const Color(0xffd7834f);

  static Color kLightPrimary = HexColor("#FF8B03");
  static Color kLightTextColor = HexColor("#000000");

  static Color kButtonColor = const Color.fromRGBO(233, 186, 69, 1);
  static Color kIconColorLight = black;
  static Color kIconColorDark = white;

  static Color FDFCFB = HexColor("#FDFCFB");
  static Color iconCountColor = HexColor("#D9D9D9");
  // static Color dividerColor = HexColor("#EFEFEF");
  static Color dividerColorDark = Colors.black26;
  static Color greyText = HexColor("#4B4B4B");
  static Color termsColor = HexColor("#0720FB");
  static Color switchBackGround = HexColor("#E4DFDF");
  static Color paymentTextColor = HexColor("#747474CC");
  static Color onSwitch = HexColor("#67D142");
  static Color uploadColor = HexColor("#34210E");
  static Color notificationSwitch = const Color(0xFFF3ECEC);
  static Color offSwitch = const Color(0xFFDF6363);
  static Color chatColor = const Color(0xFFF5F6FA);
  static Color searchHintColor = HexColor("#00B8C6");
  static Color golden = const Color.fromRGBO(233, 186, 69, 1);

  // static Color countBaseColor = HexColor('#F2F5F8');
  // static Color whiteColor = Colors.white;

  static Color transparent = Colors.transparent;
  static Color appYellow = HexColor('FFD600');
  // static Color orange = HexColor('FE6B40');
  static Color gry = HexColor('7C7C7C');
  static Color bg_gry = HexColor('#242424');
  // static Color bg_gry = HexColor('414141');

  //
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }

    final hexNum = int.parse(hexColor, radix: 16);

    if (hexNum == 0) {
      return 0xff000000;
    }

    return hexNum;
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}
