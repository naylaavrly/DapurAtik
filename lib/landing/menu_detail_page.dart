import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuDetailPage extends StatefulWidget {  
  final String packageId;
  final String name;
  final int price;
  final String description;
  final String type;
  final int leadTime;
  final int minOrder;

  const MenuDetailPage({
    super.key,
    required this.packageId,
    required this.name,
    required this.price,
    required this.description,
    required this.type,
    required this.leadTime,
    required this.minOrder,
  });

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {

  // ============================================================
  // KONSTANTA WARNA
  // ============================================================
  static const Color _primary = Color(0xFF61100D);

  // ============================================================
  // STATE: loading saat proses tambah ke keranjang berlangsung
  // ============================================================
  bool _isAddingToCart = false;

  // ============================================================
  // HELPER: format angka ke Rupiah (Rp 1.000.000)
  // ============================================================
  String formatRupiah(int number) {
    return "Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  // ============================================================
  // HELPER: tampilkan snackbar dengan warna sesuai kondisi
  // ============================================================
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? Colors.red[700] : _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================
  // FUNGSI: tambahkan paket ke collection 'carts' di Firestore
  //
  //   Alur:
  //   1. Cek user sudah login
  //   2. Cek apakah paket ini sudah ada di keranjang user
  //      - Sudah ada → increment qty + update total_price
  //      - Belum ada → buat dokumen baru di 'carts'
  //   3. Tampilkan snackbar sukses / gagal
  // ============================================================
  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;

    // Validasi: harus sudah login
    if (user == null) {
      _showSnack('Silakan login terlebih dahulu.', isError: true);
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final cartsRef = FirebaseFirestore.instance.collection('carts');

      // Cek apakah paket ini sudah ada di keranjang user
      final existing = await cartsRef
          .where('user_id', isEqualTo: user.uid)
          .where('package_id', isEqualTo: widget.packageId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // --------------------------------------------------------
        // SUDAH ADA: tambah qty sebesar 1 dan update total_price
        // --------------------------------------------------------
        final doc = existing.docs.first;
        final currentQty = (doc.data()['qty'] as num?)?.toInt() ?? 1;
        final newQty = currentQty + 1;
        await cartsRef.doc(doc.id).update({
          'qty': newQty,
          'total_price': newQty * widget.price,
        });
        _showSnack('"${widget.name}" ditambahkan ke keranjang 🛒');
      } else {
        // --------------------------------------------------------
        // BELUM ADA: buat dokumen baru di collection 'carts'
        // Field disesuaikan dengan yang dibaca di user_cart.dart
        // --------------------------------------------------------
        await cartsRef.add({
          'user_id': user.uid,
          'package_id': widget.packageId,
          'name': widget.name,
          'price': widget.price,
          'qty': 1,
          'total_price': widget.price,
          'type': widget.type,
          'lead_time': widget.leadTime,
          'min_order': widget.minOrder,
          'created_at': FieldValue.serverTimestamp(),
        });
        _showSnack('"${widget.name}" ditambahkan ke keranjang 🛒');
      }
    } catch (e) {
      _showSnack('Gagal menambahkan ke keranjang. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  // ============================================================
  // BUILD: tampilan halaman detail paket
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),
      body: Column(
        children: [

          // Navbar dengan tombol back
          _buildNavbar(context),

          // -------------------------------------------------------
          // KONTEN UTAMA: ikon, nama, harga, info, deskripsi, tombol
          // -------------------------------------------------------
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Nama paket
                  Text(
                    widget.name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Harga paket
                  Text(
                    formatRupiah(widget.price),
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  // Info min order (kalau ada)
                  if (widget.minOrder > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Minimal order: ${widget.minOrder} porsi',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),

                  // Info lead time (kalau ada)
                  if (widget.leadTime > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 13, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Pesan minimal H-${widget.leadTime} sebelum acara',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),

                  // -------------------------------------------------------
                  // DESKRIPSI: isi paket yang di-generate dari menu_items
                  // -------------------------------------------------------
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.description.isEmpty
                            ? "Paket lezat dengan cita rasa terbaik 🍽️"
                            : widget.description,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          height: 1.6,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -------------------------------------------------------
                  // TOMBOL MASUKKAN KERANJANG
                  // Loading state: tampilkan spinner + teks "Menambahkan..."
                  // -------------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: _primary.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isAddingToCart ? null : _addToCart,
                      icon: _isAddingToCart
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.shopping_cart_outlined,
                              color: Colors.white, size: 18),
                      label: Text(
                        _isAddingToCart ? "Menambahkan..." : "Masukkan Keranjang",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: navbar — padding horizontal: 30 (sama dengan user_cart)
  //         agar lebar navbar tidak terlalu besar
  // ============================================================
  Widget _buildNavbar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20), 
      color: _primary,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            "Detail Paket",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}