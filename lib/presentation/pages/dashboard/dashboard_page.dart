import 'package:flutter/material.dart';
import 'package:focus_ai/presentation/screens/main_navigation_hub.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Eski xato berayotgan dashboard o'rniga avtomat ravishda
    // biz yaratgan yangi, mukammal va barcha funksiyalari bor navigatsiya markazini ochadi
    return const MainNavigationHub();
  }
}
