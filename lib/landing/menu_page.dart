import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_detail_page.dart';
import '../user/user_cart.dart';

// ================= MODEL KATEGORI =================
class _KategoriModel {
  final String id;
  final String label;
  final Color colorBg;
  final Color colorText;
  final Color colorStrip;

  _KategoriModel({
    required this.id,
    required this.label,
    required this.colorBg,
    required this.colorText,
    required this.colorStrip,
  });

  factory _KategoriModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _KategoriModel(
      id: doc.id,
      label: d['label'] ?? doc.id,
      colorBg:
          Color(int.tryParse(d['color_bg'] ?? '0xFFEEEDFE') ?? 0xFFEEEDFE),
      colorText:
          Color(int.tryParse(d['color_text'] ?? '0xFF3C3489') ?? 0xFF3C3489),
      colorStrip:
          Color(int.tryParse(d['color_strip'] ?? '0xFF7A1C1C') ?? 0xFF7A1C1C),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String searchQuery = '';

  static const Color _primary = Color(0xFF61100D);
  static const Color _bgColor = Color(0xFFF5E6DA);
  static const Color _textSoft = Color(0xFF8E8E8E);

  String formatRupiah(int number) {
    return "Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ============================================================
  // FUNGSI: tambah paket ke collection 'carts' di Firestore
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

    final existing = await cartsRef
        .where('user_id', isEqualTo: user.uid)
        .where('package_id', isEqualTo: packageId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final currentQty = (doc['qty'] as num?)?.toInt() ?? 1;
      final newQty = currentQty + 1;
      await cartsRef.doc(doc.id).update({
        'qty': newQty,
        'total_price': newQty * price,
      });
    } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          _buildNavbar(context),
          // Search bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TextField(
              onChanged: (v) =>
                  setState(() => searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari paket...',
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
          // Konten utama
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .orderBy('urutan')
                  .snapshots(),
              builder: (context, catSnap) {
                if (!catSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = catSnap.data!.docs
                    .map(_KategoriModel.fromDoc)
                    .toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('packages')
                      .snapshots(),
                  builder: (context, pkgSnap) {
                    if (!pkgSnap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    // Filter berdasarkan searchQuery
                    final allDocs = pkgSnap.data!.docs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final name =
                          (d['name'] ?? '').toString().toLowerCase();
                      return name.contains(searchQuery);
                    }).toList();

                    // Urutkan sesuai urutan kategori
                    final catIds =
                        categories.map((c) => c.id).toList();

                    allDocs.sort((a, b) {
                      final da = a.data() as Map<String, dynamic>;
                      final db = b.data() as Map<String, dynamic>;
                      final ta = (da['type'] ?? '')
                          .toString()
                          .toLowerCase();
                      final tb = (db['type'] ?? '')
                          .toString()
                          .toLowerCase();
                      final oa = catIds.indexOf(ta);
                      final ob = catIds.indexOf(tb);
                      final ia = oa < 0 ? 99 : oa;
                      final ib = ob < 0 ? 99 : ob;
                      if (ia != ib) return ia.compareTo(ib);
                      return (da['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .compareTo(
                              (db['name'] ?? '').toString().toLowerCase());
                    });

                    if (allDocs.isEmpty) {
                      return Center(
                        child: Text('Tidak ada paket 😢',
                            style: GoogleFonts.poppins()),
                      );
                    }

                    // Kelompokkan per kategori
                    final Map<String, List<QueryDocumentSnapshot>>
                        grouped = {};
                    for (final doc in allDocs) {
                      final type = ((doc.data()
                                  as Map<String, dynamic>)['type'] ??
                              '')
                          .toString()
                          .toLowerCase();
                      grouped.putIfAbsent(type, () => []).add(doc);
                    }

                    // Section sesuai urutan kategori
                    final sections = [
                      ...catIds.where((id) => grouped.containsKey(id)),
                      ...grouped.keys.where((k) => !catIds.contains(k)),
                    ];

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossCount =
                            width < 500 ? 1 : width < 900 ? 2 : 3;

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 100),
                          itemCount: sections.length,
                          itemBuilder: (context, si) {
                            final typeId = sections[si];
                            final items = grouped[typeId]!;
                            final katModel = categories
                                .where((c) => c.id == typeId)
                                .firstOrNull;
                            final label = katModel?.label ?? typeId;
                            final badgeBg = katModel?.colorBg ??
                                _primary.withOpacity(0.1);
                            final badgeText =
                                katModel?.colorText ?? _primary;
                            final stripColor =
                                katModel?.colorStrip ?? _primary;

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // ── SECTION HEADER ──
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 16, bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 5),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          label,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: badgeText,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                            height: 1,
                                            color: Colors.black12),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${items.length} paket',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _textSoft),
                                      ),
                                    ],
                                  ),
                                ),

                                // ── GRID KARTU ──
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: 220,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, ii) {
                                    final doc = items[ii];
                                    final d = doc.data()
                                        as Map<String, dynamic>;

                                    final packageId = doc.id;
                                    final name =
                                        d['name']?.toString() ?? '';
                                    final price = _toInt(d['price']);
                                    final minOrder =
                                        _toInt(d['min_order']);
                                    final leadTime =
                                        _toInt(d['lead_time']);
                                    final type =
                                        d['type']?.toString() ?? '';
                                    final menu =
                                        List<String>.from(
                                            d['menu_items'] ?? []);

                                    final description =
                                        menu.isNotEmpty
                                            ? "Termasuk: ${menu.join(', ')}\n\nMinimal order: $minOrder porsi\nLead time: $leadTime hari"
                                            : (d['description'] ?? '')
                                                .toString();

                                    return GestureDetector(
                                      onTap: () => Navigator.push(
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
                                      ),
                                      child: _menuCard(
                                        name: name,
                                        price: price,
                                        minOrder: minOrder,
                                        leadTime: leadTime,
                                        menuItems: menu,
                                        label: label,
                                        badgeBg: badgeBg,
                                        badgeText: badgeText,
                                        stripColor: stripColor,
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
                                ),

                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVBAR dengan ikon keranjang + badge
  // ============================================================
  Widget _buildNavbar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 30, vertical: 11.5),
      color: _primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Katalog Menu',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
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
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 26),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const KeranjangPage()),
                    ),
                  ),
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
  // CARD PAKET — desain mengikuti admin_paket_page
  // ============================================================
  Widget _menuCard({
    required String name,
    required int price,
    required int minOrder,
    required int leadTime,
    required List<String> menuItems,
    required String label,
    required Color badgeBg,
    required Color badgeText,
    required Color stripColor,
    required VoidCallback onAddToCart,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top strip warna kategori
          Container(height: 4, color: stripColor),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge kategori
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Nama + harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatRupiah(price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Container(height: 0.5, color: Colors.black12),
                  const SizedBox(height: 8),

                  // Min pesanan + persiapan
                  Row(
                    children: [
                      _statItem('Min. pesan', '$minOrder porsi'),
                      const SizedBox(width: 16),
                      _statItem('Persiapan', '$leadTime hari'),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Chip menu items
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: menuItems
                            .map((e) => _menuChip(e))
                            .toList(),
                      ),
                    ),
                  ),

                  // Footer: tombol tambah ke keranjang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Keranjang',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: _textSoft)),
        const SizedBox(height: 1),
        Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _menuChip(String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10, color: Color(0xFF555555)),
      ),
    );
  }
}