import 'package:flutter/material.dart';
import 'package:ar_furnish/screens/home/home_screen.dart';
import 'package:ar_furnish/screens/cart/cart_screen.dart';
import 'package:ar_furnish/screens/interior_design/interior_design.dart';
import 'package:ar_furnish/screens/profile/profile_screen.dart';

const Color primaryColor = Color(0xFF854836);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  // Static flag to let other screens know they're inside MainScreen
  static bool isInMainScreen = false;

  // Static reference to current state
  static _MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenState>();
  }

  // Method to navigate to a specific tab
  static void navigateTo(BuildContext context, int index) {
    final state = of(context);
    if (state != null) {
      state._onTabTapped(index);
    } else {
      // If not in MainScreen, navigate to MainScreen and set initial index
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
        arguments: index,
      );
    }
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;

  // Keep instances of all screens in memory
  final List<Widget> _screens = [
    const HomeScreenImproved(key: PageStorageKey('home')),
    const CartScreen(key: PageStorageKey('cart')),
    const InteriorDesignScreen(key: PageStorageKey('design')),
    ProfileScreen(
      key: const PageStorageKey('profile'),
      onLogout: () {
        // This will be overridden in the actual ProfileScreen
      },
    ),
  ];

  // Create a bucket to preserve scroll positions and form field values
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    // Set flag to true when MainScreen is active
    MainScreen.isInMainScreen = true;

    // Check if we have an initial index from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args < 4) {
        _onTabTapped(args);
      }
    });
  }

  @override
  void dispose() {
    // Reset flag when MainScreen is disposed
    MainScreen.isInMainScreen = false;
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // User tapped the current tab again - optional: scroll to top or refresh the current tab
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(
                icon: Icon(Icons.room_preferences), label: 'Design'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedItemColor: primaryColor,
          unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Keep alive even when not visible
}
