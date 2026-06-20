import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// 🎨 DESIGN SYSTEM — sama persis dengan admin_paket_page
// ============================================================
const Color primary    = Color(0xFF7A1C1C);
const Color bgColor    = Color(0xFFF5E6DA);
const Color textSoft   = Color(0xFF8E8E8E);
const Color cardBg     = Colors.white;
const Color dividerClr = Color(0xFFEDEDED);

const Color colWarning   = Color(0xFFE65100);
const Color bgWarning    = Color(0xFFFFF3E0);
const Color colInfo      = Color(0xFF1565C0);
const Color bgInfo       = Color(0xFFE3F2FD);
const Color colSuccess   = Color(0xFF2E7D32);
const Color bgSuccess    = Color(0xFFE8F5E9);
const Color colCancelled = Color(0xFF616161);
const Color bgCancelled  = Color(0xFFF5F5F5);

// Status kanonis (sesuai user_cart.dart)
const String sMenunggu   = 'Menunggu Konfirmasi';
const String sDiproses   = 'Diproses';
const String sSelesai    = 'Selesai';
const String sDibatalkan = 'Dibatalkan';

const List<Map<String, String>> _tabs = [
  {'label': 'Semua',      'value': 'semua'},
  {'label': 'Menunggu',   'value': sMenunggu},
  {'label': 'Diproses',   'value': sDiproses},
  {'label': 'Selesai',    'value': sSelesai},
  {'label': 'Dibatalkan', 'value': sDibatalkan},
];

// ── Normalisasi status: case-insensitive + trim, biar tidak ada
// pesanan "hilang" cuma gara-gara beda kapital/spasi di Firestore.
String _normalizeStatus(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  if (s == sMenunggu.toLowerCase())   return sMenunggu;
  if (s == sDiproses.toLowerCase())   return sDiproses;
  if (s == sSelesai.toLowerCase())    return sSelesai;
  if (s == sDibatalkan.toLowerCase()) return sDibatalkan;
  return raw?.trim().isNotEmpty == true ? raw!.trim() : sMenunggu;
}

Map<String, dynamic> _statusCfg(String status) {
  switch (status) {
    case sMenunggu:
      return {'label': 'Menunggu', 'color': colWarning, 'bg': bgWarning, 'icon': Icons.hourglass_top_rounded};
    case sDiproses:
      return {'label': 'Diproses', 'color': colInfo, 'bg': bgInfo, 'icon': Icons.local_fire_department_rounded};
    case sSelesai:
      return {'label': 'Selesai', 'color': colSuccess, 'bg': bgSuccess, 'icon': Icons.check_circle_rounded};
    case sDibatalkan:
      return {'label': 'Dibatalkan', 'color': colCancelled, 'bg': bgCancelled, 'icon': Icons.cancel_rounded};
    default:
      return {'label': status, 'color': textSoft, 'bg': bgColor, 'icon': Icons.receipt_long_rounded};
  }
}

String _formatRp(int val) {
  final s = val.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp ${buf.toString()}';
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1)  return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

String _formatDate(DateTime dt) {
  const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ================= STYLE INPUT (sama dengan admin_paket_page) =================
InputDecoration inputStyle(String label) => InputDecoration(
  labelText: label,
  floatingLabelBehavior: FloatingLabelBehavior.always,
  filled: true,
  fillColor: const Color(0xFFF9F3EF),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.grey),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: primary, width: 2),
  ),
);

// ============================================================
// 📄 PAGE
// ============================================================
class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key});
  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> {
  String _filterStatus = 'semua';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ===== JUDUL (sama persis dengan admin_paket_page) =====
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Kelola Pesanan',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: _NotifBell(
                      onTap: () => setState(() => _filterStatus = sMenunggu),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ===== TOOLBAR: search =====
              TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: inputStyle('Cari nama atau ID pesanan...').copyWith(
                  prefixIcon: const Icon(Icons.search),
                ),
              ),

              const SizedBox(height: 14),

              // ===== STREAM UTAMA =====
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .orderBy('created_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: primary));
                    }

                    final allDocs = snapshot.data!.docs;
                    final allNormalized = allDocs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final status = _normalizeStatus(d['status'] as String?);
                      return _OrderEntry(doc: doc, data: d, status: status);
                    }).toList();

                    var filtered = allNormalized.where((e) {
                      final matchStatus = _filterStatus == 'semua' || e.status == _filterStatus;
                      final nama = (e.data['nama_pemesan'] ?? '').toString().toLowerCase();
                      final id = e.doc.id.toLowerCase();
                      final matchSearch = _search.isEmpty || nama.contains(_search) || id.contains(_search);
                      return matchStatus && matchSearch;
                    }).toList();

                    // Urutan "Semua": Menunggu Konfirmasi di atas, sisanya terbaru dulu.
                    if (_filterStatus == 'semua') {
                      filtered.sort((a, b) {
                        final aPending = a.status == sMenunggu;
                        final bPending = b.status == sMenunggu;
                        if (aPending != bPending) return aPending ? -1 : 1;
                        final aTs = (a.data['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
                        final bTs = (b.data['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
                        return bTs.compareTo(aTs);
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TabRow(
                          allNormalized: allNormalized,
                          selected: _filterStatus,
                          onSelect: (v) => setState(() => _filterStatus = v),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: filtered.isEmpty
                              ? _EmptyState(filterStatus: _filterStatus)
                              : LayoutBuilder(builder: (ctx, constraints) {
                                  final crossCount = screenW < 700 ? 1 : screenW < 1100 ? 2 : 3;
                                  return GridView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: 260,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) => _OrderCard(entry: filtered[i]),
                                  );
                                }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderEntry {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final String status; // sudah dinormalisasi
  _OrderEntry({required this.doc, required this.data, required this.status});
}

// ============================================================
// 🔔 NOTIFIKASI BELL
// Badge = jumlah order 'Menunggu Konfirmasi' yang belum dibuka admin
// (field is_seen belum true). Reset begitu admin membuka detail order itu.
// ============================================================
class _NotifBell extends StatelessWidget {
  final VoidCallback onTap;
  const _NotifBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: sMenunggu)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final unseen = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['is_seen'] != true;
        }).length;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_rounded, color: primary, size: 20),
              ),
              if (unseen > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        unseen > 9 ? '9+' : '$unseen',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// 🔖 TAB ROW
// ============================================================
class _TabRow extends StatelessWidget {
  final List<_OrderEntry> allNormalized;
  final String selected;
  final ValueChanged<String> onSelect;
  const _TabRow({required this.allNormalized, required this.selected, required this.onSelect});

  int _count(String val) =>
      val == 'semua' ? allNormalized.length : allNormalized.where((e) => e.status == val).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((t) {
          final val = t['value']!;
          final isActive = selected == val;
          final n = _count(val);
          return GestureDetector(
            onTap: () => onSelect(val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isActive ? primary : const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Text(
                    t['label']!,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : textSoft,
                    ),
                  ),
                  if (n > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white.withOpacity(0.25) : bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isActive ? Colors.white : primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// 🗳️ EMPTY STATE
// ============================================================
class _EmptyState extends StatelessWidget {
  final String filterStatus;
  const _EmptyState({required this.filterStatus});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: primary.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            filterStatus == 'semua' ? 'Belum ada pesanan' : 'Tidak ada pesanan di kategori ini',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Pesanan dari pelanggan akan tampil di sini',
            style: GoogleFonts.poppins(fontSize: 12, color: textSoft),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🃏 ORDER CARD — ramping, mengikuti grid admin_paket_page
// ============================================================
class _OrderCard extends StatelessWidget {
  final _OrderEntry entry;
  const _OrderCard({required this.entry});

  Map<String, dynamic> get data => entry.data;
  String get status => entry.status;
  String get docId => entry.doc.id;
  List<Map<String, dynamic>> get items => List<Map<String, dynamic>>.from(data['items'] ?? []);

  @override
  Widget build(BuildContext context) {
    final cfg = _statusCfg(status);
    final nama = data['nama_pemesan'] ?? '-';
    final total = (data['grand_total'] ?? 0) as int;
    final createdTs = data['created_at'];
    final createdAt = createdTs != null ? (createdTs as Timestamp).toDate() : DateTime.now();
    final shortId = docId.length > 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();
    final isArchived = data['is_archived'] == true;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Opacity(
        opacity: isArchived ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: nama + status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#$shortId · ${_timeAgo(createdAt)}',
                          style: const TextStyle(fontSize: 10.5, color: textSoft),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: cfg['bg'], borderRadius: BorderRadius.circular(7)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(cfg['icon'], size: 10, color: cfg['color']),
                      const SizedBox(width: 3),
                      Text(cfg['label'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cfg['color'])),
                    ]),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Container(height: 0.5, color: Colors.black12),
              const SizedBox(height: 8),

              // Item preview ringkas
              Expanded(
                child: items.isEmpty
                    ? Text('Tidak ada item', style: GoogleFonts.poppins(fontSize: 11, color: textSoft))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...items.take(2).map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${item['name'] ?? ''} ×${item['qty'] ?? 1}',
                                  style: const TextStyle(fontSize: 11.5, color: textSoft),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                          if (items.length > 2)
                            Text('+${items.length - 2} item lainnya', style: const TextStyle(fontSize: 10.5, color: textSoft)),
                        ],
                      ),
              ),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: GoogleFonts.poppins(fontSize: 11, color: textSoft)),
                  Text(_formatRp(total), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: primary)),
                ],
              ),

              const SizedBox(height: 8),

              // ── Tombol aksi sesuai status ──
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    // Menunggu Konfirmasi → Terima / Tolak
    if (status == sMenunggu) {
      return Row(
        children: [
          Expanded(
            child: _smallBtn(
              label: 'Tolak',
              fg: colCancelled,
              bg: const Color(0xFFF5F5F5),
              border: const Color(0xFFE0E0E0),
              onTap: () => _showRejectDialog(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _smallBtn(
              label: 'Terima',
              fg: Colors.white,
              bg: primary,
              border: primary,
              onTap: () => _confirmUpdate(context, sDiproses, successMsg: 'Pesanan diterima & diproses'),
            ),
          ),
        ],
      );
    }
    // Diproses → Tandai Selesai
    if (status == sDiproses) {
      return SizedBox(
        width: double.infinity,
        child: _smallBtn(
          label: '✓ Tandai Selesai',
          fg: Colors.white,
          bg: primary,
          border: primary,
          onTap: () => _confirmUpdate(context, sSelesai, successMsg: 'Pesanan selesai'),
        ),
      );
    }
    // Selesai / Dibatalkan → Edit & Arsipkan
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ActionIconBtn(
          icon: Icons.edit_outlined,
          color: primary,
          tooltip: 'Edit catatan/alamat',
          onTap: () => showDialog(
            context: context,
            builder: (_) => EditOrderDialog(docId: docId, data: data),
          ),
        ),
        const SizedBox(width: 4),
        _ActionIconBtn(
          icon: Icons.archive_outlined,
          color: Colors.red,
          tooltip: 'Arsipkan pesanan',
          onTap: () => _confirmArchive(context),
        ),
      ],
    );
  }

  Widget _smallBtn({
    required String label,
    required Color fg,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ),
      ),
    );
  }

  void _confirmUpdate(BuildContext context, String newStatus, {required String successMsg}) {
    final cfg = _statusCfg(newStatus);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(cfg['icon'], color: cfg['color'], size: 20),
          const SizedBox(width: 8),
          const Text('Ubah Status Pesanan'),
        ]),
        content: Text('Pesanan akan diubah menjadi "${cfg['label']}". Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
            onPressed: () async {
              // Tutup dialog dulu sebelum await, supaya UI tidak nyangkut
              // walau card di belakangnya rebuild/dispose saat status berubah.
              Navigator.pop(dialogContext);
              await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': newStatus});
              if (context.mounted) {
                _toast(context, successMsg);
              }
            },
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
  }

  // ── Tolak pesanan: wajib isi alasan ──
  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          String? error;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tolak Pesanan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Masukkan alasan penolakan untuk pelanggan:', style: TextStyle(fontSize: 13, color: textSoft)),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: inputStyle('Alasan penolakan').copyWith(errorText: error),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () async {
                  final reason = reasonCtrl.text.trim();
                  if (reason.isEmpty) {
                    setLocal(() => error = 'Alasan wajib diisi');
                    return;
                  }
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection('orders').doc(docId).update({
                    'status': sDibatalkan,
                    'cancel_reason': reason,
                  });
                  if (context.mounted) {
                    _toast(context, 'Pesanan ditolak');
                  }
                },
                child: const Text('Tolak Pesanan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Arsipkan (soft-delete) ──
  void _confirmArchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Arsipkan Pesanan'),
        content: const Text('Pesanan akan diarsipkan dan ditandai pudar di daftar. Data tetap tersimpan dan bisa dilihat kembali. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await FirebaseFirestore.instance.collection('orders').doc(docId).update({'is_archived': true});
              if (context.mounted) {
                _toast(context, 'Pesanan diarsipkan');
              }
            },
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Detail bottom sheet — buka detail = tandai is_seen: true (reset notif) ──
  void _showDetail(BuildContext context) async {
    if (status == sMenunggu && data['is_seen'] != true) {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({'is_seen': true});
    }

    if (!context.mounted) return;
    final cfg = _statusCfg(status);
    final nama = data['nama_pemesan'] ?? '-';
    final noTelp = data['no_telpon'] ?? '-';
    final total = (data['grand_total'] ?? 0) as int;
    final shortId = docId.length > 8 ? docId.substring(0, 8).toUpperCase() : docId.toUpperCase();
    final createdTs = data['created_at'];
    final createdAt = createdTs != null ? (createdTs as Timestamp).toDate() : DateTime.now();
    final cancelReason = data['cancel_reason'] as String?;
    final note = data['admin_note'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: cardBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Pesanan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('#$shortId', style: GoogleFonts.poppins(fontSize: 12, color: textSoft, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: cfg['bg'], borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(cfg['icon'], size: 13, color: cfg['color']),
                        const SizedBox(width: 5),
                        Text(cfg['label'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cfg['color'])),
                      ]),
                    ),
                  ],
                ),

                if (cancelReason != null && cancelReason.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bgCancelled, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alasan Penolakan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colCancelled)),
                        const SizedBox(height: 4),
                        Text(cancelReason, style: const TextStyle(fontSize: 12.5, color: textSoft)),
                      ],
                    ),
                  ),
                ],

                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bgInfo, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Catatan Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colInfo)),
                        const SizedBox(height: 4),
                        Text(note, style: const TextStyle(fontSize: 12.5, color: textSoft)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                _detailRow(Icons.person_rounded, 'Nama', nama),
                _detailRow(Icons.phone_rounded, 'No. Telpon', noTelp),
                _detailRow(Icons.access_time_rounded, 'Waktu Pesan', _formatDate(createdAt)),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daftar Pesanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ...items.map((item) => _PackageItemCard(item: item)),
                      Container(height: 1, color: dividerClr, margin: const EdgeInsets.symmetric(vertical: 8)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(_formatRp(total), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: primary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (status == sMenunggu)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () { Navigator.pop(context); _showRejectDialog(context); },
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () { Navigator.pop(context); _confirmUpdate(context, sDiproses, successMsg: 'Pesanan diterima & diproses'); },
                          child: const Text('Terima Pesanan'),
                        ),
                      ),
                    ],
                  )
                else if (status == sDiproses)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () { Navigator.pop(context); _confirmUpdate(context, sSelesai, successMsg: 'Pesanan selesai'); },
                      child: const Text('Tandai Selesai'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 10),
          Text('$label  ', style: const TextStyle(fontSize: 12, color: textSoft)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ============================================================
// 🛠️ SMALL WIDGETS
// ============================================================
class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionIconBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ============================================================
// 📦 PACKAGE ITEM CARD
// Menampilkan 1 item pesanan + isi paket (menu_items) yang di-fetch
// realtime dari collection 'packages' via package_id. Bisa expand/collapse
// supaya tidak makan tempat kalau pelanggan pesan banyak paket sekaligus.
// ============================================================
class _PackageItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _PackageItemCard({required this.item});

  @override
  State<_PackageItemCard> createState() => _PackageItemCardState();
}

class _PackageItemCardState extends State<_PackageItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final packageId = (item['package_id'] ?? '').toString();
    final tglTs = item['tanggal_acara'];
    String tglStr = '-';
    if (tglTs != null) {
      final tgl = (tglTs as Timestamp).toDate();
      tglStr = '${tgl.day.toString().padLeft(2, '0')}/${tgl.month.toString().padLeft(2, '0')}/${tgl.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: dividerClr)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header item: tap untuk expand isi paket ──
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: packageId.isEmpty ? null : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name'] ?? ''} ×${item['qty'] ?? 1}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _formatRp((item['total_price'] ?? 0) as int),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
                      ),
                      if (packageId.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: textSoft,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Acara: $tglStr', style: const TextStyle(fontSize: 11, color: textSoft)),
                ],
              ),
            ),
          ),

          // ── Isi paket (menu_items), di-fetch saat expanded ──
          if (_expanded && packageId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('packages').doc(packageId).get(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                      ),
                    );
                  }
                  if (!snap.hasData || !snap.data!.exists) {
                    return Text(
                      'Paket tidak ditemukan (mungkin sudah dihapus)',
                      style: GoogleFonts.poppins(fontSize: 11, color: textSoft, fontStyle: FontStyle.italic),
                    );
                  }
                  final pkg = snap.data!.data() as Map<String, dynamic>;
                  final menuItems = List<String>.from(pkg['menu_items'] ?? []);
                  if (menuItems.isEmpty) {
                    return Text(
                      'Tidak ada rincian isi paket',
                      style: GoogleFonts.poppins(fontSize: 11, color: textSoft, fontStyle: FontStyle.italic),
                    );
                  }
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Isi Paket', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: menuItems.map((m) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(m, style: const TextStyle(fontSize: 10.5, color: textSoft)),
                          )).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// ✏️ EDIT ORDER DIALOG — ubah catatan admin / no. telpon
// ============================================================
class EditOrderDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const EditOrderDialog({super.key, required this.docId, required this.data});

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<EditOrderDialog> {
  late TextEditingController _noteCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.data['admin_note'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.data['no_telpon'] ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Pesanan', style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _phoneCtrl, decoration: inputStyle('No. Telpon')),
            const SizedBox(height: 12),
            TextField(controller: _noteCtrl, maxLines: 3, decoration: inputStyle('Catatan admin / alamat')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.docId).update({
        'no_telpon': _phoneCtrl.text.trim(),
        'admin_note': _noteCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}