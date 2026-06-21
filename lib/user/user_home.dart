import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../landing/menu_page.dart';
import '../landing/menu_detail_page.dart';
import 'user_history.dart';
import 'user_profile.dart';
import 'user_cart.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {

  // ============================================================
  // STATE: index halaman yang sedang aktif di bottom nav
  // ============================================================
  int selectedIndex = 0;

  // ============================================================
  // KONSTANTA WARNA
  // ============================================================
  static const Color _primary = Color(0xFF61100D);
  static const Color _bgColor = Color(0xFFF5E6DA);

  // ============================================================
  // DAFTAR HALAMAN: dipake sebagai getter supaya tidak di-init
  // sebelum context siap
  // ============================================================
  List<Widget> get pages => [
    const SizedBox(),           // index 0 = home (ditangani _buildHomeContent)
    const MenuPage(),           // index 1 = katalog menu
    const HistoryPage(),        // index 2 = riwayat pesanan
    const UserProfile(),        // index 3 = profil
    const KeranjangPage(),      // index 4 = keranjang
  ];

  // ============================================================
  // HELPER: sapaan berdasarkan jam saat ini
  // ============================================================
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Selamat Pagi";
    if (hour < 15) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  // ============================================================
  // HELPER: ambil nama user dari Firebase Auth
  //         prioritas: displayName → bagian email sebelum @
  // ============================================================
  String getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User";
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null) return user.email!.split('@')[0];
    return "User";
  }

  // ============================================================
  // HELPER: format angka ke format Rupiah (Rp 1.000.000)
  // ============================================================
  String formatRupiah(dynamic number) {
    final n = number is int ? number : (number is num ? number.toInt() : 0);
    return "Rp ${n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  // ============================================================
  // HELPER: konversi dynamic ke int (aman untuk Firestore data)
  // ============================================================
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ============================================================
  // BUILD: struktur utama halaman dengan bottom floating navbar
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [

          // Konten utama: home atau halaman sesuai selectedIndex
          Positioned.fill(
            child: selectedIndex == 0
                ? _buildHomeContent()
                : pages[selectedIndex],
          ),

          // -------------------------------------------------------
          // FLOATING BOTTOM NAVBAR: home, menu, riwayat, profil, logout
          // -------------------------------------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _navItem(Icons.home, 0),
                    _navItem(Icons.menu, 1),
                    _navItem(Icons.receipt_long, 2),
                    _navItem(Icons.person, 3),
                    _logoutItem(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: konten halaman home (index 0)
  //         terdiri dari navbar, sapaan, quick actions,
  //         section menu pilihan, dan section pesanan aktif
  // ============================================================
  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildNavbar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Teks sapaan dengan nama user
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${getGreeting()}, ${getUserName()} 👋🏻",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Quick action buttons (pesan, status, keranjang)
                _quickActions(),
                const SizedBox(height: 30),

                // Section menu pilihan (horizontal scroll)
                _buildMenu(),
                const SizedBox(height: 20),

                // Section pesanan aktif user
                _buildOrderSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGET: navbar atas dengan nama aplikasi
  // ============================================================
  Widget _buildNavbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      color: _primary,
      child: Text(
        "Mbak Atik Catering",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: baris 3 tombol quick action
  //         (Pesan Sekarang, Status Pesanan, Keranjang)
  // ============================================================
  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol ke halaman katalog menu
          _quickItem(Icons.restaurant, "Pesan\nsekarang", () {
            setState(() => selectedIndex = 1);
          }),
          // Tombol ke halaman riwayat pesanan
          _quickItem(Icons.access_time, "Status\npesanan", () {
            setState(() => selectedIndex = 2);
          }),
          // Tombol ke keranjang dengan badge jumlah item
          _cartItem(),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: tombol quick action generik (ikon + label)
  // ============================================================
  Widget _quickItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primary),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: tombol keranjang dengan badge jumlah item real-time
  //         dari collection 'carts' milik user yang login
  // ============================================================
  Widget _cartItem() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('carts')
          .where('user_id', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Hitung jumlah item di keranjang
        int count = 0;
        if (snapshot.hasData) count = snapshot.data!.docs.length;

        return GestureDetector(
          onTap: () => setState(() => selectedIndex = 4),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart, color: _primary),
                  ),
                  // Badge merah jumlah item (muncul hanya jika count > 0)
                  if (count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$count",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text("Keranjang", style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // WIDGET: section "Menu Pilihan" — horizontal scroll card paket
  //         data diambil dari collection 'packages' di Firestore
  //         setiap card bisa diklik → navigasi ke MenuDetailPage
  // ============================================================
  Widget _buildMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section: judul + link "Lihat menu lainnya"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Menu Pilihan",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => selectedIndex = 1),
                child: Text(
                  "Lihat menu lainnya",
                  style: GoogleFonts.poppins(
                    color: _primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // -------------------------------------------------------
          // STREAM: ambil semua dokumen dari collection 'packages'
          // -------------------------------------------------------
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('packages')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              // -------------------------------------------------------
              // LIST CARD MENU: horizontal scroll, setiap card clickable
              // -------------------------------------------------------
              return SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    // Ambil field dari dokumen Firestore
                    final String name = data['name'] ?? 'Menu';
                    final int price = _toInt(data['price']);
                    final int minOrder = _toInt(data['min_order']);
                    final int leadTime = _toInt(data['lead_time']);
                    final List<dynamic> menuItems =
                        data['menu_items'] as List<dynamic>? ?? [];

                    // Generate description dari menu_items + min_order + lead_time
                    // karena field 'description' belum ada di Firestore
                    final String description = menuItems.isNotEmpty
                        ? "Termasuk: ${menuItems.join(', ')}\n\n"
                            "Minimal order: $minOrder porsi\n"
                            "Lead time: $leadTime hari"
                        : '';

                    // -------------------------------------------------------
                    // CARD: tap → navigasi ke MenuDetailPage dengan data paket
                    // -------------------------------------------------------
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuDetailPage(
                              name: name,
                              price: price,
                              description: description,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primary.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Nama paket
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Harga paket
                            Text(
                              formatRupiah(price),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                            // Min order (kalau ada)
                            if (minOrder > 0)
                              Text(
                                'Min. $minOrder porsi',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 6),

                            // Daftar isi menu (maks 3 item + "N lainnya")
                            if (menuItems.isNotEmpty) ...[
                              const Divider(height: 8, thickness: 0.5),
                              ...menuItems.take(3).map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 1),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.circle,
                                              size: 5, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              if (menuItems.length > 3)
                                Text(
                                  '+${menuItems.length - 3} lainnya',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: section "Pesanan Aktif" — daftar order user yang
  //         statusnya bukan 'selesai' atau 'dibatalkan'
  //         data dari collection 'orders' di Firestore
  // ============================================================
  Widget _buildOrderSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section: judul + link "Lihat semua"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pesanan Aktif",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => selectedIndex = 2),
                child: Text(
                  "Lihat semua",
                  style: GoogleFonts.poppins(
                    color: _primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (user == null)
            Text("User belum login", style: GoogleFonts.poppins(fontSize: 13))
          else
            // -------------------------------------------------------
            // STREAM: ambil orders milik user dari Firestore
            // -------------------------------------------------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('user_id', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allOrders = snapshot.data!.docs;

                // Filter hanya order yang masih aktif
                final activeOrders = allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status =
                      data['status']?.toString().toLowerCase().trim() ?? '';
                  return !status.contains('selesai') &&
                      !status.contains('dibatalkan');
                }).toList();

                // State kosong: tidak ada pesanan aktif
                if (activeOrders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Tidak ada pesanan aktif',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  );
                }

                // Tampilkan maks 3 pesanan aktif terbaru
                final displayed = activeOrders.take(3).toList();

                // -------------------------------------------------------
                // CARD ORDER AKTIF: nama item + badge status
                // -------------------------------------------------------
                return Column(
                  children: displayed.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final items = (data['items'] as List<dynamic>? ?? []);
                    final firstItem = items.isNotEmpty
                        ? items[0] as Map<String, dynamic>
                        : {};
                    final String namaItem =
                        firstItem['name']?.toString() ?? 'Pesanan';
                    final String status = data['status']?.toString() ?? '';
                    final int itemCount = items.length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama item pertama
                                Text(
                                  namaItem,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Keterangan item tambahan kalau > 1
                                if (itemCount > 1)
                                  Text(
                                    '+${itemCount - 1} item lainnya',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge warna sesuai status order
                          _buildStatusBadge(status.toLowerCase()),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: badge status order dengan warna berbeda per status
  //         (Selesai, Diproses, Menunggu Konfirmasi, Dibatalkan)
  // ============================================================
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase().trim()) {
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
      case 'menunggu konfirmasi':
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
        label = status.isEmpty ? '-' : status;
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
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: item di floating bottom navbar
  //         aktif = background merah muda + ikon merah
  // ============================================================
  Widget _navItem(IconData icon, int index) {
    final isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? _primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isActive ? _primary : Colors.grey,
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: tombol logout di navbar
  //         muncul dialog konfirmasi sebelum sign out
  // ============================================================
  Widget _logoutItem() {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Keluar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Text('Yakin ingin keluar?',
                style: GoogleFonts.poppins(fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Batal',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Keluar',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pop(context);
        }
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.logout, color: Colors.grey),
      ),
    );
  }
}