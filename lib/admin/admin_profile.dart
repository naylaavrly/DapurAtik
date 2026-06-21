import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../landing/landing_page.dart'; // ← tambahan: untuk navigasi setelah logout

// ── Design tokens (sama dengan dashboard)
const Color primary    = Color(0xFF7A1C1C);
const Color primarySoft= Color(0xFFFFF0F0);
const Color bgPage     = Color(0xFFF5E6DA);
const Color bgCard     = Color(0xFFFFFFFF);
const Color textDark   = Color(0xFF1A1A1A);
const Color textMuted  = Color(0xFF9E9E9E);

InputDecoration _inputStyle(String label, {String? helper}) =>
    InputDecoration(
      labelText: label,
      helperText: helper,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0xFFF9F3EF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});
  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final _user = FirebaseAuth.instance.currentUser;

  // Controllers info
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();

  // Controllers password
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _cfmPassCtrl = TextEditingController();

  bool _isLoading    = true;
  bool _isSaving     = false;
  bool _isVerified   = false;
  bool _showOld      = false;
  bool _showNew      = false;
  bool _showCfm      = false;

  String _email      = '';
  String _name       = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _cfmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    final d = doc.data() ?? {};
    setState(() {
      _email         = _user!.email ?? '';
      _name          = d['name'] ?? '';
      _nameCtrl.text = _name;
      _phoneCtrl.text= d['phone'] ?? '';
      _isLoading     = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'name':  _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      setState(() => _name = _nameCtrl.text.trim());
      _toast('Profil berhasil disimpan', success: true);
    } catch (e) {
      _toast('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _verifyOldPassword() async {
    if (_oldPassCtrl.text.isEmpty) {
      _toast('Masukkan password lama terlebih dahulu');
      return;
    }
    try {
      final cred = EmailAuthProvider.credential(
          email: _user!.email!, password: _oldPassCtrl.text);
      await _user!.reauthenticateWithCredential(cred);
      setState(() => _isVerified = true);
      _toast('Password lama benar ✓', success: true);
    } catch (_) {
      _toast('Password lama salah');
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _cfmPassCtrl.text) {
      _toast('Konfirmasi password tidak cocok');
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      _toast('Password baru minimal 6 karakter');
      return;
    }
    try {
      await _user!.updatePassword(_newPassCtrl.text);
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      _cfmPassCtrl.clear();
      setState(() => _isVerified = false);
      _toast('Password berhasil diubah', success: true);
    } catch (e) {
      _toast('Gagal ubah password: $e');
    }
  }

  void _toast(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            success
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        backgroundColor: success ? primary : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgPage,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Judul ──
              Center(
                child: Text('Profil Admin',
                    style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primary)),
              ),

              const SizedBox(height: 24),

              // ── Avatar + Info Singkat ──
              _avatarCard(),

              const SizedBox(height: 20),

              // ── Informasi Akun ──
              _sectionCard(
                title: 'Informasi Akun',
                icon: Icons.person_outline_rounded,
                child: Column(
                  children: [
                    // Email (read-only)
                    TextField(
                      controller: TextEditingController(text: _email),
                      readOnly: true,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: textMuted),
                      decoration: _inputStyle('Email').copyWith(
                        suffixIcon: const Icon(Icons.lock_outline,
                            size: 16, color: textMuted),
                        helperText: 'Email tidak bisa diubah',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nameCtrl,
                      decoration: _inputStyle('Nama Admin'),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputStyle('No. Telepon'),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : Text('Simpan Perubahan',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Ubah Password ──
              _sectionCard(
                title: 'Ubah Password',
                icon: Icons.lock_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stepBadge('1', 'Verifikasi password lama'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _oldPassCtrl,
                      obscureText: !_showOld,
                      enabled: !_isVerified,
                      decoration: _inputStyle('Password Lama')
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                              _showOld
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: textMuted),
                          onPressed: () =>
                              setState(() => _showOld = !_showOld),
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              _isVerified ? textMuted : primary,
                          side: BorderSide(
                              color: _isVerified
                                  ? textMuted
                                  : primary),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        onPressed: _isVerified
                            ? null
                            : _verifyOldPassword,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isVerified
                                  ? Icons.check_circle_rounded
                                  : Icons.verified_user_outlined,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isVerified
                                  ? 'Terverifikasi ✓'
                                  : 'Verifikasi Password',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isVerified) ...[
                      const SizedBox(height: 20),
                      _stepBadge('2', 'Buat password baru'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPassCtrl,
                        obscureText: !_showNew,
                        decoration: _inputStyle('Password Baru',
                                helper: 'Minimal 6 karakter')
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                                _showNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: textMuted),
                            onPressed: () =>
                                setState(() => _showNew = !_showNew),
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cfmPassCtrl,
                        obscureText: !_showCfm,
                        decoration:
                            _inputStyle('Konfirmasi Password Baru')
                                .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                                _showCfm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: textMuted),
                            onPressed: () =>
                                setState(() => _showCfm = !_showCfm),
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          onPressed: _changePassword,
                          child: Text('Ubah Password',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Logout ──
              _sectionCard(
                title: 'Sesi Aktif',
                icon: Icons.security_rounded,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Masuk sebagai Admin',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(_email,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                              vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        onPressed: () =>
                            _confirmLogout(context),
                        icon: const Icon(Icons.logout_rounded,
                            size: 17),
                        label: Text('Keluar dari Akun',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar card ──
  Widget _avatarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFFB23A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : 'A',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.isNotEmpty ? _name : 'Admin',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  _email,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Admin',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card ──
  Widget _sectionCard({
    required String  title,
    required IconData icon,
    required Widget  child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _stepBadge(String step, String label) => Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
                color: primary, shape: BoxShape.circle),
            child: Center(
              child: Text(step,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textDark)),
        ],
      );

  // ============================================================
  // FUNGSI: dialog konfirmasi logout
  // FIX: setelah signOut navigasi ke Landingpage
  // ============================================================
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun'),
        content: const Text('Yakin ingin logout dari akun admin ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context); // tutup dialog dulu
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                // Navigasi ke landing page, hapus semua route sebelumnya
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Landingpage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}