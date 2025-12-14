import 'package:flutter/material.dart';
import '../services/supabase_notification_service.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class BottomNavBarWidget extends StatefulWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const BottomNavBarWidget({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  State<BottomNavBarWidget> createState() => _BottomNavBarWidgetState();
}

class _BottomNavBarWidgetState extends State<BottomNavBarWidget> {
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _startNotificationCountTimer();
  }

  void _startNotificationCountTimer() {
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
      final count = await SupabaseNotificationService().getUnreadCount(
        appState.currentUser!.id!,
      );
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: widget.currentIndex,
      height: 60,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      indicatorColor: Colors.transparent,
      onDestinationSelected: widget.onDestinationSelected,
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
    );
  }
}

