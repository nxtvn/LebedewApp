import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// HomePage Widget zur plattformspezifischen Darstellung der Hauptseite
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Widget> _pages = [
    const Center(child: Text('Lebedew Startseite')),
    const Center(child: Text('Suche')),
    const Center(child: Text('Profil')),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoHomePage() : _buildMaterialHomePage();
  }

  /// Cupertino HomePage für iOS
  Widget _buildCupertinoHomePage() {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Start'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Suche'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profil'),
        ],
      ),
      tabBuilder: (context, index) => CupertinoTabView(builder: (context) => _pages[index]),
    );
  }

  /// Material HomePage für Android
  Widget _buildMaterialHomePage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Lebedew App')),
      body: FadeTransition(
        opacity: _controller,
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Start'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Suche'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 