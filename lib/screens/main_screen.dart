import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/supabase_notification_service.dart';
import 'main_feed_screen.dart';
import 'contacts_screen.dart';
import 'add_product_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int? initialTab;
  
  const MainScreen({super.key, this.initialTab});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class MainScreenWithTab extends MainScreen {
  final int initialTab;
  
  const MainScreenWithTab({super.key, required this.initialTab}) : super(initialTab: initialTab);
  
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final GlobalKey<MainFeedScreenState> _mainFeedKey = GlobalKey<MainFeedScreenState>();
  final GlobalKey<ProfileScreenWrapperState> _profileScreenKey = GlobalKey<ProfileScreenWrapperState>();
  final SupabaseNotificationService _notificationService = SupabaseNotificationService();
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
    _loadNotificationCount();
    // Refresh notification count periodically
    _startNotificationCountTimer();
  }

  void _startNotificationCountTimer() {
    // Refresh every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadNotificationCount();
        _startNotificationCountTimer();
      }
    });
  }

  Future<void> _loadNotificationCount() async {
    final appState = context.read<AppState>();
    if (appState.currentUser != null && mounted) {
      final count = await _notificationService.getUnreadCount(
        appState.currentUser!.id!,
      );
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    }
  }

  void refreshNotificationCount() {
    _loadNotificationCount();
  }

  late final List<Widget> _screens = [
    MainFeedScreen(key: _mainFeedKey),
    const ContactsScreen(),
    const AddProductScreenWrapper(),
    NotificationsScreen(onNotificationRead: refreshNotificationCount),
    ProfileScreenWrapper(key: _profileScreenKey),
  ];

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BannerAdWidget(),
          NavigationBar(
            selectedIndex: _currentIndex,
            height: 60,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            indicatorColor: Colors.transparent,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Reset search khi chuyển về tab Trang chủ
              if (index == 0 && _mainFeedKey.currentState != null) {
                _mainFeedKey.currentState!.resetSearch();
              }
              // Refresh profile screen khi chuyển về tab Hồ sơ
              if (index == 4 && _profileScreenKey.currentState != null) {
                _profileScreenKey.currentState!.refreshProfile();
              }
              // Refresh notification count khi chuyển về tab Thông báo
              if (index == 3) {
                _loadNotificationCount();
              }
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 24, color: Colors.black),
                selectedIcon: Icon(Icons.home, size: 24, color: Colors.orange),
                label: '',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outlined, size: 24, color: Colors.black),
                selectedIcon: Icon(Icons.people, size: 24, color: Colors.orange),
                label: '',
              ),
              NavigationDestination(
                icon: Image.asset('assets/icons/app_icon.png', width: 43, height: 43),
                selectedIcon: Image.asset('assets/icons/app_icon.png', width: 43, height: 43),
                label: '',
              ),
              NavigationDestination(
                icon: _buildNotificationIcon(Icons.notifications_outlined, Colors.black),
                selectedIcon: _buildNotificationIcon(Icons.notifications, Colors.orange),
                label: '',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, size: 24, color: Colors.black),
                selectedIcon: Icon(Icons.person, size: 24, color: Colors.orange),
                label: '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(IconData iconData, Color iconColor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData, size: 24, color: iconColor),
        if (_unreadNotificationCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class AddProductScreenWrapper extends StatefulWidget {
  const AddProductScreenWrapper({super.key});

  @override
  State<AddProductScreenWrapper> createState() => _AddProductScreenWrapperState();
}

class _AddProductScreenWrapperState extends State<AddProductScreenWrapper> {
  @override
  Widget build(BuildContext context) {
    return AddProductScreen(
      onProductAdded: () {
        // Khi thêm sản phẩm thành công, chuyển về tab Trang chủ và reload
        final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
        if (mainScreenState != null) {
          mainScreenState.switchToTab(0);
          // Reload products after switching to home tab
          Future.delayed(const Duration(milliseconds: 300), () {
            mainScreenState._mainFeedKey.currentState?.refreshProducts();
          });
        }
      },
      showBannerAd: false, // Không hiển thị banner ad vì MainScreen đã có
    );
  }
}

class ProfileScreenWrapper extends StatefulWidget {
  const ProfileScreenWrapper({super.key});

  @override
  State<ProfileScreenWrapper> createState() => ProfileScreenWrapperState();
}

class ProfileScreenWrapperState extends State<ProfileScreenWrapper> {
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  void refreshProfile() {
    _profileKey.currentState?.refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.currentUser != null) {
          return ProfileScreen(
            key: _profileKey,
            userId: appState.currentUser!.id!,
            showBottomNavBar: false, // Không hiển thị bottom nav bar vì MainScreen đã có
          );
        }
        return const Scaffold(
          body: Center(
            child: Text('Vui lòng đăng nhập'),
          ),
        );
      },
    );
  }

}
