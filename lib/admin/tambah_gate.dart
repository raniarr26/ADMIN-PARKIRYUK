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
      QuerySnapshot snapshot =
          await _firestore.collection('parking_gates').get();
      setState(() {
        parkingGates =
            snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return ParkingGate(
                id: doc.id,
                gateName: data['gateName'] ?? '',
                area: data['area'] ?? '',
                location: data['lokasi'] ?? '',
                totalSlot: data['total_slot'] ?? 0,
              );
            }).toList();
      });
    } catch (e) {
      print('Error loading gates: $e');
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
        );
      },
    );
  }

  void _addGateToFirebase(ParkingGate gate) async {
    try {
      await _firestore.collection('parking_gates').add({
        'gateName': gate.gateName,
        'area': gate.area,
        'lokasi': gate.location,
        'total_slot': gate.totalSlot,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _loadGatesFromFirebase();
    } catch (e) {
      print('Error adding gate: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add gate: $e')));
    }
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
                DataColumn(label: Text('Gate')),
                DataColumn(label: Text('Area')),
                DataColumn(label: Text('Lokasi')),
                DataColumn(label: Text('Total Slot')),
              ],
              rows:
                  parkingGates.map((gate) {
                    return DataRow(
                      cells: [
                        DataCell(Text(gate.gateName)),
                        DataCell(Text(gate.area)),
                        DataCell(Text(gate.location)),
                        DataCell(Text(gate.totalSlot.toString())),
                      ],
                    );
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
          'Manajemen Gate Parkir',
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
              if (parkingGates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Belum ada gate parkir. Tambahkan sekarang!',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                buildDataTable(),
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

  const AddGateModal({Key? key, required this.onGateAdded}) : super(key: key);

  @override
  _AddGateModalState createState() => _AddGateModalState();
}

class _AddGateModalState extends State<AddGateModal> {
  final TextEditingController gateNameController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController totalSlotController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Gate Baru',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: gateNameController,
              decoration: const InputDecoration(labelText: 'Gate Name'),
            ),
            TextField(
              controller: areaController,
              decoration: const InputDecoration(labelText: 'Area'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Lokasi'),
            ),
            TextField(
              controller: totalSlotController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Slot'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newGate = ParkingGate(
                      id: DateTime.now().toString(),
                      gateName: gateNameController.text.trim(),
                      area: areaController.text.trim(),
                      location: locationController.text.trim(),
                      totalSlot:
                          int.tryParse(totalSlotController.text.trim()) ?? 0,
                    );
                    widget.onGateAdded(newGate);
                    Navigator.pop(context);
                  },
                  child: const Text('Tambah'),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ParkingGate {
  final String id;
  final String gateName;
  final String area;
  final String location;
  final int totalSlot;

  ParkingGate({
    required this.id,
    required this.gateName,
    required this.area,
    required this.location,
    required this.totalSlot,
  });
}
