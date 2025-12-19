import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected; // Callback when an item is tapped

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemSelected, // Call the provided callback
      type: BottomNavigationBarType.fixed, // Use fixed for more than 3 items
      selectedItemColor: Theme.of(context).primaryColor, // Highlight selected item
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Contacts', // Placeholder for another section
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings', // Placeholder for another section
        ),
        // Add more items as needed
      ],
    );
  }
}