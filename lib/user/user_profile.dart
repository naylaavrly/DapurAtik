import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// DESIGN TOKENS — warna sesuai user_profile yang sudah ada
// ============================================================
const Color _primary     = Color(0xFF61100D);
const Color _primarySoft = Color(0xFFFFF0F0);
const Color _bgPage      = Color(0xFFF5E6DA);
const Color _bgCard      = Color(0xFFFFFFFF);
const Color _textDark    = Color(0xFF1A1A1A);
const Color _textMuted   = Color(0xFF9E9E9E);

// ============================================================
// HELPER: style field input (sama polanya dengan admin_profile)
// ============================================================
InputDecoration _inputStyle(String label, {String? helper}) =>
    InputDecoration(
      labelText: label,
      helperText: helper,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0xFFF9F3EF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
    );

// ============================================================
class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final _user = FirebaseAuth.instance.currentUser;

  // Controllers data diri
  final _addressCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();

  // Controllers ganti password
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _isLoading  = true;
  bool _isSaving   = false;
  bool _isVerified = false;
  bool _showOld    = false;
  bool _showNew    = false;

  String _email = '';
  String _name  = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // FUNGSI: ambil data user dari Firestore
  // ============================================================
  Future<void> _loadData() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    final d = doc.data() ?? {};
    setState(() {
      _email             = _user!.email ?? '';
      _name              = d['name'] ?? '';
      _addressCtrl.text  = d['address'] ?? '';
      _phoneCtrl.text    = d['phone'] ?? '';
      _isLoading         = false;
    });
  }

  // ============================================================
  // FUNGSI: simpan perubahan alamat & telepon ke Firestore
  // ============================================================
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'address': _addressCtrl.text.trim(),
        'phone':   _phoneCtrl.text.trim(),
      });
      _toast('Profil berhasil disimpan', success: true);
    } catch (e) {
      _toast('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============================================================
  // FUNGSI: verifikasi password lama sebelum ganti password
  // ============================================================
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

  // ============================================================
  // FUNGSI: ganti ke password baru
  // ============================================================
  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 6) {
      _toast('Password baru minimal 6 karakter');
      return;
    }
    try {
      await _user!.updatePassword(_newPassCtrl.text);
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      setState(() => _isVerified = false);
      _toast('Password berhasil diubah', success: true);
    } catch (e) {
      _toast('Gagal ubah password: $e');
    }
  }

  // ============================================================
  // HELPER: tampilkan snackbar sukses / error
  // ============================================================
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
        backgroundColor: success ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // BUILD: halaman profil user
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgPage,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          children: [

            // -------------------------------------------------------
            // NAVBAR: judul halaman — sama dengan halaman lain di app
            // -------------------------------------------------------
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              color: _primary,
              child: Text(
                "Profil",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            // -------------------------------------------------------
            // BODY: scrollable content
            // -------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ----------------------------------------
                    // AVATAR CARD: gradient merah dengan inisial
                    // ----------------------------------------
                    _avatarCard(),

                    const SizedBox(height: 20),

                    // ----------------------------------------
                    // SECTION CARD: Data Diri
                    // ----------------------------------------
                    _sectionCard(
                      title: 'Data Diri',
                      icon: Icons.person_outline_rounded,
                      child: Column(
                        children: [

                          // Email (read-only, tidak bisa diubah)
                          TextField(
                            controller:
                                TextEditingController(text: _email),
                            readOnly: true,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: _textMuted),
                            decoration: _inputStyle('Email').copyWith(
                              suffixIcon: const Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: _textMuted),
                              helperText: 'Email tidak bisa diubah',
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Field alamat
                          TextField(
                            controller: _addressCtrl,
                            maxLines: 2,
                            decoration: _inputStyle('Alamat Pengiriman'),
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),

                          const SizedBox(height: 14),

                          // Field nomor telepon
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: _inputStyle('Nomor Telepon'),
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),

                          const SizedBox(height: 18),

                          // Tombol simpan perubahan
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
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

                    // ----------------------------------------
                    // SECTION CARD: Ganti Password
                    // ----------------------------------------
                    _sectionCard(
                      title: 'Ganti Password',
                      icon: Icons.lock_outline_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Step 1: verifikasi password lama
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
                                    color: _textMuted),
                                onPressed: () =>
                                    setState(() => _showOld = !_showOld),
                              ),
                            ),
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),

                          const SizedBox(height: 10),

                          // Tombol verifikasi — berubah jadi "Terverifikasi" setelah sukses
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    _isVerified ? _textMuted : _primary,
                                side: BorderSide(
                                    color: _isVerified
                                        ? _textMuted
                                        : _primary),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
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

                          // Step 2 muncul setelah verifikasi berhasil
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
                                      color: _textMuted),
                                  onPressed: () => setState(
                                      () => _showNew = !_showNew),
                                ),
                              ),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),

                            const SizedBox(height: 14),

                            // Tombol ubah password
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
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

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: avatar card dengan gradient merah + inisial nama
  // ============================================================
  Widget _avatarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, Color(0xFFB23A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Inisial nama user
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
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
                // Nama user
                Text(
                  _name.isNotEmpty ? _name : 'Pengguna',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                // Email user
                Text(
                  _email,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Badge role
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Pelanggan',
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

  // ============================================================
  // WIDGET: section card dengan judul + ikon + konten
  // ============================================================
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
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
          // Header section: ikon + judul
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textDark)),
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

  // ============================================================
  // WIDGET: badge step bernomor (untuk alur ganti password)
  // ============================================================
  Widget _stepBadge(String step, String label) => Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
                color: _primary, shape: BoxShape.circle),
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
                  color: _textDark)),
        ],
      );
}