import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:sistem_parkir/user/parkiran_page.dart';

class PindaiMasukParkiranPage extends StatefulWidget {
  final String userId;
  const PindaiMasukParkiranPage({super.key, required this.userId});

  @override
  State<PindaiMasukParkiranPage> createState() => _PindaiMasukParkiranPageState();
}

class _PindaiMasukParkiranPageState extends State<PindaiMasukParkiranPage> {
  String? selectedVehicleType;
  String? selectedTimeSlot;
  List<Map<String, dynamic>> availableParkingSpots = [];
  String? selectedParkingSpot;
  bool isLoadingSpots = false;

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
          'Pindai Masuk Parkiran',
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

            _buildSectionTitle('2. Pilih Jam Parkir'),
            const SizedBox(height: 15),
            _buildTimeSlotSelector(),
            const SizedBox(height: 30),

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
                    'Konfirmasi Parkir',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                            color: isSelected ? Colors.black : Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Gate: ${spot['gateName']} - ${_getVehicleDisplayName(spot['slotNumber'])}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.black87 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Kosong',
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

  String _getVehicleDisplayName(String slotNumber) {
    if (slotNumber.toUpperCase().startsWith('M')) {
      return 'Motor';
    } else if (slotNumber.toUpperCase().startsWith('C') ||
               slotNumber.toUpperCase().startsWith('A') ||
               slotNumber.toUpperCase().startsWith('B')) {
      return 'Mobil';
    }
    return 'Mobil/Lainnya';
  }

  void _selectVehicleType(String type) {
    setState(() {
      selectedVehicleType = type;
      selectedParkingSpot = null;
      availableParkingSpots.clear();
    });
    if (selectedTimeSlot != null) {
      _loadAvailableParkingSpots();
    }
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      selectedTimeSlot = timeSlot;
      selectedParkingSpot = null;
      availableParkingSpots.clear();
    });
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
    if (selectedVehicleType == null || selectedTimeSlot == null) {
      setState(() {
        availableParkingSpots.clear();
        isLoadingSpots = false;
      });
      return;
    }

    setState(() {
      isLoadingSpots = true;
      availableParkingSpots.clear();
      selectedParkingSpot = null;
    });

    try {
      QuerySnapshot parkingGatesSnapshot =
          await FirebaseFirestore.instance.collection('parking_gates').get();

      List<Map<String, dynamic>> spots = [];

      for (QueryDocumentSnapshot doc in parkingGatesSnapshot.docs) {
        Map<String, dynamic> gateData = doc.data() as Map<String, dynamic>;
        String gateName = gateData['gateName'] ?? '';
        List<dynamic> slots = gateData['slots'] ?? [];

        for (var slot in slots) {
          String slotNumber = slot['slotNumber'] ?? '';
          String status = slot['status'] ?? '';

          bool isCorrectVehicleType = false;
          if (selectedVehicleType == 'motor') {
            isCorrectVehicleType = slotNumber.toUpperCase().startsWith('M');
          } else if (selectedVehicleType == 'mobil') {
            isCorrectVehicleType = !slotNumber.toUpperCase().startsWith('M') && slotNumber.isNotEmpty;
          }

          if (isCorrectVehicleType && status.toLowerCase() == 'kosong') {
            bool isBookedForTimeSlot = await _isSpotBooked(
              gateName,
              slotNumber,
              selectedTimeSlot!,
            );

            if (!isBookedForTimeSlot) {
              spots.add({
                'id': '${gateName}_$slotNumber',
                'slotNumber': slotNumber,
                'gateName': gateName,
                'status': status,
                'gateDocId': doc.id,
              });
            }
          }
        }
      }

      setState(() {
        availableParkingSpots = spots;
        isLoadingSpots = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSpots = false;
        availableParkingSpots.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data tempat parkir: $e')),
      );
    }
  }

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
          .collection('parkir')  // Menggunakan koleksi 'parkir'
          .where('gate_name', isEqualTo: gateName)
          .where('slot_number', isEqualTo: slotNumber)
          .where('parkir_date', isEqualTo: currentDate)
          .where('time_slot', isEqualTo: timeSlot)
          .where('status', whereIn: ['active', 'confirmed', 'completed'])
          .get();

      return bookingSnapshot.docs.isNotEmpty;
    } catch (e) {
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
      String bookingCode = _generateBookingCode();
      DateTime now = DateTime.now();
      String currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      Map<String, dynamic> selectedSpot = availableParkingSpots.firstWhere(
        (spot) => spot['id'] == selectedParkingSpot,
      );

      Map<String, dynamic> bookingData = {
        'user_id': widget.userId,
        'gate_name': selectedSpot['gateName'],
        'slot_number': selectedSpot['slotNumber'],
        'parkiran_code': bookingCode,
        'vehicle_type': selectedVehicleType!,
        'parkir_date': currentDate,
        'time_slot': selectedTimeSlot!,
        'status': 'confirmed',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Menyimpan ke koleksi 'parkir' bukan 'parkirs'
      DocumentReference bookingRef =
          FirebaseFirestore.instance.collection('parkir').doc();
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
          slots[i]['status'] = 'terisi';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat booking: $e'))
      );
    }
  }

  void _showBookingSuccessDialog(String bookingCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              const Text('Booking parkir Anda telah dikonfirmasi.'),
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
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ParkingHistoryPage(userId: widget.userId),
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