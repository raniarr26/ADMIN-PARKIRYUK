import 'package:flutter/material.dart';

class BerandaPage extends StatelessWidget {
  final String userId;

  const BerandaPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(),
          
          const SizedBox(height: 32),
          
          // Statistics Cards Row
          _buildStatisticsSection(),
          
          const SizedBox(height: 32),

          // Quick Actions Grid
          Expanded(
            child: _buildManagementMenu(isWideScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.admin_panel_settings,
            size: 80,
            color: Color(0xFFFFA726),
          ),
          const SizedBox(height: 16),
          const Text(
            'Selamat Datang, Admin!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'User ID: $userId',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kelola sistem parkir Anda dengan mudah dan efisien melalui dashboard admin ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Parkir',
            '8',
            Icons.local_parking,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Tersedia',
            '8',
            Icons.check_circle,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Terisi',
            '0',
            Icons.car_rental,
            const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementMenu(bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Manajemen',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: isWideScreen ? 4 : 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2,
            children: [
              _buildAdminMenuItem(
                icon: Icons.people,
                title: 'Kelola Pengguna',
                description: 'Manajemen user dan akses',
                color: const Color(0xFF9C27B0),
                onTap: () => _showFeatureComingSoon('Kelola Pengguna'),
              ),
              _buildAdminMenuItem(
                icon: Icons.local_parking,
                title: 'Kelola Parkir',
                description: 'Atur zona dan kapasitas',
                color: const Color(0xFF2196F3),
                onTap: () {
                  // Navigate to monitoring page
                  // This can be handled by parent widget
                },
              ),
              _buildAdminMenuItem(
                icon: Icons.attach_money,
                title: 'Laporan Keuangan',
                description: 'Statistik pendapatan',
                color: const Color(0xFF4CAF50),
                onTap: () => _showFeatureComingSoon('Laporan Keuangan'),
              ),
              _buildAdminMenuItem(
                icon: Icons.settings,
                title: 'Pengaturan Sistem',
                description: 'Konfigurasi aplikasi',
                color: const Color(0xFF607D8B),
                onTap: () => _showFeatureComingSoon('Pengaturan Sistem'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMenuItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeatureComingSoon(String featureName) {
    // This should be handled by parent widget or using a callback
    print('$featureName akan segera hadir!');
  }
}