import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  int _selectedTab = 0;

  String _getStatusFromIndex(int index) {
    switch (index) {
      case 1:
        return 'selesai';
      case 2:
        return 'diproses';
      case 3:
        return 'menunggu';
      case 4:
        return 'dibatalkan';
      default:
        return 'semua';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ================= NAVBAR =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            color: const Color(0xFF61100D),
            child: Text(
              "Order History",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ================= TAB Chips =================
          Container(
            color: const Color(0xFFF5EFE6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildChipTab(0, 'Semua'),
                  _buildChipTab(1, 'Selesai'),
                  _buildChipTab(2, 'Diproses'),
                  _buildChipTab(3, 'Menunggu'),
                  _buildChipTab(4, 'Dibatalkan'),
                ],
              ),
            ),
          ),

          // ================= KONTEN TAB =================
          Expanded(
            child: _buildOrderList(_getStatusFromIndex(_selectedTab)),
          ),

        ],
      ),
    );
  }

  // Method chip tab
  Widget _buildChipTab(int index, String label) {
    final bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF61100D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF61100D) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(String status) {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text("User belum login"),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "Belum ada pesanan",
              style: GoogleFonts.poppins(),
            ),
          );
        }

        var orders = snapshot.data!.docs;

        if (status != 'semua') {
          orders = orders.where((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

            return data['status']
                    .toString()
                    .toLowerCase() ==
                status;
          }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 16,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {

            final data = orders[index].data()
                as Map<String, dynamic>;

            return _buildOrderCard(data);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
  Map<String, dynamic> order) {

    return Container(
      margin: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [

              Text(
                order['id'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              _buildStatusBadge(
                order['status']
                    .toString()
                    .toLowerCase(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(8),
                child: order['image_url'] != null
                    ? Image.network(
                        order['image_url'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      order['product_name'] ?? '',
                      style:
                          GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    Text(
                      "${order['qty']} box",
                      style:
                          GoogleFonts.poppins(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [

              Text(
                "Rp ${order['total_price']}",
                style: GoogleFonts.poppins(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              OutlinedButton(
                onPressed: () {},
                child: const Text(
                  "Detail",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'selesai':
        bgColor = const Color(0xFFEAF3DE);
        textColor = const Color(0xFF3B6D11);
        label = 'Selesai';
        break;
      case 'diproses':
        bgColor = const Color(0xFFFAEEDA);
        textColor = const Color(0xFF854F0B);
        label = 'Diproses';
        break;
      case 'menunggu':
        bgColor = const Color(0xFFE6F1FB);
        textColor = const Color(0xFF185FA5);
        label = 'Menunggu';
        break;
      case 'dibatalkan':
        bgColor = const Color(0xFFFCEBEB);
        textColor = const Color(0xFFA32D2D);
        label = 'Dibatalkan';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}