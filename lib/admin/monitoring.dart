import 'package:flutter/material.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  String selectedStatus = 'Tersedia';

  // Data parkir untuk tabel
  List<Map<String, dynamic>> parkingData = [
    {
      'zona': 'Mobil',
      'gate': 'A1', // Added 'gate'
      'status': 'Tersedia',
      'kendaraan': '',
      'kodeUnik': '',
      'waktu': '',
      'plat': '',
      'tarif': ''
    },
    {
      'zona': 'Motor',
      'gate': 'A2', // Added 'gate'
      'status': 'Tersedia',
      'kendaraan': '',
      'kodeUnik': '',
      'waktu': '',
      'plat': '',
      'tarif': ''
    },
    {
      'zona': 'Mobil',
      'gate': 'A3', // Added 'gate'
      'status': 'Terisi', // Changed to Terisi for demonstration
      'kendaraan': 'Mobil',
      'kodeUnik': 'XYZ789',
      'waktu': '10:30',
      'plat': 'B 1234 CD',
      'tarif': 'Rp 5.000'
    },
    {
      'zona': 'Motor',
      'gate': 'B1', // Added 'gate'
      'status': 'Tersedia',
      'kendaraan': '',
      'kodeUnik': '',
      'waktu': '',
      'plat': '',
      'tarif': ''
    },
    {
      'zona': 'Mobil',
      'gate': 'B2', // Added 'gate'
      'status': 'Terisi',
      'kendaraan': 'Motor',
      'kodeUnik': 'ABC123',
      'waktu': '09:00',
      'plat': 'D 5678 EF',
      'tarif': 'Rp 2.000'
    },
    {
      'zona': 'Mobil',
      'gate': 'B3', // Added 'gate'
      'status': 'Tersedia',
      'kendaraan': '',
      'kodeUnik': '',
      'waktu': '',
      'plat': '',
      'tarif': ''
    },
    {
      'zona': 'Motor',
      'gate': 'C1', // Added 'gate'
      'status': 'Tersedia',
      'kendaraan': '',
      'kodeUnik': '',
      'waktu': '',
      'plat': '',
      'tarif': ''
    },
    {
      'zona': 'Mobil',
      'gate': 'C2', // Added 'gate'
      'status': 'Terisi',
      'kendaraan': 'Mobil',
      'kodeUnik': 'PQR456',
      'waktu': '11:15',
      'plat': 'E 9012 GH',
      'tarif': 'Rp 6.000'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFilterSection(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildParkingTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Monitoring Parkir',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          const Text(
            'Status:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterButton(
            'Tersedia',
            isActive: selectedStatus == 'Tersedia',
            onTap: () {
              setState(() {
                selectedStatus = 'Tersedia';
              });
            },
          ),
          const SizedBox(width: 12),
          // Moved 'Kendaraan' filter to be directly next to 'Status' filters as per common UI patterns for related filters
          const Text(
            'Filter Lain:', // Changed label to be more general
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterButton(
            'Terisi',
            isActive: selectedStatus == 'Terisi',
            onTap: () {
              setState(() {
                selectedStatus = 'Terisi';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, {required bool isActive, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFA726) : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isActive ? const Color(0xFFFFA726) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildParkingTable() {
    // Filter the parking data based on selectedStatus
    final filteredParkingData = parkingData.where((data) {
      if (selectedStatus == 'Tersedia') {
        return data['status'] == 'Tersedia';
      } else if (selectedStatus == 'Terisi') {
        return data['status'] != 'Tersedia'; // Assuming 'Terisi' means anything not 'Tersedia'
      }
      return true; // Should not happen with current filter options
    }).toList();

    return Container(
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
          _buildTableHeader(),
          Expanded(
            child: _buildTableBody(filteredParkingData), // Pass filtered data
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFFA726),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              'Zona',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Gate', // Added Gate header
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Kendaraan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Kode Unik',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Waktu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Plat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Tarif',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody(List<Map<String, dynamic>> dataToDisplay) { // Accept data to display
    return ListView.builder(
      itemCount: dataToDisplay.length,
      itemBuilder: (context, index) {
        final data = dataToDisplay[index];
        final isEven = index % 2 == 0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isEven ? Colors.white : const Color(0xFFF8F9FA),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  data['zona'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  data['gate'], // Display Gate data
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data['status'] == 'Tersedia'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['status'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: data['status'] == 'Tersedia'
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ),
              Expanded(flex: 2, child: Text(data['kendaraan'] == '' ? '-' : data['kendaraan'])),
              Expanded(flex: 2, child: Text(data['kodeUnik'] == '' ? '-' : data['kodeUnik'])),
              Expanded(flex: 2, child: Text(data['waktu'] == '' ? '-' : data['waktu'])),
              Expanded(flex: 2, child: Text(data['plat'] == '' ? '-' : data['plat'])),
              Expanded(flex: 1, child: Text(data['tarif'] == '' ? '-' : data['tarif'])),
            ],
          ),
        );
      },
    );
  }
}