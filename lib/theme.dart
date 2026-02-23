import 'package:flutter/material.dart';

class AppColors {
  static const Color mainColor = Color(0xFFFA7F21); // Naranja
  static const Color darkBlue = Color(0xFF101230);  // Azul oscuro
  static const Color lightGray = Color(0xFFCFCFCF); // Gris claro
  static const Color darkGray = Color(0xFF686868);  // Gris oscuro
}

final ThemeData appTheme = ThemeData(
  fontFamily: 'Montserrat',
  primaryColor: AppColors.mainColor,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: AppColors.mainColor,
    secondary: AppColors.darkBlue,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.mainColor,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.darkBlue,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle( // equiv. headline1
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.darkBlue,
    ),
    displayMedium: TextStyle( // equiv. headline2
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.darkBlue,
    ),
    displaySmall: TextStyle( // equiv. headline3
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: AppColors.darkBlue,
    ),
    titleLarge: TextStyle( // equiv. headline4
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: AppColors.darkBlue,
    ),
    titleMedium: TextStyle( // equiv. headline5
      fontSize: 16,
      fontWeight: FontWeight.w300,
      color: AppColors.darkBlue,
    ),
    bodyMedium: TextStyle( // equiv. bodyText1
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.darkGray,
    ),
  ),
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.darkBlue; // Color al presionar
      }
      return AppColors.mainColor; // Color por defecto
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white; // Texto blanco cuando se presiona
      }
      return AppColors.darkBlue; // Texto azul normalmente
    }),
    textStyle: WidgetStateProperty.all<TextStyle>(
      const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    padding: WidgetStateProperty.all<EdgeInsets>(
      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    ),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  ),
);
