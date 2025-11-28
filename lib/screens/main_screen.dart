import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/banner_ad_widget.dart';
import 'main_feed_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
  }

  late final List<Widget> _screens = [
    MainFeedScreen(key: _mainFeedKey),
    const AddProductScreenWrapper(),
    const NotificationsScreen(),
    const ProfileScreenWrapper(),
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
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            indicatorColor: Colors.transparent,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Reset search khi chuyển về tab Trang chủ
              if (index == 0 && _mainFeedKey.currentState != null) {
                _mainFeedKey.currentState!.resetSearch();
              }
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 24, color: Colors.black),
                selectedIcon: Icon(Icons.home, size: 24, color: Colors.orange),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline, size: 24, color: Colors.black),
                selectedIcon: Icon(Icons.add_circle, size: 24, color: Colors.orange),
                label: 'Đăng tin',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_outlined, size: 24, color: Colors.black),
                selectedIcon: Icon(Icons.notifications, size: 24, color: Colors.orange),
                label: 'Thông báo',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, size: 24, color: Colors.black),
                selectedIcon: Icon(Icons.person, size: 24, color: Colors.orange),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ],
      ),
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
        // Khi thêm sản phẩm thành công, chuyển về tab Trang chủ
        final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
        if (mainScreenState != null) {
          mainScreenState.switchToTab(0);
        }
      },
      showBannerAd: false, // Không hiển thị banner ad vì MainScreen đã có
    );
  }
}

class ProfileScreenWrapper extends StatelessWidget {
  const ProfileScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.currentUser != null) {
          return ProfileScreen(
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
