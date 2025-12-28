import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kPrimary = Color(0xFFD32F2F); 
const kSurface = Color(0xFFF3F4F6); 

ThemeData buildTheme(Brightness brightness) {
 final base = ThemeData(
   useMaterial3: true,
   brightness: brightness,
   colorSchemeSeed: kPrimary,
   fontFamily: "ElMessiri",
 );

 final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme); 
 return base.copyWith(
   textTheme: textTheme,
   scaffoldBackgroundColor: kSurface,
   appBarTheme: const AppBarTheme(
     backgroundColor: Colors.white,
     foregroundColor: Colors.black87,
     elevation: 0,
     centerTitle: false,
   ),
   elevatedButtonTheme: ElevatedButtonThemeData(
     style: ElevatedButton.styleFrom(
       backgroundColor: kPrimary,        
       foregroundColor: Colors.white,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(14),
       ),
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
       textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
     ),
   ),
   outlinedButtonTheme: OutlinedButtonThemeData(
     style: OutlinedButton.styleFrom(
       foregroundColor: kPrimary,
       side: const BorderSide(color: kPrimary, width: 1.4),
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(14),
       ),
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
       textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
     ),
   ),
   cardTheme: const CardThemeData(
     color: Colors.white,
     elevation: 0,
     margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
     shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.all(Radius.circular(18)),
     ),
     clipBehavior: Clip.antiAlias,
   ),
   bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
     type: BottomNavigationBarType.fixed,
     backgroundColor: Colors.white,
     selectedItemColor: kPrimary,
     unselectedItemColor: Colors.black54,
     showUnselectedLabels: true,
     elevation: 8,
   ),
 );
}