import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_screen.dart';
import 'sf10_viewer_screen.dart';
import 'borrow_items_screen.dart';
import 'folders_screen.dart';
import 'history_items.dart';
import 'package:filesphere_sys/login_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;
  final _titles = [
    'SF10 Viewer',
    'Borrow Items',
    'Folders',
    'Search',
    'History',
  ];
  bool _isDarkMode = false;
  User? _currentUser;
  Map<String, dynamic>? _userData;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Navigation items with icons and labels
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.description, 'label': 'SF10 Viewer'},
    {'icon': Icons.shopping_cart, 'label': 'Borrow Items'},
    {'icon': Icons.folder, 'label': 'Folders'},
    {'icon': Icons.search, 'label': 'Search'},
    {'icon': Icons.history, 'label': 'History'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data()!;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginTypeScreen()),
    );
  }

  Widget get _content {
    switch (_selectedIndex) {
      case 0:
        return const SF10ViewerScreen();
      case 1:
        return const BorrowedItemsScreen();
      case 2:
        return const FoldersScreen();
      case 3:
        return const SearchAllScreen();
      case 4:
        return const HistoryScreen();
      default:
        return const FoldersScreen();
    }
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications at this time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For assistance, please contact:'),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('support@inventorysystem.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('+1 (555) 123-4567'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode
        ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueAccent.shade200,
              secondary: Colors.lightBlueAccent.shade200,
            ),
          )
        : ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueAccent.shade400,
              secondary: Colors.lightBlueAccent.shade400,
            ),
          );

    return MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text(
            _titles[_selectedIndex],
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
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: _showNotificationDialog,
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpDialog,
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
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: _content,
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _userData?['name'] ?? 'Guest',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(_currentUser?.email ?? 'No email'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
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
                            : Colors.white.withOpacity(0.7),
                      ),
                      title: Text(
                        item['label'],
                        style: TextStyle(
                          color: _selectedIndex == _navItems.indexOf(item)
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          fontWeight: _selectedIndex == _navItems.indexOf(item)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: _selectedIndex == _navItems.indexOf(item),
                      selectedTileColor: Colors.white.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedIndex = _navItems.indexOf(item);
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Divider(color: Colors.white54, height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    title: Text(
                      'Settings',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(
                      _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    title: Text(
                      _isDarkMode ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
