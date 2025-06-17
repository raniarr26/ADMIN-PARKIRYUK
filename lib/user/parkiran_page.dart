import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart'; // Untuk memformat tanggal

class ParkingHistoryPage extends StatefulWidget {
  final String userId;

  const ParkingHistoryPage({super.key, required this.userId});

  @override
  State<ParkingHistoryPage> createState() => _ParkingHistoryPageState();
}

class _ParkingHistoryPageState extends State<ParkingHistoryPage> {
  final Set<String> _processedParkings = {}; // To prevent redundant updates

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // === PERBAIKAN LOGIKA PENGHITUNGAN DURASI ===
  
  // Fungsi untuk menghitung sisa waktu hingga slot berakhir
  Duration _calculateRemainingTimeFromSlot(String timeSlot, String parkingDate) {
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(parkingDate);
      String endTime = timeSlot.split('-')[1].trim();
      List<String> timeParts = endTime.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      DateTime endDateTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
      DateTime now = DateTime.now();

      if (now.isBefore(endDateTime)) {
        return endDateTime.difference(now);
      } else {
        return Duration.zero;
      }
    } catch (e) {
      debugPrint('Error calculating remaining time for $parkingDate $timeSlot: $e');
      return Duration.zero;
    }
  }

  // Fungsi untuk menghitung total durasi slot
  Duration _calculateTotalSlotDuration(String timeSlot) {
    try {
      List<String> times = timeSlot.split('-').map((e) => e.trim()).toList();
      String startTimeStr = times[0];
      String endTimeStr = times[1];

      List<String> startParts = startTimeStr.split(':');
      int startHour = int.parse(startParts[0]);
      int startMinute = int.parse(startParts[1]);

      List<String> endParts = endTimeStr.split(':');
      int endHour = int.parse(endParts[0]);
      int endMinute = int.parse(endParts[1]);

      DateTime startDateTime = DateTime(2000, 1, 1, startHour, startMinute);
      DateTime endDateTime = DateTime(2000, 1, 1, endHour, endMinute);

      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
      return endDateTime.difference(startDateTime);
    } catch (e) {
      debugPrint('Error calculating total duration for $timeSlot: $e');
      return Duration.zero;
    }
  }

  // Fungsi untuk menghitung waktu yang sudah terpakai (hanya jika slot sudah dimulai)
  Duration _calculateUsedTimeFromSlot(String timeSlot, String parkingDate) {
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(parkingDate);
      String startTimeStr = timeSlot.split('-')[0].trim();
      String endTimeStr = timeSlot.split('-')[1].trim();
      
      List<String> startParts = startTimeStr.split(':');
      int startHour = int.parse(startParts[0]);
      int startMinute = int.parse(startParts[1]);

      List<String> endParts = endTimeStr.split(':');
      int endHour = int.parse(endParts[0]);
      int endMinute = int.parse(endParts[1]);

      DateTime startDateTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, startHour, startMinute);
      DateTime endDateTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, endHour, endMinute);
      DateTime now = DateTime.now();

      // Jika waktu sekarang masih sebelum slot dimulai, return 0
      if (now.isBefore(startDateTime)) {
        return Duration.zero;
      }
      
      // Jika waktu sekarang sudah melewati slot berakhir, return total durasi slot
      if (now.isAfter(endDateTime)) {
        return endDateTime.difference(startDateTime);
      }
      
      // Jika waktu sekarang di antara start dan end, hitung durasi yang sudah berjalan
      return now.difference(startDateTime);
    } catch (e) {
      debugPrint('Error calculating used time for $parkingDate $timeSlot: $e');
      return Duration.zero;
    }
  }

  // Fungsi untuk mengecek apakah slot sudah dimulai
  bool _hasSlotStarted(String timeSlot, String parkingDate) {
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(parkingDate);
      String startTimeStr = timeSlot.split('-')[0].trim();
      List<String> timeParts = startTimeStr.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      DateTime startDateTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
      DateTime now = DateTime.now();

      return now.isAfter(startDateTime);
    } catch (e) {
      debugPrint('Error checking if slot has started for $parkingDate $timeSlot: $e');
      return false;
    }
  }

  // Fungsi untuk mengecek apakah slot sudah berakhir
  bool _hasSlotExpired(String timeSlot, String parkingDate) {
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(parkingDate);
      String endTime = timeSlot.split('-')[1].trim();
      List<String> timeParts = endTime.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      DateTime endDateTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
      DateTime now = DateTime.now();

      return now.isAfter(endDateTime);
    } catch (e) {
      debugPrint('Error checking if slot has expired for $parkingDate $timeSlot: $e');
      return false;
    }
  }

  Future<void> _updateParkingGateStatus(String gateName, String slotNumber, String parkingId) async {
    if (_processedParkings.contains(parkingId)) {
      debugPrint('Parking $parkingId already processed. Skipping update.');
      return;
    }

    try {
      _processedParkings.add(parkingId);

      QuerySnapshot gateQuery = await FirebaseFirestore.instance
          .collection('parking_gates')
          .where('gateName', isEqualTo: gateName)
          .limit(1)
          .get();

      if (gateQuery.docs.isNotEmpty) {
        DocumentSnapshot gateDoc = gateQuery.docs.first;

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot freshGateDoc = await transaction.get(gateDoc.reference);
          Map<String, dynamic> gateData = freshGateDoc.data() as Map<String, dynamic>;
          List<dynamic> slots = List.from(gateData['slots'] ?? []);

          bool slotFoundAndUpdated = false;
          for (int i = 0; i < slots.length; i++) {
            if (slots[i]['slotNumber'] == slotNumber) {
              slots[i]['status'] = 'kosong';
              slotFoundAndUpdated = true;
              break;
            }
          }

          if (!slotFoundAndUpdated) {
            debugPrint('Slot $slotNumber not found in gate $gateName document. Cannot update status.');
          } else {
            transaction.update(gateDoc.reference, {
              'slots': slots,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }

          DocumentReference parkingRef = FirebaseFirestore.instance.collection('parkir').doc(parkingId);
          transaction.update(parkingRef, {
            'status': 'expired',
            'updated_at': FieldValue.serverTimestamp(),
          });
        });

        debugPrint('Status parking gate $gateName-$slotNumber (via parking $parkingId) berhasil diupdate menjadi kosong');
        debugPrint('Parking $parkingId status updated to expired');
      } else {
        debugPrint('Parking gate document for $gateName not found for parking $parkingId.');
      }
    } catch (e) {
      debugPrint('Error updating parking gate status for parking $parkingId: $e');
      _processedParkings.remove(parkingId);
    }
  }

  void _checkAndUpdateExpiredParkings(List<DocumentSnapshot> docs) {
    // Hanya cek parking untuk tanggal hari ini
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (DocumentSnapshot doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      String parkingId = doc.id;
      String parkingDate = data['parkir_date'] ?? '';
      String timeSlot = data['time_slot'] ?? '';
      String status = data['status'] ?? '';
      String gateName = data['gate_name'] ?? '';
      String slotNumber = data['slot_number'] ?? '';

      if ((status.toLowerCase() == 'active' || status.toLowerCase() == 'confirmed') &&
          parkingDate == currentDate &&
          !_processedParkings.contains(parkingId)) {
        
        // Cek apakah slot sudah expired menggunakan fungsi yang diperbaiki
        bool isExpired = _hasSlotExpired(timeSlot, parkingDate);

        if (isExpired) {
          _updateParkingGateStatus(gateName, slotNumber, parkingId);
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _getVehicleTypeDisplay(String vehicleType) {
    return vehicleType.toLowerCase() == 'motor' ? 'Motor' : 'Mobil';
  }

  String _getTimeSlotDisplay(String timeSlot) {
    return timeSlot.replaceAll('-', ' - ');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'DIKONFIRMASI';
      case 'active':
        return 'AKTIF';
      case 'completed':
        return 'SELESAI';
      case 'cancelled':
        return 'DIBATALKAN';
      case 'expired':
        return 'KEDALUWARSA';
      case 'pending':
        return 'MENUNGGU';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD700),
        title: const Text(
          'Riwayat Parkir',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parkir')
            .where('user_id', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFA500)),
            );
          }

          if (snapshot.hasError) {
            debugPrint('Firestore Stream Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan saat memuat data: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_parking,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat parkir',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Parkir pertama Anda akan muncul di sini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          List<DocumentSnapshot> parkings = List.from(snapshot.data!.docs);
          parkings.sort((a, b) {
            Timestamp? createdAtA = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
            Timestamp? createdAtB = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;

            if (createdAtA == null && createdAtB == null) return 0;
            if (createdAtA == null) return 1;
            if (createdAtB == null) return -1;

            return createdAtB.compareTo(createdAtA);
          });

          _checkAndUpdateExpiredParkings(parkings);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: parkings.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = parkings[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              return ParkingCard(
                key: ValueKey(doc.id),
                data: data,
                parkingId: doc.id,
                onUpdateStatus: (gateName, slotNumber, parkingId) =>
                    _updateParkingGateStatus(gateName, slotNumber, parkingId),
                formatDuration: _formatDuration,
                getVehicleTypeDisplay: _getVehicleTypeDisplay,
                getTimeSlotDisplay: _getTimeSlotDisplay,
                getStatusColor: _getStatusColor,
                getStatusDisplay: _getStatusDisplay,
                calculateRemainingTimeFromSlot: _calculateRemainingTimeFromSlot,
                calculateTotalSlotDuration: _calculateTotalSlotDuration,
                calculateUsedTimeFromSlot: _calculateUsedTimeFromSlot,
                hasSlotStarted: _hasSlotStarted,
                hasSlotExpired: _hasSlotExpired,
              );
            },
          );
        },
      ),
    );
  }
}

// ParkingCard dengan logika penghitungan yang diperbaiki
class ParkingCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String parkingId;
  final Function(String, String, String) onUpdateStatus;
  final String Function(Duration) formatDuration;
  final String Function(String) getVehicleTypeDisplay;
  final String Function(String) getTimeSlotDisplay;
  final Color Function(String) getStatusColor;
  final String Function(String) getStatusDisplay;
  final Duration Function(String, String) calculateRemainingTimeFromSlot;
  final Duration Function(String) calculateTotalSlotDuration;
  final Duration Function(String, String) calculateUsedTimeFromSlot;
  final bool Function(String, String) hasSlotStarted;
  final bool Function(String, String) hasSlotExpired;

  const ParkingCard({
    required super.key,
    required this.data,
    required this.parkingId,
    required this.onUpdateStatus,
    required this.formatDuration,
    required this.getVehicleTypeDisplay,
    required this.getTimeSlotDisplay,
    required this.getStatusColor,
    required this.getStatusDisplay,
    required this.calculateRemainingTimeFromSlot,
    required this.calculateTotalSlotDuration,
    required this.calculateUsedTimeFromSlot,
    required this.hasSlotStarted,
    required this.hasSlotExpired,
  });

  @override
  State<ParkingCard> createState() => _ParkingCardState();
}

class _ParkingCardState extends State<ParkingCard> {
  Timer? _cardTimer;
  Duration _remainingTime = Duration.zero;
  Duration _usedTime = Duration.zero;
  bool _isExpired = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _updateTimes();
    _startCardTimer();
  }

  @override
  void didUpdateWidget(covariant ParkingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _updateTimes();
      _startCardTimer();
    }
  }

  @override
  void dispose() {
    _cardTimer?.cancel();
    super.dispose();
  }

  void _updateTimes() {
    final String parkingDate = widget.data['parkir_date'] ?? '';
    final String timeSlot = widget.data['time_slot'] ?? '';

    _remainingTime = widget.calculateRemainingTimeFromSlot(timeSlot, parkingDate);
    _usedTime = widget.calculateUsedTimeFromSlot(timeSlot, parkingDate);
    _isExpired = widget.hasSlotExpired(timeSlot, parkingDate);
    _hasStarted = widget.hasSlotStarted(timeSlot, parkingDate);
  }

  void _startCardTimer() {
    String status = widget.data['status'] ?? '';
    
    // Timer hanya jalan jika parking masih aktif/confirmed dan belum expired
    if ((status.toLowerCase() == 'active' || status.toLowerCase() == 'confirmed') && !_isExpired) {
      _cardTimer?.cancel();
      _cardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _updateTimes();
            
            // Jika slot sudah expired, trigger update status dan stop timer
            if (_isExpired) {
              timer.cancel();
              Future.microtask(() => widget.onUpdateStatus(
                    widget.data['gate_name'] ?? '',
                    widget.data['slot_number'] ?? '',
                    widget.parkingId,
                  ));
            }
          });
        }
      });
    } else {
      _cardTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    String parkiranCode = widget.data['parkiran_code'] ?? 'N/A';
    String parkingDate = widget.data['parkir_date'] ?? '';
    String timeSlot = widget.data['time_slot'] ?? '';
    String gateName = widget.data['gate_name'] ?? '';
    String slotNumber = widget.data['slot_number'] ?? '';
    String status = widget.data['status'] ?? '';
    String vehicleType = widget.data['vehicle_type'] ?? '';

    Duration totalSlotDuration = widget.calculateTotalSlotDuration(timeSlot);

    // Menentukan status tampilan berdasarkan kondisi waktu
    String timeStatus;
    Color timeStatusColor;
    
    if (_isExpired) {
      timeStatus = 'Expired';
      timeStatusColor = Colors.red;
    } else if (!_hasStarted) {
      timeStatus = 'Belum Dimulai';
      timeStatusColor = Colors.blue;
    } else {
      timeStatus = 'Sisa Waktu';
      timeStatusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kode Parkir',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parkiranCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA500),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.getStatusDisplay(status),
                    style: TextStyle(
                      color: widget.getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.calendar_today,
                    'Tanggal',
                    DateFormat('dd MMMM yyyy').format(DateTime.parse(parkingDate)),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.access_time,
                    'Jam',
                    widget.getTimeSlotDisplay(timeSlot),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.local_parking,
                    'Lokasi',
                    'Gate $gateName - Slot $slotNumber',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.directions_car,
                    'Kendaraan',
                    widget.getVehicleTypeDisplay(vehicleType),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Total Durasi Slot',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.formatDuration(totalSlotDuration),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isExpired ? Icons.schedule 
                                    : !_hasStarted ? Icons.pending
                                    : Icons.hourglass_bottom,
                                  size: 16,
                                  color: timeStatusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: timeStatusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isExpired ? '00:00:00' : widget.formatDuration(_remainingTime),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: timeStatusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (totalSlotDuration.inSeconds > 0) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress Waktu Parkir',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (_usedTime.inSeconds / totalSlotDuration.inSeconds).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isExpired ? Colors.red 
                              : !_hasStarted ? Colors.blue
                              : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Terpakai: ${widget.formatDuration(_usedTime)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}