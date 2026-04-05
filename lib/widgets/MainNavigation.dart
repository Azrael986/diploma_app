import 'package:flutter/material.dart';
import 'package:first_app/screens/report.dart';
import 'package:first_app/screens/history.dart';  // Статус хянах/Түүх хуудас

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; // Одоо сонгогдсон байгаа хуудасны индекс

  // 1. Харуулах хуудсуудын жагсаалт
final List<Widget> _pages = [
  const ReportScreen(),
  const StatusCheckScreen(), // Энд HistoryScreen-ийг StatusCheckScreen болгож соль
  const Center(child: Text("Профайл")),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. Сонгогдсон хуудсыг дэлгэцэнд харуулна
      body: _pages[_selectedIndex],
      
      // 3. Доод навигацийн цэс
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Идэвхтэй байгаа товчлуур
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Товчлуур дээр дарахад хуудсыг солино
          });
        },
        type: BottomNavigationBarType.fixed, // Товчлуурууд тогтмол байрлалтай байна
        selectedItemColor: Colors.blue,      // Сонгогдсон үеийн өнгө
        unselectedItemColor: Colors.grey,    // Сонгогдоогүй үеийн өнгө
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: "Мэдээлэх",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: "Хянах",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Профайл",
          ),
        ],
      ),
    );
  }
}