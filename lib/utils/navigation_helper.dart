import 'package:flutter/material.dart';
import 'package:ar_furnish/screens/main_screen.dart';

/// Helper class for app navigation
class NavigationHelper {
  /// Tab indices for main navigation
  static const int homeTab = 0;
  static const int cartTab = 1;
  static const int designTab = 2;
  static const int profileTab = 3;

  /// Navigate to Home tab
  static void goToHome(BuildContext context) {
    MainScreen.navigateTo(context, homeTab);
  }

  /// Navigate to Cart tab
  static void goToCart(BuildContext context) {
    MainScreen.navigateTo(context, cartTab);
  }

  /// Navigate to Design tab
  static void goToDesign(BuildContext context) {
    MainScreen.navigateTo(context, designTab);
  }

  /// Navigate to Profile tab
  static void goToProfile(BuildContext context) {
    MainScreen.navigateTo(context, profileTab);
  }

  /// Go back to previous screen safely
  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      goToHome(context);
    }
  }

  /// For screens that need to check if they should show a bottom bar
  static bool shouldShowBottomBar(BuildContext context) {
    // If we're in the MainScreen, we shouldn't show another bottom bar
    if (MainScreen.isInMainScreen) {
      return false;
    }

    // If this is one of the primary screens accessed directly (not through MainScreen)
    // we should show the bottom bar
    return true;
  }

  /// Method to help migrate to the new navigation system
  static void migrateToMainScreen(BuildContext context, int tabIndex) {
    // For screens navigating to main tabs, use this method instead of direct navigation
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
      arguments: tabIndex,
    );
  }
}
