import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_detail_page.dart';
import '../user/user_cart.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {

  // ============================================================
  // STATE: kata kunci pencarian menu
  // ============================================================
  String searchQuery = "";

  static const Color _primary = Color(0xFF61100D);

  // ============================================================
  // HELPER: format angka ke Rupiah
  // ============================================================
  String formatRupiah(int number) {
    return "Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  // ============================================================
  // HELPER: konversi dynamic ke int
  // ============================================================
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ============================================================
  // FUNGSI: tambah paket ke collection 'carts' di Firestore
  //   - Kalau sudah ada → increment qty
  //   - Kalau belum ada → buat dokumen baru
  // ============================================================
  Future<void> _addToCart({
    required String packageId,
    required String name,
    required int price,
    required String type,
    required int leadTime,
    required int minOrder,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login terlebih dahulu.')),
      );
      return;
    }

    final cartsRef = FirebaseFirestore.instance.collection('carts');

    // Cek apakah paket ini sudah ada di keranjang user
    final existing = await cartsRef
        .where('user_id', isEqualTo: user.uid)
        .where('package_id', isEqualTo: packageId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Sudah ada → tambah qty
      final doc = existing.docs.first;
      final currentQty = (doc['qty'] as num?)?.toInt() ?? 1;
      final newQty = currentQty + 1;
      await cartsRef.doc(doc.id).update({
        'qty': newQty,
        'total_price': newQty * price,
      });
    } else {
      // Belum ada → buat dokumen baru
      await cartsRef.add({
        'user_id': user.uid,
        'package_id': packageId,
        'name': name,
        'price': price,
        'qty': 1,
        'total_price': price,
        'type': type,
        'lead_time': leadTime,
        'min_order': minOrder,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" ditambahkan ke keranjang 🛒'),
          duration: const Duration(seconds: 2),
          backgroundColor: _primary,
        ),
      );
    }
  }

  // ============================================================
  // BUILD: halaman katalog menu
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),
      body: Column(
        children: [
          // Navbar — style sama dengan user_home (horizontal: 30)
          _buildNavbar(context),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount = 2;
                if (width > 600) crossAxisCount = 3;
                if (width > 1000) crossAxisCount = 4;
                if (width > 1400) crossAxisCount = 5;

                return Column(
                  children: [

                    // ----------------------------------------
                    // SEARCH BAR: filter paket berdasarkan nama
                    // ----------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => searchQuery = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Cari paket...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ----------------------------------------
                    // GRID PAKET: stream dari collection 'packages'
                    // ----------------------------------------
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('packages')
                            .orderBy('type')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text("Error: ${snapshot.error}"));
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                                child: Text("Tidak ada data"));
                          }

                          // Filter berdasarkan searchQuery
                          final menus = snapshot.data!.docs.where((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final name =
                                (data['name'] ?? "").toString().toLowerCase();
                            return name.contains(searchQuery);
                          }).toList();

                          if (menus.isEmpty) {
                            return Center(
                              child: Text("Tidak ada paket 😢",
                                  style: GoogleFonts.poppins()),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                            itemCount: menus.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 0.95,
                            ),
                            itemBuilder: (context, index) {
                              final doc = menus[index];
                              final data =
                                  doc.data() as Map<String, dynamic>;

                              // Ambil semua field yang dibutuhkan
                              final packageId = doc.id;
                              final name = data['name'] ?? '';
                              final price = _toInt(data['price']);
                              final minOrder = _toInt(data['min_order']);
                              final leadTime = _toInt(data['lead_time']);
                              final type = data['type']?.toString() ?? '';

                              final menuItemsRaw = data['menu_items'];
                              final List<String> menuItems =
                                  menuItemsRaw is List
                                      ? menuItemsRaw
                                          .map((e) => e.toString())
                                          .toList()
                                      : <String>[];

                              // Generate description dari field Firestore
                              final description = menuItems.isNotEmpty
                                  ? "Termasuk: ${menuItems.join(', ')}\n\n"
                                      "Minimal order: $minOrder porsi\n"
                                      "Lead time: $leadTime hari"
                                  : (data['description'] ?? '').toString();

                              // ----------------------------------------
                              // CARD: tap → buka MenuDetailPage
                              //        tombol + → langsung tambah ke cart
                              // ----------------------------------------
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MenuDetailPage(
                                        packageId: packageId,
                                        name: name,
                                        price: price,
                                        description: description,
                                        type: type,
                                        leadTime: leadTime,
                                        minOrder: minOrder,
                                      ),
                                    ),
                                  );
                                },
                                child: _menuCard(
                                  name: name,
                                  price: price,
                                  menuItems: menuItems,
                                  onAddToCart: () => _addToCart(
                                    packageId: packageId,
                                    name: name,
                                    price: price,
                                    type: type,
                                    leadTime: leadTime,
                                    minOrder: minOrder,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: navbar — padding disesuaikan dengan user_home
  //         (horizontal: 30, vertical: 20)
  //         + ikon keranjang dengan badge jumlah item real-time
  // ============================================================
  Widget _buildNavbar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 11.5),
      color: _primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Katalog Menu",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          // Ikon keranjang + badge jumlah item
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser == null
                ? null
                : FirebaseFirestore.instance
                    .collection('carts')
                    .where('user_id',
                        isEqualTo:
                            FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Tombol keranjang — buka KeranjangPage
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const KeranjangPage()),
                      );
                    },
                  ),
                  // Badge merah jumlah item (tampil kalau count > 0)
                  if (count > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET CARD: tampilan satu paket di grid
  //   - Tap card → buka detail (onTap di InkWell)
  //   - Tap tombol + → tambah ke keranjang (onAddToCart)
  //     GestureDetector terpisah agar tidak trigger onTap card
  // ============================================================
  Widget _menuCard({
    required String name,
    required int price,
    required List<String> menuItems,
    required VoidCallback onAddToCart,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Nama paket
          Text(
            name,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Daftar isi menu
          if (menuItems.isNotEmpty)
            Text(
              menuItems.join(', '),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

          const Spacer(),

          // Harga + tombol tambah ke keranjang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatRupiah(price),
                style: const TextStyle(
                  color: Color(0xFF61100D),
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Tombol + — GestureDetector terpisah dari card tap
              GestureDetector(
                onTap: onAddToCart,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF61100D),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}