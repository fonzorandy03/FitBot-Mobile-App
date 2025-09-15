import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.asMap().entries.map((entry) {
          int index = entry.key;
          NavBarItem item = entry.value;
          return _buildNavBarItem(
            icon: item.icon,
            activeIcon: item.activeIcon,
            label: item.label,
            index: index,
            isSelected: currentIndex == index,
            onTap: () => onTap(index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? Color(0xFFE85A30) : Color(0xFF9E9E9E),
                size: 24,
              ),
            ),
            SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Color(0xFFE85A30) : Color(0xFF9E9E9E),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// Classe per definire gli elementi della navigation bar
class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// Factory per creare facilmente i NavBarItem predefiniti per FitBot
class FitBotNavItems {
  static List<NavBarItem> get defaultItems => [
        NavBarItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
        ),
        NavBarItem(
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center,
          label: 'Workout',
        ),
        NavBarItem(
          icon: Icons.restaurant_menu_outlined,
          activeIcon: Icons.restaurant_menu,
          label: 'Dieta',
        ),
        NavBarItem(
          icon: Icons.trending_up_outlined,
          activeIcon: Icons.trending_up,
          label: 'Progressi',
        ),
        NavBarItem(
          icon: Icons.play_circle_outline,
          activeIcon: Icons.play_circle,
          label: 'Video',
        ),
      ];
}

// Esempio di utilizzo in un widget Scaffold
class ExampleUsage extends StatefulWidget {
  @override
  _ExampleUsageState createState() => _ExampleUsageState();
}

class _ExampleUsageState extends State<ExampleUsage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedPage(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: FitBotNavItems.defaultItems,
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_currentIndex) {
      case 0:
        return _buildPage('Home', Icons.home, Color(0xFFE85A30));
      case 1:
        return _buildPage('Workout', Icons.fitness_center, Color(0xFFE91E63));
      case 2:
        return _buildPage('Dieta', Icons.restaurant_menu, Color(0xFF4CAF50));
      case 3:
        return _buildPage('Progressi', Icons.trending_up, Color(0xFF2196F3));
      case 4:
        return _buildPage('Video', Icons.play_circle, Color(0xFF9C27B0));
      default:
        return _buildPage('Home', Icons.home, Color(0xFFE85A30));
    }
  }

  Widget _buildPage(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F4F0), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  icon,
                  size: 60,
                  color: color,
                ),
              ),
              SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pagina $title',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget principale per testare la navigation bar
class CustomNavBarDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Bottom NavBar',
      theme: ThemeData(
        primaryColor: Color(0xFFE85A30),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ExampleUsage(),
      debugShowCheckedModeBanner: false,
    );
  }
}