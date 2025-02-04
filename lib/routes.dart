import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shibuya_app/src/screens/events/calendar_screen.dart';
import 'package:shibuya_app/src/screens/home.dart';
import 'package:shibuya_app/src/screens/mayPage/mypage.dart';
import 'package:shibuya_app/src/screens/post_view.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PostViewPage(onWantToGoPressed: (File photo) { },),
    const HomeScreen(),
    const MyCalendarPage(),
    const MyPageScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        selectedItemColor: Colors.blue, // 選択されたアイテムの色
        unselectedItemColor: Colors.grey, // 選択されていないアイテムの色
        backgroundColor: Colors.white, // 背景色
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'event',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'mypage',
          ),
        ],
      ),
    );
  }
}