import 'package:flutter/material.dart';
import 'screens/admin_dashboard.dart';
import 'screens/user_dashboard.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final role = (args is String && (args == 'Admin' || args == 'User'))
        ? args
        : 'User';

    return role == 'Admin' ? const AdminDashboard() : const UserDashboard();
  }
}
