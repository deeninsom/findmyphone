import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/feature_grid.dart';
import 'security_page.dart';
import 'automation_page.dart';
import 'file_page.dart';
import 'tracking_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SecurityPage(),
    const AutomationPage(),
    const FilePage(),
    const TrackingPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Kuwait City, St 9, 24"),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Security',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_mode),
            label: 'Automation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}