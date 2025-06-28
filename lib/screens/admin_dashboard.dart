import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registered_users_screen.dart';
import 'sf10_manager_screen.dart';
import 'admin_folder.dart';
import 'borrowed_items_screen.dart';
import 'package:filesphere_sys/admin_login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.inventory,
      'label': 'Inventory',
      'screen': SF10ViewerScreen(),
    },
    {
      'icon': Icons.handshake,
      'label': 'Borrowed Items',
      'screen': SimpleBorrowedItemsScreen(),
    },
    {'icon': Icons.folder, 'label': 'Folders', 'screen': UsersFoldersScreen()},
    {'icon': Icons.people, 'label': 'Users', 'screen': RegisteredUsersScreen()},
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('New user registered'),
              subtitle: Text('2 minutes ago'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Overdue items'),
              subtitle: Text('5 items overdue'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: Colors.red.shade800,
                secondary: Colors.deepOrange.shade200,
                surface: Colors.grey.shade900,
              ),
            )
          : ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.red.shade600,
                secondary: Colors.deepOrange.shade200,
              ),
            ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text(
            _navItems[_selectedIndex]['label'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Colors.deepPurple.shade800,
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Badge(
                label: Text('3'),
                child: Icon(Icons.notifications),
              ),
              onPressed: _showNotifications,
            ),
            IconButton(
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 18),
              ),
              onPressed: () {
                // Show profile dialog
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Colors.deepPurple.shade900.withOpacity(0.05),
              ],
            ),
          ),
          child: _navItems[_selectedIndex]['screen'],
        ),
        floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
            ? FloatingActionButton(
                onPressed: () {
                  // Add new item functionality
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.9),
              Colors.deepPurple.shade800.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    Colors.deepPurple.shade800,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 32,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Admin Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ..._navItems.map(
                    (item) => ListTile(
                      leading: Icon(
                        item['icon'],
                        color: _selectedIndex == _navItems.indexOf(item)
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                      ),
                      title: Text(
                        item['label'],
                        style: TextStyle(
                          color: _selectedIndex == _navItems.indexOf(item)
                              ? Colors.white
                              : Colors.white.withOpacity(0.8),
                          fontWeight: _selectedIndex == _navItems.indexOf(item)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: _selectedIndex == _navItems.indexOf(item),
                      selectedTileColor: Colors.black.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedIndex = _navItems.indexOf(item);
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Divider(color: Colors.white30),
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    title: Text(
                      'Settings',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    onTap: () {
                      // Navigate to settings
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    title: Text(
                      _isDarkMode ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    onTap: _toggleTheme,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.primary,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.6),
      items: _navItems
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['label'],
            ),
          )
          .toList(),
    );
  }
}
