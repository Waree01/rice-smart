import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Shared bottom navigation for the admin section (screens 7–11).
///
/// Tapping a destination replaces the current admin location so the back
/// stack doesn't grow while moving between admin tabs.
class AdminBottomNav extends StatelessWidget {
  /// 0 dashboard · 1 review · 2 labeling · 3 map · 4 users
  final int current;
  const AdminBottomNav({super.key, required this.current});

  static const _routes = [
    '/admin',
    '/admin/review',
    '/admin/labeling',
    '/admin/map',
    '/admin/users',
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: current,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.adminPrimary,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      onTap: (i) {
        if (i == current) return;
        context.go(_routes[i]);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'แดชบอร์ด',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inbox_outlined),
          label: 'คิว',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.label_outline),
          label: 'ติดป้าย',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'แผนที่',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'ผู้ใช้',
        ),
      ],
    );
  }
}
