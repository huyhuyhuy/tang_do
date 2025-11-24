import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'providers/app_state.dart' as app_provider;
import 'screens/login_screen.dart';
import 'screens/main_feed_screen.dart';
import 'services/seed_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mobile Ads
  await MobileAds.instance.initialize();
  
  // Seed sample data for testing
  final seedService = SeedService();
  await seedService.seedData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => app_provider.AppState(),
      child: MaterialApp(
        title: 'Tặng đồ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_provider.AppState>(
      builder: (context, appState, _) {
        if (appState.isLoggedIn) {
          return const MainFeedScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
