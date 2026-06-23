import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  int _selectedTab = 0;

  String formatRupiah(dynamic number) {
    final value = int.tryParse(number.toString()) ?? 0;

    return "Rp ${value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  Future<void> _printInvoice(
    Map<String, dynamic> order,
  ) async {

    final pdf = pw.Document();

    final items = (order['items'] as List<dynamic>? ?? []);

    final orderId = order['order_id']?.toString() ?? '';

    final shortOrderId = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    final namaPemesan = order['nama_pemesan'] ?? '-';
    final noTelpon = order['no_telpon'] ?? '-';
    final alamat = order['alamat'] ?? '-';
    final grandTotal = order['grand_total'] ?? 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // Header
              pw.Center(
                child: pw.Text(
                  'DAPUR ATIK',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.Center(
                child: pw.Text(
                  'Invoice Pesanan',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Info Pesanan
              _buildPdfRow('No. Order', 'ORD-$shortOrderId'),
              _buildPdfRow('Nama', namaPemesan),
              _buildPdfRow('No. Telpon', noTelpon),
              _buildPdfRow('Alamat', alamat),
              _buildPdfRow('WA Pemilik', '0813-1583-7240'),

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // List Item
              pw.Text(
                'Pesanan',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              pw.SizedBox(height: 8),

              ...items.map((item) {
                final itemMap = item as Map<String, dynamic>;
                final name = itemMap['name'] ?? '-';
                final qty = itemMap['qty'] ?? 0;
                final price = itemMap['price'] ?? 0;
                final total = itemMap['total_price'] ?? 0;
                final tanggalAcara = itemMap['tanggal_acara'];

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [

                      pw.Text(
                        name,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),

                      pw.Text('$qty × Rp ${_formatNumber(price)}'),

                      if (tanggalAcara != null)
                      pw.Text(
                        () {
                          final date = (tanggalAcara as Timestamp).toDate();
                          return 'Tanggal Acara: ${date.day}/${date.month}/${date.year}';
                        }(),
                        style: const pw.TextStyle(color: PdfColors.grey),
                      ),
                      pw.Text('Rp ${_formatNumber(total)}'),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(),
              pw.SizedBox(height: 4),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rp ${_formatNumber(grandTotal)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              pw.Center(
                child: pw.Text(
                  'Terima kasih sudah memesan!',
                  style: const pw.TextStyle(color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // Helper baris PDF
  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(label),
          ),
          pw.Text(': '),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  // Helper format angka
  String _formatNumber(dynamic number) {
    final n = (number is int) ? number : (number as num).toInt();
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            width: 90,
            child: Text(
              title,
              style: GoogleFonts.poppins(),
            ),
          ),

          Text(
            ": ",
            style: GoogleFonts.poppins(),
          ),

          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  void _showOrderDetail(Map<String, dynamic> order) {

    final items =
        (order['items'] as List<dynamic>? ?? []);

    final orderId =
        order['order_id']?.toString() ?? '';

    final shortOrderId =
        orderId.length >= 8
            ? orderId.substring(0, 8).toUpperCase()
            : orderId.toUpperCase();

    final namaPemesan =
        order['nama_pemesan'] ?? '-';

    final noTelpon =
        order['no_telpon'] ?? '-';

    final alamat =
        order['alamat'] ?? '-';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: Center(
            child: Text(
              "Invoice Pesanan",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Divider(),

                  buildInfoRow(
                    "No. Order",
                    "ORD-$shortOrderId",
                  ),

                  const SizedBox(height: 4),

                  buildInfoRow(
                    "Nama",
                    namaPemesan,
                  ),

                  const SizedBox(height: 4),

                  buildInfoRow(
                    "No. Telpon",
                    noTelpon,
                  ),

                  const SizedBox(height: 4),

                  buildInfoRow(
                    "Alamat",
                    alamat,
                  ),

                  const SizedBox(height: 4),

                  GestureDetector(
                    onTap: () async {
                      final Uri url = Uri.parse('https://wa.me/6281315837240');
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    child: buildInfoRow("WA Pemilik", "0813-1583-7240 (Tap untuk chat)"),
                  ),

                  const SizedBox(height: 12),

                  const Divider(),

                  Text(
                    "Pesanan",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...items.map((item) {

                    final qty =
                        item['qty'] ?? 0;

                    final price =
                        item['price'] ?? 0;

                    final total =
                        item['total_price'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EFE6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            item['name'] ?? '',
                            style:
                                GoogleFonts.poppins(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            "$qty × ${formatRupiah(price)}",
                            style: GoogleFonts.poppins(),
                          ),

                          if (item['tanggal_acara'] != null)
                          Text(
                            "Tanggal Acara : "
                            "${(item['tanggal_acara'] as Timestamp).toDate().day}/"
                            "${(item['tanggal_acara'] as Timestamp).toDate().month}/"
                            "${(item['tanggal_acara'] as Timestamp).toDate().year}",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),

                          Text(
                            "${formatRupiah(total)}",
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const Divider(),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [

                      Text(
                        "TOTAL",
                        style:
                            GoogleFonts.poppins(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        formatRupiah(order['grand_total']),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          actions: [

            if ((order['status'] ?? '')
                .toString()
                .toLowerCase()
                .trim() == 'selesai')

              TextButton.icon(
                onPressed: () {
                  _printInvoice(order);
                },
                icon: const Icon(Icons.print),
                label: const Text(
                  "Cetak PDF",
                ),
              ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Tutup",
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),
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
            color: const Color(0xFFF5E6DA),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

          const SizedBox(height: 12),

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

            final orderStatus =
              data['status']
                  ?.toString()
                  .toLowerCase()
                  .trim() ?? '';

            if (status == 'menunggu') {
              return orderStatus.contains('menunggu');
            }

          return orderStatus.contains(status);
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

    final items =
    (order['items'] as List<dynamic>? ?? []);

    final firstItem =
        items.isNotEmpty
            ? items[0] as Map<String, dynamic>
            : {};

    final itemNames =
        items.map((e) => e['name'].toString()).toList();

    final Timestamp? tanggalAcara =
    firstItem['tanggal_acara'] as Timestamp?;

    final String tanggalAcaraText =
        tanggalAcara != null
            ? "${tanggalAcara.toDate().day}/${tanggalAcara.toDate().month}/${tanggalAcara.toDate().year}"
            : "-";

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
          onTap: () {
            _showOrderDetail(order);
          },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
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
                    "Acara: $tanggalAcaraText",
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

              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  firstItem['name'] ?? 'Produk',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (itemNames.length > 1)
                      Text(
                        "+ ${itemNames.length - 1} paket lainnya",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                    Text(
                      "${firstItem['qty'] ?? 0} Paket",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                      ),
                    ),

                  ],
                ),
              ],
            ),

              const Divider(),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    formatRupiah(order['grand_total']),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
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