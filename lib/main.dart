import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_state.dart' as app_provider;
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'config/supabase_config.dart';
import 'services/interstitial_ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (only for database access, not Auth)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // Initialize Mobile Ads
  await MobileAds.instance.initialize();
  
  // Pre-load interstitial ad for better performance
  InterstitialAdService.loadAd();
  
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedAd = false;

  Future<void> _checkAndShowAd(BuildContext context) async {
    if (_hasCheckedAd) return;
    
    // Wait a bit for the app state to be ready
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    final appState = Provider.of<app_provider.AppState>(context, listen: false);
    if (appState.isLoggedIn) {
      _hasCheckedAd = true;
      // Check if we should show ad (after 4 hours, not first login)
      // First login ad is handled in app_state.dart after login/register
      final shouldShow = await InterstitialAdService.shouldShowAd(isFirstLogin: false);
      if (shouldShow && mounted) {
        // Load ad if not already loaded
        await InterstitialAdService.loadAd();
        // Wait a bit for ad to load
        await Future.delayed(const Duration(milliseconds: 1500));
        // Show ad (not first login, so isFirstLogin: false)
        if (mounted) {
          InterstitialAdService.showAdIfNeeded(isFirstLogin: false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_provider.AppState>(
      builder: (context, appState, _) {
        // Check and show ad when user is logged in (on app open or after login)
        if (appState.isLoggedIn && !_hasCheckedAd) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndShowAd(context);
          });
        } else if (!appState.isLoggedIn) {
          _hasCheckedAd = false;
        }
        
        if (appState.isLoggedIn) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
