import 'package:ar_furnish/screens/checkout/checkout_screen.dart';
import 'package:ar_furnish/screens/forgot%20password/forgotPassword.dart';
import 'package:ar_furnish/screens/furniture_list_screen.dart';
import 'package:ar_furnish/screens/orders/orders_screen.dart';
import 'package:ar_furnish/screens/profile/profile_screen.dart';
import 'package:ar_furnish/screens/settings/notify_setting.dart';
import 'package:ar_furnish/screens/settings/settings_screen.dart';
import 'package:ar_furnish/screens/settings/language_screen.dart';
import 'package:ar_furnish/screens/settings/faq_screen.dart';
import 'package:ar_furnish/screens/settings/terms_screen.dart';
import 'package:ar_furnish/screens/settings/privacy_screen.dart';
import 'package:ar_furnish/screens/settings/support_screen.dart';
import 'package:ar_furnish/screens/wishlist/wishlist_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ar_furnish/screens/auth/sign_in_screen.dart';
import 'package:ar_furnish/screens/auth/sign_up_screen.dart';
import 'package:ar_furnish/screens/cart/cart_screen.dart';
import 'package:ar_furnish/screens/product/product_details_screen.dart';
import 'package:ar_furnish/screens/search/search_results_screen.dart';
import 'package:ar_furnish/models/product.dart';
import 'package:ar_furnish/screens/interior_design/interior_design.dart';
import 'package:ar_furnish/screens/interior_design/saved_designs_screen.dart';
import 'package:ar_furnish/screens/profile/address.dart';
import 'package:ar_furnish/screens/profile/payment_method.dart';
import 'package:ar_furnish/screens/settings/theme_settings_screen.dart';
import 'package:ar_furnish/screens/settings/edit_profile.dart';
import 'package:ar_furnish/screens/splash/splash_screen.dart';
import 'package:ar_furnish/screens/main_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        // If arguments contains an index, pass it to MainScreen
        final index = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: RouteSettings(arguments: index),
        );
      case '/sign-in':
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case '/sign-up':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/settings/language':
        return MaterialPageRoute(builder: (_) => const LanguageScreen());
      case '/settings/faq':
        return MaterialPageRoute(builder: (_) => const FAQScreen());
      case '/settings/terms':
        return MaterialPageRoute(builder: (_) => const TermsScreen());
      case '/settings/privacy':
        return MaterialPageRoute(builder: (_) => const PrivacyScreen());
      case '/settings/support':
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      case '/checkout':
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case '/wishlist':
        return MaterialPageRoute(builder: (_) => const WishlistScreen());
      case '/orders':
        return MaterialPageRoute(builder: (_) => OrdersScreen());
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            onLogout: () {
              // Handle logout logic here, e.g., clearing user session or token
              FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  _, '/sign-in', (route) => false);
            },
          ),
        );
      case '/cart':
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case '/product':
        final product = settings.arguments as Product;
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        );
      case '/search':
        final query = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SearchResultsScreen(initialQuery: query ?? ''),
        );
      case '/furniture':
        return MaterialPageRoute(
          builder: (_) =>
              FurnitureListScreen(category: settings.arguments as String),
        );
      case '/interior-design':
        return MaterialPageRoute(builder: (_) => const InteriorDesignScreen());
      case '/saved-designs':
        return MaterialPageRoute(builder: (_) => const SavedDesignsScreen());
      case '/address':
        return MaterialPageRoute(builder: (_) => const AddressScreen());
      case '/themeSetting':
        return MaterialPageRoute(builder: (_) => const ThemeSettingsScreen());
      case '/payment-method':
        return MaterialPageRoute(builder: (_) => const PaymentMethodScreen());
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case '/notifications':
        return MaterialPageRoute(
            builder: (_) => const NotificationSettingsScreen());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
