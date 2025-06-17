import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'memilih_bokingan_parkir.dart';
import 'pindai_masuk_parkiran.dart';
import 'package:sistem_parkir/login_page.dart';
import 'profile.dart';

class UserDashboardPage extends StatefulWidget {
  final String userId;
  const UserDashboardPage({super.key, required this.userId});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  String? _username;
  bool _isParkingActive = false; 
  bool _isLoadingParkingStatus = true;
  String _parkingLocation = ''; 
  int _selectedIndex = 0; 

  // Remove the late final declaration
  List<Widget>? _pages;

  @override
  void initState() {
    super.initState();
    // Don't initialize _pages here - do it in didChangeDependencies or make it lazy
    _loadUserData();
    _checkParkingStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize _pages here where context is fully available
    if (_pages == null) {
      _pages = [
        _buildDashboardContent(), 
        const Center(child: Text('Chat Page Placeholder')),
        ProfilePage(userId: widget.userId), 
      ];
    }
  }

  // Alternative approach: Make _pages a getter (lazy initialization)
  List<Widget> get pages {
    return [
      _buildDashboardContent(), 
      const Center(child: Text('Chat Page Placeholder')),
      ProfilePage(userId: widget.userId), 
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadUserData() async {
    if (widget.userId.isNotEmpty) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            _username =
                (userDoc.data() as Map<String, dynamic>)['username'] as String?;
          });
        } else {
          print(
              'User document for ID ${widget.userId} does not exist or has no data.');
          setState(() {
            _username = 'Pengguna Tidak Ditemukan';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User data not found. Please log in again.')),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _username = 'Error Memuat Data';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data pengguna: $e')),
        );
      }
    } else {
      print('User ID is empty. Redirecting to login.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    }
  }

  Future<void> _checkParkingStatus() async {
    try {
      setState(() {
        _isLoadingParkingStatus = true;
      });

      QuerySnapshot parkirQuery = await FirebaseFirestore.instance
          .collection('parkir')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (parkirQuery.docs.isNotEmpty) {
        DocumentSnapshot parkirDoc = parkirQuery.docs.first;
        Map<String, dynamic> parkirData =
            parkirDoc.data() as Map<String, dynamic>;

        setState(() {
          _isParkingActive = true;
          _parkingLocation =
              parkirData['location'] ?? parkirData['parkingSpot'] ?? 'Lokasi Tidak Diketahui';
          _isLoadingParkingStatus = false;
        });
        return;
      }

      QuerySnapshot bookingQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: widget.userId)
          .where('status', whereIn: ['active', 'confirmed', 'ongoing'])
          .limit(1)
          .get();

      if (bookingQuery.docs.isNotEmpty) {
        DocumentSnapshot bookingDoc = bookingQuery.docs.first;
        Map<String, dynamic> bookingData =
            bookingDoc.data() as Map<String, dynamic>;

        setState(() {
          _isParkingActive = true;
          _parkingLocation =
              bookingData['location'] ?? bookingData['parkingSpot'] ?? 'Booking Aktif';
          _isLoadingParkingStatus = false;
        });
        return;
      }

      setState(() {
        _isParkingActive = false;
        _parkingLocation = '';
        _isLoadingParkingStatus = false;
      });
    } catch (e) {
      print('Error checking parking status: $e');
      setState(() {
        _isParkingActive = false;
        _parkingLocation = '';
        _isLoadingParkingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat status parkir: $e')),
      );
    }
  }

  Future<void> _refreshParkingStatus() async {
    await _checkParkingStatus();
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _refreshParkingStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        colors: [
                          Color(0xFFFFD700), // Gold
                          Color(0xFFFFA500), // Orange
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                        Stack(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 20,
                  child: _username == null
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _username!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -120),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                child: Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(25),
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
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 100,
                              minHeight: 100,
                              maxWidth: 200,
                              maxHeight: 200,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isParkingActive
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFFA500),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: _isParkingActive
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFFA500),
                                    child: Icon(
                                      _isParkingActive
                                          ? Icons.local_parking
                                          : Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Text(
                                  'Anda Sedang',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _isLoadingParkingStatus
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text(
                                        _isParkingActive ? 'Parkir' : 'Tidak Parkir',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: _isParkingActive
                                              ? const Color(0xFF4CAF50)
                                              : Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                const SizedBox(height: 8),
                                if (_isParkingActive && _parkingLocation.isNotEmpty)
                                  Text(
                                    'Lokasi: $_parkingLocation',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: _isParkingActive
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFFA500),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (!_isParkingActive)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => PindaiMasukParkiranPage(
                                            userId: widget.userId)),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'Pindai Untuk Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          if (!_isParkingActive) const SizedBox(height: 15),
                          if (!_isParkingActive)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            BokingParkirPage(userId: widget.userId)),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'Booking Tempat Parkir',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          if (_isParkingActive)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showFinishParkingDialog();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFf44336),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'Selesai Parkir',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: IndexedStack(
        index: _selectedIndex,
        // Use the getter instead of the _pages variable
        children: pages,
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 28),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishParkingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selesai Parkir'),
          content: const Text('Apakah Anda yakin ingin menyelesaikan sesi parkir?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _finishParking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf44336),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Selesai'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _finishParking() async {
    try {
      QuerySnapshot parkirQuery = await FirebaseFirestore.instance
          .collection('parkir')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'active')
          .get();

      for (DocumentSnapshot doc in parkirQuery.docs) {
        await doc.reference.update({
          'status': 'completed',
          'exitTime': FieldValue.serverTimestamp(),
        });
      }

      QuerySnapshot bookingQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: widget.userId)
          .where('status', whereIn: ['active', 'confirmed', 'ongoing'])
          .get();

      for (DocumentSnapshot doc in bookingQuery.docs) {
        await doc.reference.update({
          'status': 'completed',
          'exitTime': FieldValue.serverTimestamp(),
        });
      }

      await _checkParkingStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi parkir telah selesai'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      print('Error finishing parking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyelesaikan parkir: $e'),
          backgroundColor: const Color(0xFFf44336),
        ),
      );
    }
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

class ProfilePage extends StatelessWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Profile Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text('User ID: $userId'),
          // Add more profile details here
        ],
      ),
    );
  }
}