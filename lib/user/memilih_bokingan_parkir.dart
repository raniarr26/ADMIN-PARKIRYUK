import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:sistem_parkir/user/boking_parkir.dart'; 

class BokingParkirPage extends StatefulWidget {
  final String userId;
  const BokingParkirPage({super.key, required this.userId});

  @override
  State<BokingParkirPage> createState() => _BokingParkirPageState();
}

class _BokingParkirPageState extends State<BokingParkirPage> {
  String? selectedVehicleType;
  String? selectedTimeSlot;
  List<Map<String, dynamic>> availableParkingSpots = [];
  String? selectedParkingSpot;
  bool isLoadingSpots = false;

  // Time slots with 4-hour intervals
  final List<Map<String, String>> timeSlots = [
    {'label': '06:00 - 10:00', 'value': '06:00-10:00'},
    {'label': '10:00 - 14:00', 'value': '10:00-14:00'},
    {'label': '14:00 - 18:00', 'value': '14:00-18:00'},
    {'label': '18:00 - 22:00', 'value': '18:00-22:00'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          'Booking Tempat Parkir',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Pilih Jenis Kendaraan
            _buildSectionTitle('1. Pilih Jenis Kendaraan'),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildVehicleCard(
                    'motor',
                    Icons.motorcycle,
                    selectedVehicleType == 'motor',
                    () => _selectVehicleType('motor'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildVehicleCard(
                    'mobil',
                    Icons.directions_car,
                    selectedVehicleType == 'mobil',
                    () => _selectVehicleType('mobil'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Step 2: Pilih Jam
            _buildSectionTitle('2. Pilih Jam Parkir'),
            const SizedBox(height: 15),
            _buildTimeSlotSelector(),
            const SizedBox(height: 30),

            // Step 3: Pilih Tempat Parkir
            if (selectedVehicleType != null && selectedTimeSlot != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('3. Pilih Tempat Parkir'),
                  const SizedBox(height: 15),
                  _buildParkingSpotSelector(),
                  const SizedBox(height: 30),
                ],
              ),

            // Tombol Booking
            if (selectedParkingSpot != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Konfirmasi Booking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildVehicleCard(
    String type,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA500) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
          Icon(
            icon,
            size: 40,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
          const SizedBox(height: 10),
          Text(
            type == 'motor' ? 'Motor' : 'Mobil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    return Column(
      children: timeSlots.map((slot) {
        bool isSelected = selectedTimeSlot == slot['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _selectTimeSlot(slot['value']!),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFFFA500) : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: isSelected ? Colors.black : const Color(0xFFFFA500),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    slot['label']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.black : Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.black),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParkingSpotSelector() {
    if (isLoadingSpots) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFA500)),
      );
    }

    if (availableParkingSpots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tidak ada tempat parkir yang tersedia untuk pilihan ini.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: availableParkingSpots.map((spot) {
        bool isSelected = selectedParkingSpot == spot['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _selectParkingSpot(spot['id']),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFFFA500) : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_parking,
                    color: isSelected ? Colors.black : const Color(0xFFFFA500),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Slot ${spot['slotNumber']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.black : Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Gate: ${spot['gateName']} - ${_getVehicleDisplayName(spot['slotNumber'])}',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isSelected ? Colors.black87 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Display status, primarily "Kosong" since we're filtering for available
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green, // Always green for "Kosong"
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Kosong', // Display "Kosong" as these are available spots
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Logic Methods ---

  String _getVehicleDisplayName(String slotNumber) {
    if (slotNumber.toUpperCase().startsWith('M')) {
      return 'Motor';
    } else if (slotNumber.toUpperCase().startsWith('C') ||
               slotNumber.toUpperCase().startsWith('A') || // Assuming A, B could be car slots
               slotNumber.toUpperCase().startsWith('B')) {
      return 'Mobil';
    }
    // Fallback if no specific prefix matches, could imply a generic car slot
    return 'Mobil/Lainnya';
  }

  void _selectVehicleType(String type) {
    setState(() {
      selectedVehicleType = type;
      // Reset selected parking spot and clear available spots when vehicle type changes
      selectedParkingSpot = null;
      availableParkingSpots.clear();
    });
    // Load spots if a time slot is already selected
    if (selectedTimeSlot != null) {
      _loadAvailableParkingSpots();
    }
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      selectedTimeSlot = timeSlot;
      // Reset selected parking spot and clear available spots when time slot changes
      selectedParkingSpot = null;
      availableParkingSpots.clear();
    });
    // Load spots if a vehicle type is already selected
    if (selectedVehicleType != null) {
      _loadAvailableParkingSpots();
    }
  }

  void _selectParkingSpot(String spotId) {
    setState(() {
      selectedParkingSpot = spotId;
    });
  }

  Future<void> _loadAvailableParkingSpots() async {
    // Only proceed if both vehicle type and time slot are selected
    if (selectedVehicleType == null || selectedTimeSlot == null) {
      setState(() {
        availableParkingSpots.clear(); // Ensure list is clear if conditions aren't met
        isLoadingSpots = false;
      });
      return;
    }

    setState(() {
      isLoadingSpots = true;
      availableParkingSpots.clear(); // Clear previous spots before loading new ones
      selectedParkingSpot = null; // Clear selected spot
    });

    try {
      print('Loading parking spots for vehicle type: $selectedVehicleType and time slot: $selectedTimeSlot');

      // Query all parking gates
      QuerySnapshot parkingGatesSnapshot =
          await FirebaseFirestore.instance.collection('parking_gates').get();

      List<Map<String, dynamic>> spots = [];

      for (QueryDocumentSnapshot doc in parkingGatesSnapshot.docs) {
        Map<String, dynamic> gateData = doc.data() as Map<String, dynamic>;
        String gateName = gateData['gateName'] ?? '';
        List<dynamic> slots = gateData['slots'] ?? [];

        print('Processing gate: $gateName with ${slots.length} slots');

        for (var slot in slots) {
          String slotNumber = slot['slotNumber'] ?? '';
          String status = slot['status'] ?? ''; // Current status from Firestore

          print('Checking slot: $slotNumber, status: $status');

          // Check if slot is for the selected vehicle type
          bool isCorrectVehicleType = false;
          if (selectedVehicleType == 'motor') {
            isCorrectVehicleType = slotNumber.toUpperCase().startsWith('M');
          } else if (selectedVehicleType == 'mobil') {
            // Consider slots that are not 'M' as car slots
            isCorrectVehicleType = !slotNumber.toUpperCase().startsWith('M') && slotNumber.isNotEmpty;
          }

          print('Slot $slotNumber - isCorrectVehicleType: $isCorrectVehicleType');

          // Ensure the slot is explicitly 'kosong' from Firestore and is the correct vehicle type
          if (isCorrectVehicleType && status.toLowerCase() == 'kosong') {
            // Check if this specific spot is already booked for the selected date and time slot
            bool isBookedForTimeSlot = await _isSpotBooked(
              gateName,
              slotNumber,
              selectedTimeSlot!,
            );

            print('Slot $slotNumber - isBookedForTimeSlot: $isBookedForTimeSlot');

            if (!isBookedForTimeSlot) {
              spots.add({
                'id': '${gateName}_$slotNumber', // Unique ID for selection
                'slotNumber': slotNumber,
                'gateName': gateName,
                'status': status, // Should be 'kosong' here
                'gateDocId': doc.id, // Store doc ID to update later
              });
            }
          }
        }
      }

      print('Found ${spots.length} available spots after all checks');

      setState(() {
        availableParkingSpots = spots;
        isLoadingSpots = false;
      });
    } catch (e) {
      print('Error loading parking spots: $e');
      setState(() {
        isLoadingSpots = false;
        availableParkingSpots.clear(); // Clear spots on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data tempat parkir: $e')),
      );
    }
  }

  /// Checks if a specific parking spot is already booked for the given date and time slot.
  Future<bool> _isSpotBooked(
    String gateName,
    String slotNumber,
    String timeSlot,
  ) async {
    try {
      DateTime now = DateTime.now();
      String currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('gate_name', isEqualTo: gateName)
          .where('slot_number', isEqualTo: slotNumber)
          .where('booking_date', isEqualTo: currentDate)
          .where('time_slot', isEqualTo: timeSlot)
          .where('status', whereIn: ['active', 'confirmed', 'completed']) // Consider 'completed' if the spot remains unavailable
          .get();

      return bookingSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking booking status for $gateName/$slotNumber at $timeSlot: $e');
      // It's safer to assume it's booked if an error occurs to prevent overbooking
      return true;
    }
  }

  String _generateBookingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _createBooking() async {
    if (selectedVehicleType == null ||
        selectedTimeSlot == null ||
        selectedParkingSpot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua pilihan')),
      );
      return;
    }

    try {
      // Generate a unique booking code
      String bookingCode = _generateBookingCode();
      DateTime now = DateTime.now();
      String currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Find the details of the selected parking spot from the loaded list
      Map<String, dynamic> selectedSpot = availableParkingSpots.firstWhere(
        (spot) => spot['id'] == selectedParkingSpot,
      );

      // Create booking data
      Map<String, dynamic> bookingData = {
        'user_id': widget.userId,
        'gate_name': selectedSpot['gateName'],
        'slot_number': selectedSpot['slotNumber'],
        'booking_code': bookingCode,
        'vehicle_type': selectedVehicleType!,
        'booking_date': currentDate,
        'time_slot': selectedTimeSlot!,
        'status': 'confirmed', // Set initial status as 'confirmed'
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Start a batch operation for atomicity
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add booking document to the 'bookings' collection
      DocumentReference bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc();
      batch.set(bookingRef, bookingData);

     
      String gateDocId = selectedSpot['gateDocId'];
      DocumentReference gateRef = FirebaseFirestore.instance
          .collection('parking_gates')
          .doc(gateDocId);

     
      DocumentSnapshot gateDoc = await gateRef.get();
      if (!gateDoc.exists) {
        throw Exception('Parking gate document not found!');
      }
      Map<String, dynamic> currentGateData = gateDoc.data() as Map<String, dynamic>;
      List<dynamic> slots = List.from(currentGateData['slots'] ?? []);

     
      bool slotFoundAndUpdated = false;
      for (int i = 0; i < slots.length; i++) {
        if (slots[i]['slotNumber'] == selectedSpot['slotNumber']) {
          slots[i]['status'] = 'booking'; 
          slotFoundAndUpdated = true;
          break;
        }
      }

      if (!slotFoundAndUpdated) {
        throw Exception('Selected slot not found in gate document.');
      }

   
      batch.update(gateRef, {
        'slots': slots,
        'updated_at': FieldValue.serverTimestamp(),
      });

   
      await batch.commit();


      _showBookingSuccessDialog(bookingCode);
    } catch (e) {
      print('Error creating booking: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat booking: $e')));
    }
  }

  void _showBookingSuccessDialog(String bookingCode) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Booking Berhasil!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Booking Anda telah dikonfirmasi.'),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFA500)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kode Booking:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      bookingCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA500),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Jam Parkir: ${timeSlots.firstWhere((slot) => slot['value'] == selectedTimeSlot)['label']}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 15),
              const Text(
                'Simpan kode ini untuk masuk ke area parkir.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to the Booking History Page and replace the current route
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => BookingHistoryPage(userId: widget.userId),
                  ),
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFFFFA500),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}