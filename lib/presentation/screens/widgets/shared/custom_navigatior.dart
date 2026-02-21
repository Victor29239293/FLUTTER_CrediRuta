  import 'package:flutter/material.dart';
  import 'package:go_router/go_router.dart';

  class CustomBottomNavigationbar extends StatelessWidget {
    final int currentIndex;

    const CustomBottomNavigationbar({super.key, required this.currentIndex});

    void onItemTapped(BuildContext context, int index) {
      switch (index) {
        case 0:
          context.go('/home/0');
          break;
        case 1:
          context.go('/home/1');
          break;
        case 2:
          context.go('/home/2');
          break;
      }
    }

    @override
    Widget build(BuildContext context) {
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => onItemTapped(context, index),
        elevation: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Recintos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Rutas',
          ),
        ],
      );
    }
  }
