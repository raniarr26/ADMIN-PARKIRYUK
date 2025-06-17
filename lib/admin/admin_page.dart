import 'package:flutter/material.dart';
import 'package:sistem_parkir/admin/monitoring.dart';
import '../login_page.dart';
import 'beranda_page.dart';

import 'tambah_gate.dart';

class AdminDashboard extends StatefulWidget {
  final String userId;

  const AdminDashboard({super.key, required this.userId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // The sidebar with fixed height
          _buildSidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: _getSelectedPage(),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFFFA726),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_parking,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Parkiryuk!!',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              const Text(
                'Admin 1',
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.grey, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 120,
      height: double.infinity, // Make sidebar fill full height
      color: const Color(0xFFFFA726),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSidebarItem(icon: Icons.home, label: 'Beranda', index: 0),
          _buildSidebarItem(
            icon: Icons.local_parking,
            label: 'Monitoring',
            index: 1,
          ),
          _buildSidebarItem(
            icon: Icons.add,
            label: 'Tambah Parkir',
            index: 2,
          ),
          const Spacer(), // Push logout button to bottom
          _buildSidebarItem(
            icon: Icons.logout,
            label: 'Log Out',
            index: 3,
            onTap: () {
              // Navigates to the LoginPage and replaces the current route
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: onTap ??
          () {
            // Update the selected index when an item is tapped
            setState(() {
              selectedIndex = index;
            });
          },
      child: Container(
        width: double.infinity, 
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8F00) : Colors.transparent, // Highlight selected item
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center icon and text vertically
          children: [
            Icon(icon, color: Colors.white, size: 24), // Display the icon
            const SizedBox(height: 4), // Small space between icon and text
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center, // Center the text if it wraps
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return BerandaPage(userId: widget.userId);
      case 1:
        return const MonitoringPage();
      case 2:
        return ParkingManagementPage();
      default:
        return BerandaPage(userId: widget.userId);
    }
  }
}