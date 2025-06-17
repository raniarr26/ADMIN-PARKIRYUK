import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore operations
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth logout
import 'package:sistem_parkir/login_page.dart'; // Import your LoginPage

class ProfilePage extends StatefulWidget {
  final String userId; // The userId passed from previous pages

  // Corrected constructor syntax: removed trailing semicolon and added const
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Nullable strings to store fetched user data
  String? _username;
  String? _email;
  String? _phoneNumber;
  String? _licensePlate;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when the page initializes
  }

  /// Fetches user data from Firestore using the provided userId.
  Future<void> _loadUserData() async {
    if (widget.userId.isEmpty) {
      debugPrint('Error: userId is empty in ProfilePage.');
      _showSnackBar('Gagal memuat profil: ID pengguna tidak valid.', isError: true);
      setState(() {
        _username = 'ID Pengguna Kosong';
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId) // Use the userId passed to this widget
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _username = userData['username'] as String?;
          _email = userData['email'] as String?;
          _phoneNumber = userData['phone'] as String?; // Assuming 'phone' field
          _licensePlate = userData['licensePlate'] as String?; // Assuming 'licensePlate' field
        });
      } else {
        debugPrint('User document for ID ${widget.userId} does not exist or has no data.');
        _showSnackBar('Data profil tidak ditemukan.', isError: true);
        setState(() {
          _username = 'Profil Tidak Ditemukan';
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data for profile: $e');
      _showSnackBar('Gagal memuat data profil: ${e.toString()}', isError: true);
      setState(() {
        _username = 'Error Memuat Data';
      });
    }
  }

  /// Displays a SnackBar message.
  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handles the user logout process.
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase Auth
      if (!mounted) return;
      // Navigate back to the login page and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      _showSnackBar('Gagal keluar: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with concave shape
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background gradient with deeper concave shape
                ClipPath(
                  clipper: ConcaveBottomClipper(),
                  child: Container(
                    height: 320, // Height increased for better visual balance
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFD700), // Gold
                          Color(0xFFFFA500), // Orange
                        ],
                      ),
                    ),
                  ),
                ),
                // Header with location icon (notification icon removed for simplicity as it's empty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(
                          Icons.location_on,
                          color: Colors.white, // Changed to white for consistency
                          size: 24,
                        ),
                        // Removed notification icon as there's no functionality for it here
                      ],
                    ),
                  ),
                ),
                // Username title
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
                            color: Colors.white, // Changed to white for consistency
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
                // Avatar with image
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundImage: const NetworkImage(
                          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&h=200&fit=crop&crop=face',
                        ),
                        backgroundColor: const Color(0xFF8D6E63), // Default background if image fails
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('Error loading profile image: $exception');
                          // Fallback to a default icon or color if image fails to load
                        },
                        child: _username == null // Show person icon if username is still loading or image fails
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null, // If username loaded, assume image will load or is set
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content area - positioned to overlap the curved section
            Transform.translate(
              offset: const Offset(0, -100), // Moved up further
              child: Container(
                color: Colors.transparent, // Transparent to allow background color show through
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 20), // Increased left/right padding
                child: Column(
                  children: [
                    // White container for form fields with narrower width
                    Container(
                      width: MediaQuery.of(context).size.width * 0.85, // Width reduced
                      padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormField('Username', Icons.person_outline, _username),
                          Divider(color: Colors.grey[300], height: 32),
                          _buildFormField('Email', Icons.email_outlined, _email),
                          Divider(color: Colors.grey[300], height: 32),
                          _buildFormField('Nomor Hp', Icons.phone_outlined, _phoneNumber, hasArrow: true),
                          Divider(color: Colors.grey[300], height: 32),
                          _buildFormField('No.Plat', Icons.directions_car_outlined, _licensePlate, hasArrow: true),
                          Divider(color: Colors.grey[300], height: 32),
                          // For password, we don't display the actual value, just a placeholder label
                          _buildFormField('Password', Icons.lock_outline, '********', hasArrow: true, isPassword: true),
                          Divider(color: Colors.grey[300], height: 32),
                          // Log Out Button
                          InkWell(
                            onTap: _logout, // Call the logout function
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey[400], // Red color for consistency with Log Out text
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // Add space for bottom navigation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation
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

  /// Helper widget to build a form field row for profile details.
  Widget _buildFormField(String label, IconData icon, String? value,
      {bool hasArrow = false, bool isPassword = false}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14, // Slightly smaller label
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'Loading...', 
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (hasArrow || isPassword)
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
      ],
    );
  }
}

// Custom clipper to create a deeper concave bottom shape
class ConcaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80); 
   
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 50, 
      size.width, 
      size.height - 80, 
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
