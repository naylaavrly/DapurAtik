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

// ── Model kategori (baca dari Firestore)
class _KatModel {
  final String id;
  final String label;
  final Color  colorBg;
  final Color  colorText;
  final Color  colorStrip;
  final int    urutan;

  _KatModel({
    required this.id,
    required this.label,
    required this.colorBg,
    required this.colorText,
    required this.colorStrip,
    required this.urutan,
  });

  factory _KatModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _KatModel(
      id:         doc.id,
      label:      d['label'] ?? doc.id,
      colorBg:    Color(int.tryParse(d['color_bg']    ?? '0xFFEEEDFE') ?? 0xFFEEEDFE),
      colorText:  Color(int.tryParse(d['color_text']  ?? '0xFF3C3489') ?? 0xFF3C3489),
      colorStrip: Color(int.tryParse(d['color_strip'] ?? '0xFF7A1C1C') ?? 0xFF7A1C1C),
      urutan:     (d['urutan'] ?? 99) as int,
    );
  }
}

// ─────────────────────────────────────────────
class Landingpage extends StatefulWidget {
  const Landingpage({super.key});
  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> {
  final ScrollController _scroll    = ScrollController();
  final GlobalKey        _homeKey   = GlobalKey();
  final GlobalKey        _menuKey   = GlobalKey();
  final GlobalKey        _kontakKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo kiri
          Row(
            children: [
              Container(
                width: 34, height: 34,
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
                  fontSize: isMobile ? 14 : 17,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          // Kanan: hamburger (mobile) atau nav penuh (desktop)
          isMobile
              ? IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                  onPressed: _showMobileMenu,
                )
              : Row(
                  children: [
                    _navBtn("Beranda", () => _goto(_homeKey)),
                    _navBtn("Menu",    () => _goto(_menuKey)),
                    _navBtn("Kontak",  () => _goto(_kontakKey)),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: _showLoginDialog,
                      child: Text("Login",
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      onPressed: _showRegisterDialog,
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

  Widget _navBtn(String label, VoidCallback onTap) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w500)),
      );

  // ── Mobile menu (bottom sheet)
  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Nav links
            _mobileNavItem(Icons.home_outlined, "Beranda", () {
              Navigator.pop(context);
              _goto(_homeKey);
            }),
            _mobileNavItem(Icons.restaurant_menu_outlined, "Menu", () {
              Navigator.pop(context);
              _goto(_menuKey);
            }),
            _mobileNavItem(Icons.phone_outlined, "Kontak", () {
              Navigator.pop(context);
              _goto(_kontakKey);
            }),

            const Divider(height: 28),

            // Tombol Login
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showLoginDialog();
                },
                child: Text("Login",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),

            // Tombol Daftar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showRegisterDialog();
                },
                child: Text("Belum punya akun? Daftar",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _mobileNavItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _primary, size: 22),
      title: Text(label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500, fontSize: 15)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showLoginDialog() => showDialog(
        context: context,
        builder: (_) => const Dialog(
            child: SizedBox(width: 400, child: LoginPage())),
      );

  void _showRegisterDialog() => showDialog(
        context: context,
        builder: (_) => const Dialog(
            child: SizedBox(width: 400, child: RegisterPage())),
      );

  // ─────────────── HERO ───────────────
  Widget _buildHero() {
    return Container(
      color: _bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                Text("Terpercaya Sejak 1996",
                    style: GoogleFonts.poppins(
                        color: _primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                fontSize: 14, color: _textSoft, height: 1.7),
          ),

          const SizedBox(height: 32),

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
                      borderRadius: BorderRadius.circular(30)),
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
                      borderRadius: BorderRadius.circular(30)),
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
          _StatItem(value: "28+",        label: "Tahun Pengalaman"),
          _Pipe(),
          _StatItem(value: "3 Kategori", label: "Jenis Paket"),
          _Pipe(),
          _StatItem(value: "100+",       label: "Pelanggan Puas"),
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
              Container(
                width: 4, height: 28,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text("Paket Menu Kami",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  )),
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

          // Baca kategori + packages sekaligus
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .orderBy('urutan')
                .snapshots(),
            builder: (context, catSnap) {
              final categories = catSnap.hasData
                  ? catSnap.data!.docs.map(_KatModel.fromDoc).toList()
                  : <_KatModel>[];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('packages')
                    .snapshots(),
                builder: (context, pkgSnap) {
                  if (!pkgSnap.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    );
                  }

                  if (pkgSnap.data!.docs.isEmpty) return _emptyState();

                  // Kelompokkan per tipe
                  final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                  for (final doc in pkgSnap.data!.docs) {
                    final t = ((doc.data() as Map<String, dynamic>)['type'] ?? '')
                        .toString().toLowerCase();
                    grouped.putIfAbsent(t, () => []).add(doc);
                  }

                  // Urutan section dari categories Firestore
                  final catIds = categories.map((c) => c.id).toList();
                  final sections = [
                    ...catIds.where((id) => grouped.containsKey(id)),
                    ...grouped.keys.where((k) => !catIds.contains(k)),
                  ];

                  // Sort nama dalam tiap section
                  for (final key in grouped.keys) {
                    grouped[key]!.sort((a, b) {
                      final na = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
                      final nb = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
                      return na.compareTo(nb);
                    });
                  }

                  return Column(
                    children: [
                      ...sections.map((typeId) {
                        final items  = grouped[typeId]!;
                        final kat    = categories.where((c) => c.id == typeId).firstOrNull;
                        final label  = kat?.label ?? typeId;
                        final bgBadge   = kat?.colorBg    ?? _primary.withOpacity(0.1);
                        final textBadge = kat?.colorText  ?? _primary;
                        final strip     = kat?.colorStrip ?? _primary;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section badge + garis
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: bgBadge,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(label,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textBadge,
                                        )),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Container(height: 1, color: _divider)),
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
                                  crossAxisCount:   crossCount,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing:  14,
                                  mainAxisExtent:   230,
                                ),
                                itemCount: items.length,
                                itemBuilder: (_, i) {
                                  final d = items[i].data() as Map<String, dynamic>;
                                  return _PackageCard(
                                    data:       d,
                                    badgeBg:    bgBadge,
                                    badgeText:  textBadge,
                                    stripColor: strip,
                                    katLabel:   label,
                                    onPesan: () => _onPesan(),
                                  );
                                },
                              );
                            }),

                            const SizedBox(height: 32),
                          ],
                        );
                      }),

                      _buildMenuCta(),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Kalau klik Pesan → minta login dulu
  void _onPesan() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  color: _primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text("Login Dulu, Yuk!",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              "Untuk melakukan pemesanan, kamu perlu login atau daftar terlebih dahulu.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: _textSoft, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showLoginDialog();
                },
                child: Text("Login Sekarang",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showRegisterDialog();
                },
                child: Text("Belum punya akun? Daftar",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
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
          Text("Siap memesan?",
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            "Login atau daftar untuk melakukan pemesanan paket catering",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 13),
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
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _showLoginDialog,
                icon: const Icon(Icons.login, size: 17),
                label: Text("Login",
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _showRegisterDialog,
                icon: const Icon(Icons.person_add_outlined, size: 17),
                label: Text("Daftar",
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.restaurant_outlined, size: 48, color: _textSoft),
              const SizedBox(height: 12),
              Text("Belum ada paket tersedia",
                  style: GoogleFonts.poppins(
                      color: _textSoft, fontSize: 14)),
            ],
          ),
        ),
      );

  // ─────────────── FOOTER ───────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2A2A2A),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: const BoxDecoration(
                    color: _primary, shape: BoxShape.circle),
                child: const Icon(Icons.restaurant_menu,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text("Mbak Atik Catering",
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
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
          _footerRow(Icons.location_on_outlined,
              "Jl. Alun-Alun Selatan, Mustika Jaya, Bekasi, Jawa Barat"),
          const SizedBox(height: 10),
          _footerRow(Icons.access_time_outlined,
              "Buka setiap hari  •  08.00 – 20.00 WIB"),
          const SizedBox(height: 28),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          Text("© 2026 Mbak Atik Catering. All rights reserved.",
              style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _footerRow(IconData icon, String text) => Row(
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

// ─────────────────────────────────────────────
// PACKAGE CARD — Opsi B (top strip)
// ─────────────────────────────────────────────
class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color      badgeBg;
  final Color      badgeText;
  final Color      stripColor;
  final String     katLabel;
  final VoidCallback onPesan;

  const _PackageCard({
    required this.data,
    required this.badgeBg,
    required this.badgeText,
    required this.stripColor,
    required this.katLabel,
    required this.onPesan,
  });

  String _formatRupiah(dynamic val) {
    final n = (val is int) ? val : (int.tryParse('$val') ?? 0);
    final str = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final name      = data['name']      ?? '-';
    final price     = data['price']     ?? 0;
    final minOrder  = data['min_order'] ?? 0;
    final leadTime  = data['lead_time'] ?? 0;
    final menu      = List<String>.from(data['menu_items'] ?? []);

    return Container(
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
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // TOP COLOR STRIP
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
                    child: Text(katLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: badgeText)),
                  ),

                  const SizedBox(height: 6),

                  // Nama + harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Text(_formatRupiah(price),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primary)),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Container(height: 0.5, color: _divider),
                  const SizedBox(height: 8),

                  // Min pesan + persiapan
                  Row(
                    children: [
                      _InfoChip(
                          icon: Icons.people_outline,
                          label: "Min. $minOrder porsi"),
                      const SizedBox(width: 6),
                      _InfoChip(
                          icon: Icons.schedule_outlined,
                          label: "$leadTime hari"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Chip menu — tampilkan semua
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: menu
                            .map((e) => _MenuChip(label: e))
                            .toList(),
                      ),
                    ),
                  ),

                  // Tombol Pesan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stripColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: onPesan,
                      child: Text("Pesan Sekarang",
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
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
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
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

class _MenuChip extends StatelessWidget {
  final String label;
  final bool   muted;
  const _MenuChip({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: muted ? Colors.transparent : const Color(0xFFF5F0ED),
          border:
              Border.all(color: muted ? Colors.black12 : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                color: muted ? _textSoft : const Color(0xFF555555))),
      );
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _primary)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: _textSoft)),
        ],
      );
}

class _Pipe extends StatelessWidget {
  const _Pipe();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: _divider);
}