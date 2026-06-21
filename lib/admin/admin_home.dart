import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_dashboard.dart';
import 'admin_paket_page.dart';
import 'admin_user_page.dart';
import 'admin_order_page.dart';
import 'admin_profile.dart';

const Color _primary   = Color(0xFF7A1C1C);
const Color _textMuted = Color(0xFF9E9E9E);

const String _sMenunggu = 'Menunggu Konfirmasi';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1)  return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

String _normalizeStatus(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  if (s == _sMenunggu.toLowerCase()) return _sMenunggu;
  if (s == 'diproses')               return 'Diproses';
  if (s == 'selesai')                return 'Selesai';
  if (s == 'dibatalkan')             return 'Dibatalkan';
  return raw?.trim().isNotEmpty == true ? raw!.trim() : _sMenunggu;
}

// ============================================================
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Callback untuk child (dashboard) bisa navigasi ke tab tertentu
  void _navigateTo(int index) => setState(() => _selectedIndex = index);

  List<Widget> get _pages => [
    AdminDashboard(
      onNavigateTo: _navigateTo,
      onOpenNotif: () => _scaffoldKey.currentState?.openEndDrawer(),
    ),
    const AdminPaketPage(),
    const AdminOrderPage(),
    const AdminUserPage(),
    const AdminProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5E6DA),

      // ── Notifikasi Drawer (dari kanan) ──
      endDrawer: _NotifDrawer(
        onGoToOrders: () {
          Navigator.pop(context); // tutup drawer
          _navigateTo(2);
        },
      ),

      body: Stack(
        children: [
          // ── Content ──
          Positioned.fill(
            child: _pages[_selectedIndex],
          ),

          // ── Floating Navbar ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
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
                    _navItem(Icons.dashboard_rounded,     0, tooltip: 'Dashboard'),
                    _navItem(Icons.restaurant_menu_rounded, 1, tooltip: 'Paket'),
                    _navItem(Icons.receipt_long_rounded,  2, tooltip: 'Pesanan'),
                    _navItem(Icons.people_rounded,        3, tooltip: 'User'),
                    _navItem(Icons.person_rounded,        4, tooltip: 'Profil'),
                    const SizedBox(width: 4),
                    _divider(),
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

  Widget _navItem(IconData icon, int index, {required String tooltip}) {
    final isActive = _selectedIndex == index;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isActive
                ? _primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isActive ? _primary : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.black12,
      );

  Widget _logoutItem() => Tooltip(
        message: 'Logout',
        child: GestureDetector(
          onTap: () => _confirmLogout(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(11),
            child: const Icon(Icons.logout_rounded,
                size: 24, color: Colors.grey),
          ),
        ),
      );

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun'),
        content: const Text('Yakin ingin logout dari akun admin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🔔 NOTIF DRAWER (END DRAWER dari kanan)
// ============================================================
class _NotifDrawer extends StatelessWidget {
  final VoidCallback onGoToOrders;
  const _NotifDrawer({required this.onGoToOrders});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: const BoxDecoration(
                color: _primary,
                borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Notifikasi',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // List notifikasi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .orderBy('created_at', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: _primary));
                  }

                  final docs = snap.data!.docs;
                  final notifs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return _normalizeStatus(data['status']) ==
                        _sMenunggu;
                  }).toList();

                  if (notifs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 48,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Tidak ada notifikasi baru',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _textMuted)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8),
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 20),
                    itemBuilder: (context, i) {
                      final doc  = notifs[i];
                      final d    = doc.data() as Map<String, dynamic>;
                      final nama = d['nama_pemesan'] ?? '-';
                      final total= (d['grand_total'] ?? 0) as int;
                      final ts   = (d['created_at'] as Timestamp?)
                          ?.toDate();
                      final isSeen = d['is_seen'] == true;
                      // Ambil nama paket pertama
                      String namaPaket = '-';

                      if (d['items'] != null && d['items'] is List) {
                        final items = List<Map<String, dynamic>>.from(d['items']);

                        if (items.isNotEmpty) {
                          namaPaket = items.first['nama'] ??
                              items.first['name'] ??
                              'Paket';

                          if (items.length > 1) {
                            namaPaket += ' + ${items.length - 1} item lainnya';
                          }
                        }
                      }
                      final shortId = doc.id.length > 6
                          ? doc.id.substring(0, 6).toUpperCase()
                          : doc.id.toUpperCase();

                      // Format rupiah
                      final s = total.toString();
                      final buf = StringBuffer();
                      for (int j = 0; j < s.length; j++) {
                        if (j > 0 && (s.length - j) % 3 == 0) {
                          buf.write('.');
                        }
                        buf.write(s[j]);
                      }
                      final formatted = 'Rp ${buf.toString()}';

                      return InkWell(
                        onTap: () async {
                          // Tandai sudah dilihat
                          if (!isSeen) {
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(doc.id)
                                .update({'is_seen': true});
                          }
                          onGoToOrders();
                        },
                        child: Container(
                          color: isSeen
                              ? Colors.transparent
                              : _primary.withOpacity(0.04),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Dot unread
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 5, right: 10),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isSeen
                                        ? Colors.transparent
                                        : const Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // Ikon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Color(0xFFE65100),
                                    size: 18),
                              ),
                              const SizedBox(width: 12),

                              // Teks
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pesanan baru masuk',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: isSeen
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        color: const Color(
                                            0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$nama · #$namaPaket',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: _textMuted),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatted,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: _primary),
                                    ),
                                    if (ts != null)
                                      Text(
                                        _timeAgo(ts),
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: _textMuted),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer — lihat semua pesanan
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onGoToOrders,
                  icon: const Icon(
                      Icons.receipt_long_rounded,
                      size: 17),
                  label: Text('Lihat Semua Pesanan',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}