import 'package:flutter/material.dart';
import 'package:ar_furnish/screens/main_screen.dart';
import 'package:ar_furnish/utils/navigation_helper.dart';

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // If this screen is displayed inside the MainScreen, don't show the bottom bar
    if (MainScreen.isInMainScreen) {
      return const SizedBox.shrink(); // Return empty widget
    }

    // Otherwise, show the normal bottom navigation bar
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        // Call original callback for state management
        onTap(index);

        // Use NavigationHelper for consistent navigation
        switch (index) {
          case 0:
            NavigationHelper.goToHome(context);
            break;
          case 1:
            NavigationHelper.goToCart(context);
            break;
          case 2:
            NavigationHelper.goToDesign(context);
            break;
          case 3:
            NavigationHelper.goToProfile(context);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(
            icon: Icon(Icons.room_preferences), label: 'Design'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
    );
  }
}
