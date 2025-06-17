import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class ParkingManagementPage extends StatefulWidget {
  @override
  _ParkingManagementPageState createState() => _ParkingManagementPageState();
}

class _ParkingManagementPageState extends State<ParkingManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ParkingGate> parkingGates = [];

  @override
  void initState() {
    super.initState();
    _loadGatesFromFirebase();
  }

  void _loadGatesFromFirebase() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('parking_gates').get();
      setState(() {
        parkingGates = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          // Ensure data['slots'] is not null and is a List
          List<dynamic> rawSlots = data['slots'] ?? []; 
          return ParkingGate(
            id: doc.id,
            gateName: data['gateName'],
            zone: data['zone'],
            slots: List<ParkingSlot>.from(rawSlots.map((slot) =>
                ParkingSlot(
                  slotNumber: slot['slotNumber'],
                  status: slot['status'],
                ))),
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading gates: $e');
      // Optionally show a user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load parking gates: $e')),
      );
    }
  }

  void _showAddGateModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddGateModal(
          onGateAdded: (ParkingGate newGate) {
            _addGateToFirebase(newGate);
            setState(() {
              parkingGates.add(newGate);
            });
          },
          existingGates: parkingGates,
        );
      },
    );
  }

  void _addGateToFirebase(ParkingGate gate) async {
    try {
      await _firestore.collection('parking_gates').add({
        'gateName': gate.gateName,
        'zone': gate.zone,
        'slots': gate.slots.map((slot) => {
          'slotNumber': slot.slotNumber,
          'status': slot.status,
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      // After adding, reload to get the ID from Firebase and update the UI
      _loadGatesFromFirebase(); 
    } catch (e) {
      print('Error adding gate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add gate: $e')),
      );
    }
  }

  Widget buildGateSection(ParkingGate gate, int gateIndex) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              '${gate.zone.toUpperCase()} - Gate ${gate.gateName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: gate.slots.length,
              itemBuilder: (context, slotIndex) {
                final slot = gate.slots[slotIndex];
                return Container(
                  decoration: BoxDecoration(
                    color: _getSlotColor(slot.status),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      slot.slotNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: slot.status == 'kosong' ? Colors.black87 : Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getSlotColor(String status) {
    switch (status) {
      case 'terisi':
        return Colors.blue;
      case 'booking':
        return Colors.red;
      default:
        return Colors.grey.shade300;
    }
  }

  Widget buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keterangan:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          buildLegendItem(Colors.grey.shade300, 'Kosong'),
          buildLegendItem(Colors.blue, 'Terisi'),
          buildLegendItem(Colors.red, 'Booking'),
        ],
      ),
    );
  }

  Widget buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget buildDataTable() {
    if (parkingGates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Data Gate Parkir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Zona')),
                DataColumn(label: Text('Gate')),
                DataColumn(label: Text('Total Slot')),
                DataColumn(label: Text('Kosong')),
                DataColumn(label: Text('Terisi')),
                DataColumn(label: Text('Booking')),
              ],
              rows: parkingGates.map((gate) {
                int kosong = gate.slots.where((s) => s.status == 'kosong').length;
                int terisi = gate.slots.where((s) => s.status == 'terisi').length;
                int booking = gate.slots.where((s) => s.status == 'booking').length;
                
                return DataRow(cells: [
                  DataCell(Text(gate.zone.toUpperCase())),
                  DataCell(Text(gate.gateName)),
                  DataCell(Text('${gate.slots.length}')),
                  DataCell(Text('$kosong')),
                  DataCell(Text('$terisi')),
                  DataCell(Text('$booking')),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mega Mall - Parkir Mobil', // Consider making this dynamic based on selected zone if needed
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 80,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: FloatingActionButton(
              onPressed: _showAddGateModal,
              backgroundColor: Colors.orange.shade600,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Display a loading indicator or message if parkingGates is empty initially
              if (parkingGates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No parking gates found. Add a new one!',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[ // Use '...' to spread the list of widgets
                ...parkingGates.map((gate) => buildGateSection(gate, parkingGates.indexOf(gate))),
                buildDataTable(),
                buildLegend(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AddGateModal extends StatefulWidget {
  final Function(ParkingGate) onGateAdded;
  final List<ParkingGate> existingGates;

  const AddGateModal({
    Key? key,
    required this.onGateAdded,
    required this.existingGates,
  }) : super(key: key);

  @override
  _AddGateModalState createState() => _AddGateModalState();
}

class _AddGateModalState extends State<AddGateModal> {
  String? selectedZone;
  String? selectedGate;
  List<String> selectedSlots = [];

  final List<String> zones = ['mobil', 'motor'];
  final List<String> gates = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']; // Increased gates for flexibility
  final List<String> slots = [ // More realistic slot names
    'M1', 'M2', 'M3', 'M4', 'M5', 'M6', 'M7', 'M8', 'M9', 'M10',
    'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10'
  ];

  List<String> getAvailableGates() {
    List<String> usedGates = widget.existingGates
        .where((gate) => gate.zone == selectedZone)
        .map((gate) => gate.gateName)
        .toList();
    return gates.where((gate) => !usedGates.contains(gate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        // Added SingleChildScrollView here to prevent overflow in the modal
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min to let column take only necessary space
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tambah Gate Baru',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Zone Selection
              Text(
                'Pilih Zona:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedZone,
                    hint: const Text('Pilih Zona'),
                    isExpanded: true,
                    items: zones.map((zone) {
                      return DropdownMenuItem(
                        value: zone,
                        child: Text(zone.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedZone = value;
                        selectedGate = null; // Reset gate selection
                        selectedSlots = []; // Reset slots
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gate Selection
              if (selectedZone != null) ...[
                Text(
                  'Pilih Gate:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedGate,
                      hint: const Text('Pilih Gate'),
                      isExpanded: true,
                      items: getAvailableGates().map((gate) {
                        return DropdownMenuItem(
                          value: gate,
                          child: Text('Gate $gate'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGate = value;
                          selectedSlots = []; // Reset slots
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Slot Selection
              if (selectedGate != null) ...[
                Text(
                  'Pilih Slot:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                // The GridView.builder for slots could cause overflow if too many slots or small screen
                // It's wrapped in a Container with a fixed height, which is good.
                // However, if the GridView content itself is too large for the fixed height,
                // it still needs to be scrollable.
                Container(
                  height: 200, // Fixed height for the slot selection area
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final isSelected = selectedSlots.contains(slot);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedSlots.remove(slot);
                            } else {
                              selectedSlots.add(slot);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange.shade600 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.orange.shade800 : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons
              if (selectedZone != null && selectedGate != null && selectedSlots.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final newGate = ParkingGate(
                          id: DateTime.now().millisecondsSinceEpoch.toString(), // Client-side ID for immediate UI update
                          gateName: selectedGate!,
                          zone: selectedZone!,
                          slots: selectedSlots.map((slot) => ParkingSlot(
                            slotNumber: slot,
                            status: 'kosong',
                          )).toList(),
                        );
                        widget.onGateAdded(newGate);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tambah Gate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Data Models (unchanged, but included for completeness)
class ParkingGate {
  final String id;
  final String gateName;
  final String zone;
  final List<ParkingSlot> slots;

  ParkingGate({
    required this.id,
    required this.gateName,
    required this.zone,
    required this.slots,
  });
}

class ParkingSlot {
  final String slotNumber;
  final String status; // 'kosong', 'terisi', 'booking'

  ParkingSlot({
    required this.slotNumber,
    required this.status,
  });
}