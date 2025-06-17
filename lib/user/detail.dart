import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for data fetching

// Ensure ConcaveBottomClipper is defined or imported from its location
// For simplicity, I'll include it at the bottom of this file.

class DetailPage extends StatefulWidget {
  final String userId; // The userId passed from UserDashboardPage

  // Corrected constructor syntax
  const DetailPage({super.key, required this.userId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String? _username; // Nullable string to store the fetched username

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when the page initializes
  }

  // Function to load the username from Firestore
  Future<void> _loadUserData() async {
    // Check if userId is not empty before attempting to fetch
    if (widget.userId.isNotEmpty) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId) // Use the userId passed to this widget
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            // Cast data to Map<String, dynamic> and get the 'username' field
            _username = (userDoc.data() as Map<String, dynamic>)['username'] as String?;
          });
        } else {
          // If user document doesn't exist, set a default or show an error
          setState(() {
            _username = 'Pengguna Tidak Ditemukan';
          });
          debugPrint('User document for ID ${widget.userId} does not exist or has no data.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data pengguna tidak ditemukan. Silakan masuk lagi.')),
          );
        }
      } catch (e) {
        // Handle any errors during data fetching
        debugPrint('Error fetching user data: $e');
        setState(() {
          _username = 'Error Memuat Nama'; // Indicate an error occurred
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data pengguna: $e')),
        );
      }
    } else {
      // Handle case where userId is empty (should ideally not happen if passed correctly)
      debugPrint('Error: userId is empty in DetailPage.');
      setState(() {
        _username = 'ID Pengguna Kosong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipPath(
                  clipper: ConcaveBottomClipper(),
                  child: Container(
                    height: 300,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                    ),
                  ),
                ),
                // Header with location and notification icons
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 24), // Changed to white
                        Stack(
                          children: const [
                            Icon(
                              Icons.notifications_outlined, // Changed to outlined for consistency, and white
                              color: Colors.white,
                              size: 24,
                            ),
                            // You can add a notification badge here if needed
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Username title - now dynamic
                Positioned(
                  top: 80,
                  left: 20,
                  child: _username == null
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)) // Smaller loading indicator
                      : Text(
                          _username!.toUpperCase(), // Display fetched username
                          style: const TextStyle(
                            color: Colors.white, // Changed to white for better contrast
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ],
            ),
            // Content area - positioned to overlap the curved section
            Transform.translate(
              offset: const Offset(0, -120),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    // Parking History List
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Profile icon container
                          Container(
                            margin: const EdgeInsets.only(top: 20, bottom: 15),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFA500),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_parking,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // First parking entry (Hardcoded data)
                          _buildParkingEntry(
                            tanggal: '09 April 2025',
                            tempat: 'Mega Mall',
                            masuk: '14:30',
                            durasi: '1H 45 M',
                            harga: 'Rp 7000',
                            status: 'Lunas',
                          ),

                          Divider(color: Colors.grey[300], height: 1),

                          // Second parking entry (Hardcoded data)
                          _buildParkingEntry(
                            tanggal: '07 April 2025',
                            tempat: 'One Batam Mall',
                            masuk: '10:15',
                            durasi: 'Rp 12345', // This looks like a typo, should be duration not price
                            harga: 'Rp 5000',
                            status: 'Lunas',
                          ),

                          Divider(color: Colors.grey[300], height: 1),

                          // Third parking entry (Hardcoded data)
                          _buildParkingEntry(
                            tanggal: '31 Maret 2025',
                            tempat: 'Mega Mall',
                            masuk: '08:45',
                            durasi: 'Rp 12345', // This looks like a typo, should be duration not price
                            harga: 'Rp 7000',
                            status: 'Lunas',
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation (icons are still hardcoded and don't navigate)
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home, color: Colors.black, size: 28),
            Icon(Icons.chat_bubble_outline, color: Colors.black, size: 28),
            Icon(Icons.person, color: Colors.black, size: 28),
          ],
        ),
      ),
    );
  }

  // Helper method to build a single parking entry
  Widget _buildParkingEntry({
    required String tanggal,
    required String tempat,
    required String masuk,
    required String durasi,
    required String harga,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tanggal : $tanggal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            'Tempat : $tempat',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            'Masuk : $masuk',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            'Durasi : $durasi',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            'Harga : $harga',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            'Status : $status',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


class ConcaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 100);
    var controlPoint1 = Offset(size.width * 0.25, size.height + 60);
    var controlPoint2 = Offset(size.width * 0.75, size.height + 60);
    var endPoint = Offset(size.width, size.height - 100);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}