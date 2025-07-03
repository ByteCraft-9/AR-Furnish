import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ar_furnish/config/theme.dart';
import 'package:ar_furnish/routes/app_router.dart';
import 'package:ar_furnish/providers/cart_provider.dart';
import 'package:ar_furnish/providers/wishlist_provider.dart';
import 'package:ar_furnish/providers/filter_provider.dart';
import 'package:ar_furnish/providers/theme_provider.dart';
import 'package:ar_furnish/services/stripe_service.dart';
import 'package:ar_furnish/services/stable_diffusion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

  await Firebase.initializeApp();

  await StableDiffusionService.loadSavedBaseUrl();

  try {
    await StripeService.initialize();
  } catch (e) {
    print('Error initializing Stripe: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        Future.microtask(() {
          Provider.of<WishlistProvider>(context, listen: false).initialize();
        });

        return MaterialApp(
          title: 'AR Furnish',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: '/splash',
        );
      },
    );
  }
}
