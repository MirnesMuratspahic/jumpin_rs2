import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'requests_screen.dart';
import 'profile_screen.dart';
import 'support_screen.dart';

class MainScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const MainScreen({super.key, required this.authProvider});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const Color _primaryColor = Color(0xFF1565C0);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(authProvider: widget.authProvider),
      RequestsScreen(authProvider: widget.authProvider),
      ProfileScreen(authProvider: widget.authProvider),
      SupportScreen(authProvider: widget.authProvider),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}
