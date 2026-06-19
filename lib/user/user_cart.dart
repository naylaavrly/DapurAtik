import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final Map<String, DateTime?> _selectedDates = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  String _namaPemesan = '';
  String _noTelpon = '';

  static const Color _primary = Color(0xFF61100D);
  static const Color _bgColor = Color(0xFFF5E6DA);

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

  String _labelMinDate(String type, int? leadTime) {
    if (leadTime != null && leadTime > 0) return 'min H-$leadTime hari';
    if (type.toLowerCase() == 'hajatan') return 'min H-3 bulan';
    return 'min H-1';
  }

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

      if (selisihHari < minHari) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Paket ini hanya bisa dipesan min H-$minHari dari tanggal acara.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return; // tanggal tidak disimpan
      }

      setState(() => _selectedDates[docId] = picked);
    }
  }

  void _showDataDiriDialog(VoidCallback onSaved) {
    final nameCtrl = TextEditingController(text: _namaPemesan);
    final telponCtrl = TextEditingController(text: _noTelpon);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Data Diri',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Pesanan Atas Nama',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: _primary),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telponCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'No Telepon',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: _primary),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _namaPemesan = nameCtrl.text.trim();
                _noTelpon = telponCtrl.text.trim();
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

  void _doCheckout(List<QueryDocumentSnapshot> carts) async {
    if (carts.isEmpty) {
      _showSnack('Keranjang kosong.');
      return;
    }

    for (var doc in carts) {
      if (_selectedDates[doc.id] == null) {
        final data = doc.data() as Map<String, dynamic>;
        _showSnack('Pilih tanggal acara untuk "${data['name'] ?? ''}" terlebih dahulu.');
        return;
      }
    }

    if (_namaPemesan.isEmpty || _noTelpon.isEmpty) {
      _showDataDiriDialog(() => _doCheckout(carts));
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    int grandTotal = 0;
    List<Map<String, dynamic>> items = [];

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

    final orderRef = FirebaseFirestore.instance.collection('orders').doc();

    await orderRef.set({
      'order_id': orderRef.id,
      'user_id': user.uid,
      'nama_pemesan': _namaPemesan,
      'no_telpon': _noTelpon,
      'items': items,
      'grand_total': grandTotal,
      'status': 'Menunggu Konfirmasi',
      'created_at': Timestamp.now(),
    });

    for (var doc in carts) {
      await FirebaseFirestore.instance.collection('carts').doc(doc.id).delete();
    }

    setState(() {
      _selectedDates.clear();
      _qtyControllers.forEach((_, c) => c.dispose());
      _qtyControllers.clear();
    });

    if (mounted) {
      _showInvoice(orderId: orderRef.id, items: items, grandTotal: grandTotal);
    }
  }

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
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 50),
                    const SizedBox(height: 8),
                    Text('Pesanan Berhasil!',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Invoice Pemesanan',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(height: 24),
              _invoiceRow('No. Order', orderId.substring(0, 8).toUpperCase()),
              _invoiceRow('Nama', _namaPemesan),
              _invoiceRow('No. Telpon', _noTelpon),
              const Divider(height: 20),
              Text('Pesanan:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ...items.map((item) {
                final tgl = (item['tanggal_acara'] as Timestamp).toDate();
                final tglStr =
                    '${tgl.day.toString().padLeft(2, '0')}/${tgl.month.toString().padLeft(2, '0')}/${tgl.year}';
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  Text(formatRupiah(grandTotal),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: _primary,
                          fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Status: Menunggu Konfirmasi',
                    style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
              const SizedBox(height: 16),
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
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    for (var c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          // 🔥 NAVBAR dengan back button
          _buildNavbar(context),

          Expanded(
            child: user == null
                ? const Center(child: Text('User belum login'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('carts')
                        // ✅ Filter HANYA item milik user yang sedang login
                        .where('user_id', isEqualTo: user.uid)
                        // .orderBy('created_at', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final carts = snapshot.data!.docs;

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

                      int grandTotal = 0;
                      for (var doc in carts) {
                        final data = doc.data() as Map<String, dynamic>;
                        grandTotal += _toInt(data['total_price']);
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              itemCount: carts.length,
                              itemBuilder: (context, index) {
                                final doc = carts[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final docId = doc.id;

                                final String name = data['name'] ?? '';
                                final int price = _toInt(data['price']);
                                final String type = data['type'] ?? '';
                                final int? leadTime = data['lead_time'] != null
                                    ? _toInt(data['lead_time'])
                                    : null;
                                final int qty = _toInt(data['qty']);
                                final int minOrder = _toInt(data['min_order']);

                                // Init controller qty
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
                                final String? tglStr = tgl != null
                                    ? '${tgl.day.toString().padLeft(2, '0')}/${tgl.month.toString().padLeft(2, '0')}/${tgl.year}'
                                    : null;

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
                                      // Row: Info + Hapus
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icon pengganti gambar
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
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                    style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13)),
                                                const SizedBox(height: 2),
                                                Text(
                                                    minOrder > 0
                                                        ? '${formatRupiah(price)} / $minOrder porsi'
                                                        : '${formatRupiah(price)} / porsi',
                                                    style: GoogleFonts.poppins(
                                                        color: _primary,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600)),
                                                if (type.isNotEmpty)
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 2),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '⏱ ${_labelMinDate(type, leadTime)} sebelum acara',
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          color: Colors.orange[800],
                                                          fontWeight: FontWeight.w500),
                                                    ),
                                                  ),
                                                Text(
                                                    'Subtotal: ${formatRupiah(_toInt(data['total_price']))}',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ),
                                          // Tombol hapus
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

                                      // Qty
                                      Row(
                                        children: [
                                          Text('Jumlah:',
                                              style: GoogleFonts.poppins(fontSize: 12)),
                                          const SizedBox(width: 10),
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
                                                    const EdgeInsets.symmetric(vertical: 6),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  borderSide:
                                                      const BorderSide(color: Colors.grey),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  borderSide:
                                                      const BorderSide(color: _primary),
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

                                      // Pilih tanggal
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

                          // Bottom: Total + Data Diri + Checkout
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
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: _primary),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.person_outline,
                                        color: _primary, size: 18),
                                    label: Text(
                                      _namaPemesan.isEmpty
                                          ? 'Isi Data Diri'
                                          : 'Data Diri: $_namaPemesan',
                                      style:
                                          GoogleFonts.poppins(color: _primary, fontSize: 13),
                                    ),
                                    onPressed: () => _showDataDiriDialog(() {}),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ================= NAVBAR =================
  Widget _buildNavbar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      color: _primary,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
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
