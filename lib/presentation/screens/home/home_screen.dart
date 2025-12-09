import 'package:flutter/material.dart';
import '../input/quick_input_screen.dart';
import '../kol/kol_list_screen.dart';
import '../stocks/stock_list_screen.dart';
import '../more/more_screen.dart';

/// 主頁面 - 底部導覽容器
/// 包含4個主要Tab：快速輸入、KOL、投資標的、更多
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          QuickInputScreen(),
          KOLListScreen(),
          StockListScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: '快速輸入',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'KOL',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: '投資標的',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: '更多',
          ),
        ],
      ),
    );
  }
}
