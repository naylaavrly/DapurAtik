import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// IMPORT halaman user_home
// ============================================================
import 'user_home.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {

  // ============================================================
  // STATE: menyimpan tanggal acara & controller qty per item cart
  // ============================================================
  final Map<String, DateTime?> _selectedDates = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  // ============================================================
  // STATE: data diri pemesan (nama, telepon, alamat)
  // ============================================================
  String _namaPemesan = '';
  String _noTelpon = '';
  String _alamat = '';

  // ============================================================
  // KONSTANTA WARNA
  // ============================================================
  static const Color _primary = Color(0xFF61100D);
  static const Color _bgColor = Color(0xFFF5E6DA);

  // ============================================================
  // HELPER: format angka ke format Rupiah (Rp 1.000.000)
  // ============================================================
  String formatRupiah(int number) {
    return "Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  // ============================================================
  // HELPER: konversi dynamic (int/double/String) ke int
  // ============================================================
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ============================================================
  // HELPER: format DateTime ke string DD/MM/YYYY
  // ============================================================
  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ============================================================
  // HELPER: hitung tanggal minimum pemesanan berdasarkan
  //         lead_time dari Firestore, atau fallback ke tipe paket
  // ============================================================
  DateTime _minDate(String type, int? leadTime) {
    final now = DateTime.now();
    if (leadTime != null && leadTime > 0) {
      return now.add(Duration(days: leadTime));
    }
    if (type.toLowerCase() == 'hajatan') {
      return now.add(const Duration(days: 90));
    }
    return now.add(const Duration(days: 1));
  }

  // ============================================================
  // HELPER: teks label minimum pemesanan untuk ditampilkan di card
  // ============================================================
  String _labelMinDate(String type, int? leadTime) {
    if (leadTime != null && leadTime > 0) return 'min H-$leadTime hari';
    if (type.toLowerCase() == 'hajatan') return 'min H-3 bulan';
    return 'min H-1';
  }

  // ============================================================
  // FUNGSI: buka date picker untuk memilih tanggal acara
  //         validasi tanggal agar tidak kurang dari minDate
  // ============================================================
  Future<void> _pickDate(String docId, String type, int? leadTime) async {
    final minDate = _minDate(type, leadTime);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final pickedOnly = DateTime(picked.year, picked.month, picked.day);
      final selisihHari = pickedOnly.difference(todayOnly).inDays;
      final minHari = minDate.difference(todayOnly).inDays;

      // --------------------------------------------------------
      // Validasi: tampilkan dialog error jika tanggal terlalu dekat
      // --------------------------------------------------------
      if (selisihHari < minHari) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Tanggal Tidak Valid',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Pemesanan harus dilakukan minimal H-$minHari sebelum tanggal acara.\n\n'
                'Tanggal acara paling cepat:\n📅 ${_formatDate(minDate)}',
                style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Mengerti',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Simpan tanggal yang dipilih ke state
      setState(() => _selectedDates[docId] = picked);
    }
  }

  // ============================================================
  // FUNGSI: buka dialog data diri, prefill dari state atau Firestore
  // ============================================================
  Future<void> _openDataDiriDialog(VoidCallback onSaved) async {
    final user = FirebaseAuth.instance.currentUser;

    String prefillName = _namaPemesan;
    String prefillPhone = _noTelpon;
    String prefillAlamat = _alamat;

    // Kalau belum ada data di state, fetch dari collection 'users' di Firestore
    if (prefillName.isEmpty && user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          prefillName = data['name']?.toString() ?? '';
          prefillPhone = data['phone']?.toString() ?? '';
          prefillAlamat = data['address']?.toString() ?? '';
        }
      } catch (_) {}
    }

    if (mounted) {
      _showDataDiriDialog(onSaved,
          initName: prefillName,
          initPhone: prefillPhone,
          initAlamat: prefillAlamat);
    }
  }

  // ============================================================
  // WIDGET DIALOG: form isian data diri pemesan
  // ============================================================
  void _showDataDiriDialog(
    VoidCallback onSaved, {
    String initName = '',
    String initPhone = '',
    String initAlamat = '',
  }) {
    final nameCtrl = TextEditingController(text: initName);
    final telponCtrl = TextEditingController(text: initPhone);
    final alamatCtrl = TextEditingController(text: initAlamat);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Data Diri',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Field nama pemesan
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Pemesan',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Field nomor telepon (hanya angka)
              TextField(
                controller: telponCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'No Telepon',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Field alamat pengiriman (multi-line)
              TextField(
                controller: alamatCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Alamat Pengiriman',
                  alignLabelWithHint: true,
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Tombol batal — tutup dialog tanpa menyimpan
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          // Tombol simpan — update state lalu jalankan callback
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _namaPemesan = nameCtrl.text.trim();
                _noTelpon = telponCtrl.text.trim();
                _alamat = alamatCtrl.text.trim();
              });
              Navigator.pop(ctx);
              onSaved();
            },
            child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FUNGSI: proses checkout
  //   1. Validasi semua item sudah punya tanggal acara
  //   2. Pastikan data diri sudah terisi
  //   3. Simpan order ke collection 'orders' di Firestore
  //   4. Hapus semua item dari collection 'carts'
  //   5. Tampilkan invoice
  // ============================================================
  void _doCheckout(List<QueryDocumentSnapshot> carts) async {
    // Validasi keranjang tidak kosong
    if (carts.isEmpty) {
      _showSnack('Keranjang kosong.');
      return;
    }

    // Validasi semua item sudah pilih tanggal acara
    for (var doc in carts) {
      if (_selectedDates[doc.id] == null) {
        final data = doc.data() as Map<String, dynamic>;
        _showSnack(
            'Pilih tanggal acara untuk "${data['name'] ?? ''}" terlebih dahulu.');
        return;
      }
    }

    // Validasi data diri sudah diisi — kalau belum, buka dialog dulu
    if (_namaPemesan.isEmpty || _noTelpon.isEmpty || _alamat.isEmpty) {
      await _openDataDiriDialog(() => _doCheckout(carts));
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    int grandTotal = 0;
    List<Map<String, dynamic>> items = [];

    // Susun list item pesanan dari data cart
    for (var doc in carts) {
      final data = doc.data() as Map<String, dynamic>;
      final int qty = _toInt(data['qty']);
      final int price = _toInt(data['price']);
      final int totalPrice = qty * price;
      grandTotal += totalPrice;

      items.add({
        'package_id': data['package_id'] ?? '',
        'name': data['name'] ?? '',
        'qty': qty,
        'price': price,
        'total_price': totalPrice,
        'type': data['type'] ?? '',
        'tanggal_acara': Timestamp.fromDate(_selectedDates[doc.id]!),
      });
    }

    // Simpan dokumen order baru ke Firestore
    final orderRef = FirebaseFirestore.instance.collection('orders').doc();
    await orderRef.set({
      'order_id': orderRef.id,
      'user_id': user.uid,
      'nama_pemesan': _namaPemesan,
      'no_telpon': _noTelpon,
      'alamat': _alamat,
      'items': items,
      'grand_total': grandTotal,
      'status': 'Menunggu Konfirmasi',
      'created_at': Timestamp.now(),
    });

    // Hapus semua item cart setelah order tersimpan
    for (var doc in carts) {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(doc.id)
          .delete();
    }

    // Reset state tanggal dan qty controller
    setState(() {
      _selectedDates.clear();
      _qtyControllers.forEach((_, c) => c.dispose());
      _qtyControllers.clear();
    });

    // Tampilkan dialog invoice
    if (mounted) {
      _showInvoice(orderId: orderRef.id, items: items, grandTotal: grandTotal);
    }
  }

  // ============================================================
  // WIDGET DIALOG: invoice ringkasan pesanan setelah checkout
  // ============================================================
  void _showInvoice({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required int grandTotal,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header invoice — ikon centang + judul
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 50),
                    const SizedBox(height: 8),
                    Text('Pesanan Berhasil!',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Invoice Pemesanan',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(height: 24),

              // Info pemesan
              _invoiceRow('No. Order', orderId.substring(0, 8).toUpperCase()),
              _invoiceRow('Nama', _namaPemesan),
              _invoiceRow('No. Telpon', _noTelpon),
              _invoiceRow('Alamat', _alamat),
              const Divider(height: 20),

              // Daftar item yang dipesan
              Text('Pesanan:',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ...items.map((item) {
                final tgl = (item['tanggal_acara'] as Timestamp).toDate();
                final tglStr = _formatDate(tgl);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${item['qty']}x ${formatRupiah(item['price'])}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[700])),
                        Text('Tanggal acara: $tglStr',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[700])),
                        Text(formatRupiah(item['total_price']),
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _primary)),
                      ],
                    ),
                  ),
                );
              }),

              const Divider(height: 20),

              // Grand total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  Text(formatRupiah(grandTotal),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: _primary,
                          fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),

              // Status order
              Center(
                child: Text('Status: Menunggu Konfirmasi',
                    style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
              const SizedBox(height: 16),

              // Tombol selesai — tutup dialog invoice
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Selesai',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET HELPER: baris label-value untuk invoice
  // ============================================================
  Widget _invoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ),
          Text(': ',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER: tampilkan snackbar pesan singkat
  // ============================================================
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ============================================================
  // DISPOSE: bersihkan semua TextEditingController qty
  // ============================================================
  @override
  void dispose() {
    for (var c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // BUILD: halaman utama keranjang
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          // Navbar dengan tombol back ke UserHomePage
          _buildNavbar(context),

          Expanded(
            child: user == null
                ? const Center(child: Text('User belum login'))
                : StreamBuilder<QuerySnapshot>(
                    // ------------------------------------------------
                    // STREAM: ambil item cart milik user yang sedang login
                    // dari collection 'carts' di Firestore
                    // ------------------------------------------------
                    stream: FirebaseFirestore.instance
                        .collection('carts')
                        .where('user_id', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Tampilkan loading saat data belum siap
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final carts = snapshot.data!.docs;

                      // ------------------------------------------------
                      // STATE KOSONG: tampilkan ilustrasi keranjang kosong
                      // ------------------------------------------------
                      if (carts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 70, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('Keranjang masih kosong',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey[500], fontSize: 14)),
                            ],
                          ),
                        );
                      }

                      // Hitung grand total dari semua item cart
                      int grandTotal = 0;
                      for (var doc in carts) {
                        final data = doc.data() as Map<String, dynamic>;
                        grandTotal += _toInt(data['total_price']);
                      }

                      return Column(
                        children: [
                          // ----------------------------------------
                          // LIST: daftar card item di keranjang
                          // ----------------------------------------
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              itemCount: carts.length,
                              itemBuilder: (context, index) {
                                final doc = carts[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final docId = doc.id;

                                // Ambil field-field dari dokumen cart
                                final String name = data['name'] ?? '';
                                final int price = _toInt(data['price']);
                                final String type = data['type'] ?? '';
                                final int? leadTime = data['lead_time'] != null
                                    ? _toInt(data['lead_time'])
                                    : null;
                                final int qty = _toInt(data['qty']);
                                final int minOrder = _toInt(data['min_order']);

                                // ----------------------------------------
                                // INISIALISASI qty controller per item
                                // supaya TextField qty sinkron dengan Firestore
                                // ----------------------------------------
                                if (!_qtyControllers.containsKey(docId)) {
                                  _qtyControllers[docId] =
                                      TextEditingController(text: '$qty');
                                } else if (_qtyControllers[docId]!.text != '$qty') {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted && _qtyControllers.containsKey(docId)) {
                                      _qtyControllers[docId]!.text = '$qty';
                                    }
                                  });
                                }

                                final DateTime? tgl = _selectedDates[docId];
                                final String? tglStr =
                                    tgl != null ? _formatDate(tgl) : null;

                                // ----------------------------------------
                                // CARD: tampilan satu item di keranjang
                                // ----------------------------------------
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 8,
                                        color: Colors.black.withOpacity(0.05),
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Baris atas: ikon + info paket + tombol hapus
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Ikon pengganti gambar (packages tidak punya image)
                                          Container(
                                            width: 75,
                                            height: 75,
                                            decoration: BoxDecoration(
                                              color: _primary.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.restaurant_menu,
                                                  color: _primary, size: 28),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Info nama, harga, tipe, subtotal
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Nama paket
                                                Text(name,
                                                    style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13)),
                                                const SizedBox(height: 2),
                                                // Harga per porsi / min order
                                                Text(
                                                    minOrder > 0
                                                        ? '${formatRupiah(price)} / $minOrder porsi'
                                                        : '${formatRupiah(price)} / porsi',
                                                    style: GoogleFonts.poppins(
                                                        color: _primary,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600)),
                                                // Badge info min pemesanan
                                                if (type.isNotEmpty)
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 2),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '⏱ ${_labelMinDate(type, leadTime)} sebelum acara',
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          color: Colors.orange[800],
                                                          fontWeight: FontWeight.w500),
                                                    ),
                                                  ),
                                                // Subtotal item ini
                                                Text(
                                                    'Subtotal: ${formatRupiah(_toInt(data['total_price']))}',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ),
                                          // Tombol hapus item dari cart
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                color: Colors.red, size: 20),
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection('carts')
                                                  .doc(docId)
                                                  .delete();
                                              setState(() {
                                                _selectedDates.remove(docId);
                                                _qtyControllers[docId]?.dispose();
                                                _qtyControllers.remove(docId);
                                              });
                                            },
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // ----------------------------------------
                                      // KONTROL QTY: tombol -, input angka, tombol +
                                      // ----------------------------------------
                                      Row(
                                        children: [
                                          Text('Jumlah:',
                                              style: GoogleFonts.poppins(fontSize: 12)),
                                          const SizedBox(width: 10),
                                          // Tombol kurangi qty
                                          _qtyBtn('-', () async {
                                            if (qty > 1) {
                                              await FirebaseFirestore.instance
                                                  .collection('carts')
                                                  .doc(docId)
                                                  .update({
                                                'qty': qty - 1,
                                                'total_price': (qty - 1) * price,
                                              });
                                            }
                                          }),
                                          const SizedBox(width: 6),
                                          // TextField input qty langsung
                                          SizedBox(
                                            width: 50,
                                            height: 32,
                                            child: TextField(
                                              controller: _qtyControllers[docId],
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly
                                              ],
                                              style: GoogleFonts.poppins(fontSize: 13),
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: const BorderSide(
                                                      color: Colors.grey),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: const BorderSide(
                                                      color: _primary),
                                                ),
                                              ),
                                              onSubmitted: (val) async {
                                                int newQty = int.tryParse(val) ?? 1;
                                                if (newQty < 1) newQty = 1;
                                                await FirebaseFirestore.instance
                                                    .collection('carts')
                                                    .doc(docId)
                                                    .update({
                                                  'qty': newQty,
                                                  'total_price': newQty * price,
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Tombol tambah qty
                                          _qtyBtn('+', () async {
                                            await FirebaseFirestore.instance
                                                .collection('carts')
                                                .doc(docId)
                                                .update({
                                              'qty': qty + 1,
                                              'total_price': (qty + 1) * price,
                                            });
                                          }),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // ----------------------------------------
                                      // PILIH TANGGAL ACARA: tekan untuk buka date picker
                                      // ----------------------------------------
                                      GestureDetector(
                                        onTap: () => _pickDate(docId, type, leadTime),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: tgl != null
                                                    ? _primary
                                                    : Colors.grey[400]!),
                                            borderRadius: BorderRadius.circular(10),
                                            color: tgl != null
                                                ? _primary.withOpacity(0.05)
                                                : Colors.white,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  size: 15,
                                                  color: tgl != null
                                                      ? _primary
                                                      : Colors.grey[500]),
                                              const SizedBox(width: 8),
                                              Text(
                                                tgl != null
                                                    ? 'Tanggal Acara: $tglStr'
                                                    : 'Pilih Tanggal Acara',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: tgl != null
                                                      ? _primary
                                                      : Colors.grey[600],
                                                  fontWeight: tgl != null
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // ----------------------------------------
                          // BOTTOM BAR: total + tombol data diri + checkout
                          // ----------------------------------------
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(20)),
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 12,
                                    color: Colors.black12,
                                    offset: Offset(0, -3))
                              ],
                            ),
                            child: Column(
                              children: [
                                // Baris grand total
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Pesanan',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      formatRupiah(grandTotal),
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: _primary,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Tombol isi/lihat data diri pemesan
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: _primary),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.person_outline,
                                        color: _primary, size: 18),
                                    label: Text(
                                      _namaPemesan.isEmpty
                                          ? 'Isi Data Diri'
                                          : 'Data Diri: $_namaPemesan',
                                      style: GoogleFonts.poppins(
                                          color: _primary, fontSize: 13),
                                    ),
                                    onPressed: () => _openDataDiriDialog(() {}),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Tombol checkout — validasi lalu simpan order
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onPressed: () => _doCheckout(carts),
                                    child: Text('Checkout',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                  ),
                                ),
                              ],
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
  // WIDGET: navbar atas dengan tombol back ke UserHomePage
  // ============================================================
  Widget _buildNavbar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      color: _primary,
      child: Row(
        children: [
          // -------------------------------------------------------
          // TOMBOL BACK: navigasi ke UserHomePage (bukan pop)
          // pushReplacement agar halaman keranjang tidak menumpuk
          // di navigation stack
          // -------------------------------------------------------
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UserHome()),
              );
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            'Keranjang',
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

  // ============================================================
  // WIDGET HELPER: tombol bulat untuk tambah/kurang qty
  // ============================================================
  Widget _qtyBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}