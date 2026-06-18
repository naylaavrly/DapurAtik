import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../user/user_home.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

// ── Palet warna
const Color _primary     = Color(0xFF7A1C1C);
const Color _primaryDark = Color(0xFF5A1212);
const Color _bgPage      = Color(0xFFFAF6F3);
const Color _bgCard      = Color(0xFFFFFFFF);
const Color _textSoft    = Color(0xFF8E8E8E);
const Color _divider     = Color(0xFFECE8E5);

// ── Badge warna per tipe
const Map<String, List<Color>> _typeBadge = {
  'hajatan':  [Color(0xFFEEEDFE), Color(0xFF3C3489)],
  'tahlilan': [Color(0xFFE1F5EE), Color(0xFF0F6E56)],
  'snackbox': [Color(0xFFFAEEDA), Color(0xFF854F0B)],
};
const Map<String, String> _typeLabel = {
  'hajatan':  'Hajatan',
  'tahlilan': 'Tahlilan',
  'snackbox': 'Snack Box',
};
const List<String> _typeOrder = ['hajatan', 'tahlilan', 'snackbox'];

// ─────────────────────────────────────────────
class Landingpage extends StatefulWidget {
  const Landingpage({super.key});
  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _homeKey    = GlobalKey();
  final GlobalKey _menuKey    = GlobalKey();
  final GlobalKey _kontakKey  = GlobalKey();


  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHome()),
        );
      });
    }
  }

  void _goto(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          _buildNavbar(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                children: [
                  Container(key: _homeKey,   child: _buildHero()),
                  Container(key: _menuKey,   child: _buildMenu()),
                  Container(key: _kontakKey, child: _buildFooter()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── NAVBAR ───────────────
  Widget _buildNavbar() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "Mbak Atik Catering",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          // Nav links
          Row(
            children: [
              _navBtn("Beranda", () => _goto(_homeKey)),
              _navBtn("Menu",    () => _goto(_menuKey)),
              _navBtn("Kontak",  () => _goto(_kontakKey)),
              const SizedBox(width: 8),

              // Tombol Login
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const Dialog(
                    child: SizedBox(width: 400, child: LoginPage()),
                  ),
                ),
                child: Text("Login",
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),

              const SizedBox(width: 8),

              // Tombol Daftar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const Dialog(
                    child: SizedBox(width: 400, child: RegisterPage()),
                  ),
                ),
                child: Text("Daftar",
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.85),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  // ─────────────── HERO ───────────────
  Widget _buildHero() {
    return Container(
      color: _bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        children: [
          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _primary.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 13, color: _primary),
                const SizedBox(width: 5),
                Text(
                  "Terpercaya Sejak 1996",
                  style: GoogleFonts.poppins(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Headline
          Text(
            "Catering Rumahan\nuntuk Setiap Momen Spesial",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: const Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            "Cita rasa masakan rumahan, harga terjangkau,\npelayanan terpercaya untuk hajatan, tahlilan, dan snack box.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _textSoft,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 32),

          // CTA Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                onPressed: () => _goto(_menuKey),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text("Lihat Menu",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => _goto(_kontakKey),
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: Text("Hubungi Kami",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),

          const SizedBox(height: 44),

          // Stats strip
          _buildStatsStrip(),
        ],
      ),
    );
  }

  Widget _buildStatsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: _bgPage,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _StatItem(value: "28+", label: "Tahun Pengalaman"),
          _Pipe(),
          _StatItem(value: "3 Kategori", label: "Jenis Paket"),
          _Pipe(),
          _StatItem(value: "100+", label: "Pelanggan Puas"),
        ],
      ),
    );
  }

  // ─────────────── MENU ───────────────
  Widget _buildMenu() {
    return Container(
      color: _bgPage,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(width: 4, height: 28,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(4),
                  )),
              const SizedBox(width: 12),
              Text(
                "Paket Menu Kami",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              "Pilih paket yang sesuai dengan kebutuhan acara Anda",
              style: GoogleFonts.poppins(fontSize: 13, color: _textSoft),
            ),
          ),
          const SizedBox(height: 28),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('packages')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: _primary),
                ));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState();
              }

              final docs = snapshot.data!.docs;

              // Group by type
              final Map<String, List<QueryDocumentSnapshot>> grouped = {};
              for (final doc in docs) {
                final t = ((doc.data() as Map<String, dynamic>)['type'] ?? '')
                    .toString()
                    .toLowerCase();
                grouped.putIfAbsent(t, () => []).add(doc);
              }

              // Sort sections
              final sections = _typeOrder
                  .where((t) => grouped.containsKey(t))
                  .toList();
              for (final t in grouped.keys) {
                if (!sections.contains(t)) sections.add(t);
              }

              return Column(
                children: sections.map((type) {
                  final items = grouped[type]!;
                  final label = _typeLabel[type] ?? type;
                  final badge = _typeBadge[type] ??
                      [_primary.withOpacity(0.1), _primary];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section badge
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: badge[0],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: badge[1],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(height: 1, color: _divider),
                            ),
                            const SizedBox(width: 8),
                            Text("${items.length} paket",
                                style: const TextStyle(
                                    fontSize: 12, color: _textSoft)),
                          ],
                        ),
                      ),

                      // Grid kartu
                      LayoutBuilder(builder: (ctx, constraints) {
                        final w = constraints.maxWidth;
                        final crossCount = w < 600 ? 1 : w < 960 ? 2 : 3;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 230,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final d = items[i].data() as Map<String, dynamic>;
                            return _PackageCard(data: d, badge: badge);
                          },
                        );
                      }),

                      const SizedBox(height: 32),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          // CTA masuk
          _buildMenuCta(),
        ],
      ),
    );
  }

  Widget _buildMenuCta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            "Siap memesan?",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Login atau daftar untuk melakukan pemesanan paket catering",
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const Dialog(
                    child: SizedBox(width: 400, child: LoginPage()),
                  ),
                ),
                icon: const Icon(Icons.login, size: 17),
                label: Text("Login",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const Dialog(
                    child: SizedBox(width: 400, child: RegisterPage()),
                  ),
                ),
                icon: const Icon(Icons.person_add_outlined, size: 17),
                label: Text("Daftar",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.restaurant_outlined, size: 48, color: _textSoft),
            const SizedBox(height: 12),
            Text("Belum ada paket tersedia",
                style: GoogleFonts.poppins(color: _textSoft, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─────────────── FOOTER ───────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2A2A2A),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "Mbak Atik Catering",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 24),

          Text("Kontak Kami",
              style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1)),

          const SizedBox(height: 14),

          _footerRow(Icons.phone_outlined, "0813-1583-7240"),
          const SizedBox(height: 10),
          _footerRow(
            Icons.location_on_outlined,
            "Jl. Alun-Alun Selatan, Mustika Jaya, Bekasi, Jawa Barat",
          ),
          const SizedBox(height: 10),
          _footerRow(Icons.access_time_outlined,
              "Buka setiap hari  •  08.00 – 20.00 WIB"),

          const SizedBox(height: 28),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 16),

          Text(
            "© 2026 Mbak Atik Catering. All rights reserved.",
            style: GoogleFonts.poppins(
                color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _footerRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 13, height: 1.5)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PACKAGE CARD
// ─────────────────────────────────────────────
class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Color> badge;
  const _PackageCard({required this.data, required this.badge});

  @override
  Widget build(BuildContext context) {
    final name      = data['name']       ?? '-';
    final price     = data['price']      ?? 0;
    final minOrder  = data['min_order']  ?? 0;
    final leadTime  = data['lead_time']  ?? 0;
    final menuItems = List<String>.from(data['menu_items'] ?? []);

    final formattedPrice = _formatRupiah(price);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama + harga
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badge[0],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formattedPrice,
                  style: TextStyle(
                    color: badge[1],
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Info chips
          Row(
            children: [
              _InfoChip(
                icon: Icons.people_outline,
                label: "Min. $minOrder porsi",
              ),
              const SizedBox(width: 6),
              _InfoChip(
                icon: Icons.schedule_outlined,
                label: "$leadTime hari",
              ),
            ],
          ),

          const SizedBox(height: 10),
          Container(height: 0.5, color: _divider),
          const SizedBox(height: 8),

          // Isi menu — Wrap chip
          Expanded(
            child: menuItems.isEmpty
                ? Text("Belum ada isi menu",
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _textSoft))
                : Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: menuItems
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F0ED),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(
                                    fontSize: 10, color: _textSoft),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(dynamic val) {
    final n = (val is int) ? val : (int.tryParse('$val') ?? 0);
    if (n >= 1000) {
      return 'Rp ${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return 'Rp $n';
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _textSoft),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: _textSoft)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: _textSoft),
        ),
      ],
    );
  }
}

class _Pipe extends StatelessWidget {
  const _Pipe();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: _divider,
    );
  }
}