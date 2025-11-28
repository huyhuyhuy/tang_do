import 'package:flutter/material.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const BottomNavBarWidget({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 60,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: Colors.transparent,
      onDestinationSelected: onDestinationSelected,
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
    );
  }
}

