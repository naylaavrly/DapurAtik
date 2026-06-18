import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// ================= KONSTANTA =================
const Color primary    = Color(0xFF7A1C1C);
const Color bgColor    = Color(0xFFF5E6DA);
const Color textSoft   = Color(0xFF8E8E8E);

// Urutan section
const List<String> _typeOrder = ['hajatan', 'tahlilan', 'snackbox'];

// Label bahasa Indonesia per tipe
const Map<String, String> _typeLabel = {
  'hajatan':  'Hajatan',
  'tahlilan': 'Tahlilan',
  'snackbox': 'Snack Box',
};

// Warna badge per tipe  (bg, text)
const Map<String, List<Color>> _typeBadgeColor = {
  'hajatan':  [Color(0xFFEEEDFE), Color(0xFF3C3489)],
  'tahlilan': [Color(0xFFE1F5EE), Color(0xFF0F6E56)],
  'snackbox': [Color(0xFFFAEEDA), Color(0xFF854F0B)],
};

// ================= STYLE INPUT =================
InputDecoration inputStyle(String label) => InputDecoration(
  labelText: label,
  floatingLabelBehavior: FloatingLabelBehavior.always,
  filled: true,
  fillColor: const Color(0xFFF9F3EF),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.grey),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: primary, width: 2),
  ),
);

// ================= PAGE =================
class AdminPaketPage extends StatefulWidget {
  const AdminPaketPage({super.key});
  @override
  State<AdminPaketPage> createState() => _AdminPaketPageState();
}

class _AdminPaketPageState extends State<AdminPaketPage> {
  String _search      = '';
  String _filterType  = 'semua';

  @override
  Widget build(BuildContext context) {
    final screenW  = MediaQuery.of(context).size.width;
    final isMobile = screenW < 700;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ===== JUDUL =====
              Center(
                child: Text(
                  'Kelola Paket',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ===== TOOLBAR =====
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v.toLowerCase()),
                      decoration: inputStyle('Cari paket...').copyWith(
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filter tipe',
                    onSelected: (v) => setState(() => _filterType = v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'semua',    child: Text('Semua')),
                      PopupMenuItem(value: 'hajatan',  child: Text('Hajatan')),
                      PopupMenuItem(value: 'tahlilan', child: Text('Tahlilan')),
                      PopupMenuItem(value: 'snackbox', child: Text('Snack Box')),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: primary, size: 32),
                    tooltip: 'Tambah Paket',
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AddPaketDialog(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== KONTEN =====
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('packages')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filter
                    final allDocs = snapshot.data!.docs.where((doc) {
                      final d    = doc.data() as Map<String, dynamic>;
                      final name = (d['name'] ?? '').toString().toLowerCase();
                      final type = (d['type'] ?? '').toString().toLowerCase();
                      final matchSearch = name.contains(_search);
                      // Fix: "snack box" di filter map ke value 'snackbox'
                      final matchType = _filterType == 'semua' || type == _filterType;
                      return matchSearch && matchType;
                    }).toList();

                    // Sort: urutan tipe → nama
                    allDocs.sort((a, b) {
                      final da = a.data() as Map<String, dynamic>;
                      final db = b.data() as Map<String, dynamic>;
                      final ta = (da['type'] ?? '').toString().toLowerCase();
                      final tb = (db['type'] ?? '').toString().toLowerCase();
                      final oi = _typeOrder.indexOf(ta);
                      final oj = _typeOrder.indexOf(tb);
                      final oa = oi < 0 ? 99 : oi;
                      final ob = oj < 0 ? 99 : oj;
                      if (oa != ob) return oa.compareTo(ob);
                      return (da['name'] ?? '').toString()
                          .toLowerCase()
                          .compareTo((db['name'] ?? '').toString().toLowerCase());
                    });

                    if (allDocs.isEmpty) {
                      return const Center(child: Text('Paket tidak ditemukan'));
                    }

                    // Kelompokkan per tipe
                    final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                    for (final doc in allDocs) {
                      final type = ((doc.data() as Map<String, dynamic>)['type'] ?? '')
                          .toString()
                          .toLowerCase();
                      grouped.putIfAbsent(type, () => []).add(doc);
                    }

                    // Urut section sesuai _typeOrder
                    final sections = _typeOrder
                        .where((t) => grouped.containsKey(t))
                        .toList();
                    // Tipe tidak dikenal tetap masuk
                    for (final t in grouped.keys) {
                      if (!sections.contains(t)) sections.add(t);
                    }

                    // Kolom grid responsif: mobile=1, tablet=2, desktop=3
                    final crossCount = screenW < 700
                        ? 1
                        : screenW < 1100
                            ? 2
                            : 3;

                    return ListView.builder(
                      itemCount: sections.length,
                      itemBuilder: (context, si) {
                        final type  = sections[si];
                        final items = grouped[type]!;
                        final label = _typeLabel[type] ?? type;
                        final badgeColors = _typeBadgeColor[type] ??
                            [primary.withOpacity(0.1), primary];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── SECTION HEADER ──
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: badgeColors[0],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      label,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: badgeColors[1],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.black12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${items.length} paket',
                                    style: const TextStyle(
                                        fontSize: 12, color: textSoft),
                                  ),
                                ],
                              ),
                            ),

                            // ── GRID KARTU ──
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:  crossCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing:  12,
                                // tinggi card dikontrol lewat mainAxisExtent agar seragam
                                mainAxisExtent: 220,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, ii) {
                                final doc  = items[ii];
                                final d    = doc.data() as Map<String, dynamic>;
                                final menu = List<String>.from(d['menu_items'] ?? []);
                                final harga    = d['price']     ?? 0;
                                final minOrder = d['min_order'] ?? 0;
                                final leadTime = d['lead_time'] ?? 0;

                                return Container(
                                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.06),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      // Nama paket
                                      Text(
                                        d['name'] ?? '-',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 10),

                                      // Stat row: harga, min porsi, persiapan
                                      Row(
                                        children: [
                                          _StatChip(
                                            icon: Icons.attach_money,
                                            label: 'Rp $harga',
                                          ),
                                          const SizedBox(width: 6),
                                          _StatChip(
                                            icon: Icons.people_outline,
                                            label: '$minOrder porsi',
                                          ),
                                          const SizedBox(width: 6),
                                          _StatChip(
                                            icon: Icons.schedule,
                                            label: '$leadTime hari',
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // Divider tipis
                                      Container(height: 0.5, color: Colors.black12),
                                      const SizedBox(height: 8),

                                      // Isi paket — chip wrap, maks 2 baris
                                      Expanded(
                                        child: _MenuChipList(items: menu),
                                      ),

                                      // Tombol aksi
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          _ActionBtn(
                                            icon: Icons.edit_outlined,
                                            color: primary,
                                            tooltip: 'Edit',
                                            onTap: () => showDialog(
                                              context: context,
                                              builder: (_) => EditPaketDialog(
                                                  docId: doc.id, data: d),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          _ActionBtn(
                                            icon: Icons.delete_outline,
                                            color: Colors.red,
                                            tooltip: 'Hapus',
                                            onTap: () =>
                                                _confirmDelete(context, doc.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),
                          ],
                        );
                      },
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

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Paket'),
        content: const Text('Yakin ingin menghapus paket ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('packages')
                  .doc(docId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ================= WIDGET KECIL =================

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textSoft),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(fontSize: 11, color: textSoft)),
        ],
      ),
    );
  }
}

class _MenuChipList extends StatelessWidget {
  final List<String> items;
  const _MenuChipList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: items
          .map(
            (e) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBE8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                e,
                style: const TextStyle(fontSize: 11, color: textSoft),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   tooltip;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ================= DIALOG TAMBAH =================
class AddPaketDialog extends StatefulWidget {
  const AddPaketDialog({super.key});
  @override
  State<AddPaketDialog> createState() => _AddPaketDialogState();
}

class _AddPaketDialogState extends State<AddPaketDialog> {
  final _namaCtrl     = TextEditingController();
  final _hargaCtrl    = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _leadTimeCtrl = TextEditingController();
  final List<TextEditingController> _menuCtrls = [TextEditingController()];

  String _tipe      = 'hajatan';
  bool   _isLoading = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _minOrderCtrl.dispose();
    _leadTimeCtrl.dispose();
    for (final c in _menuCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Paket',
          style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _namaCtrl,
                  decoration: inputStyle('Nama Paket')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipe,
                decoration: inputStyle('Kategori'),
                items: const [
                  DropdownMenuItem(value: 'hajatan',  child: Text('Hajatan')),
                  DropdownMenuItem(value: 'tahlilan', child: Text('Tahlilan')),
                  DropdownMenuItem(value: 'snackbox', child: Text('Snack Box')),
                ],
                onChanged: (v) => setState(() => _tipe = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hargaCtrl,
                keyboardType: TextInputType.number,
                decoration: inputStyle('Harga per porsi (Rp)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: inputStyle('Min. pesanan (porsi)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _leadTimeCtrl,
                keyboardType: TextInputType.number,
                decoration: inputStyle('Waktu persiapan (hari)'),
              ),
              const SizedBox(height: 16),
              const Text('Isi Paket',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: primary)),
              const SizedBox(height: 8),
              ..._menuCtrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                            controller: e.value,
                            decoration: inputStyle('Menu ${e.key + 1}')),
                      ),
                      if (_menuCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () =>
                              setState(() => _menuCtrls.removeAt(e.key)),
                        ),
                    ]),
                  )),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _menuCtrls.add(TextEditingController())),
                icon: const Icon(Icons.add, color: primary),
                label: const Text('Tambah Item',
                    style: TextStyle(color: primary)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: primary, foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _simpan,
          child: _isLoading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _simpan() async {
    setState(() => _isLoading = true);
    try {
      final menu = _menuCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await FirebaseFirestore.instance.collection('packages').add({
        'name':      _namaCtrl.text.trim(),
        'type':      _tipe,
        'price':     int.tryParse(_hargaCtrl.text)    ?? 0,
        'min_order': int.tryParse(_minOrderCtrl.text) ?? 0,
        'lead_time': int.tryParse(_leadTimeCtrl.text) ?? 0,
        'menu_items': menu,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ================= DIALOG EDIT =================
class EditPaketDialog extends StatefulWidget {
  final String              docId;
  final Map<String, dynamic> data;
  const EditPaketDialog({super.key, required this.docId, required this.data});
  @override
  State<EditPaketDialog> createState() => _EditPaketDialogState();
}

class _EditPaketDialogState extends State<EditPaketDialog> {
  late TextEditingController _namaCtrl;
  late TextEditingController _hargaCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _leadTimeCtrl;
  late List<TextEditingController> _menuCtrls;
  late String _tipe;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl     = TextEditingController(text: widget.data['name'] ?? '');
    _hargaCtrl    = TextEditingController(
        text: (widget.data['price']     ?? 0).toString());
    _minOrderCtrl = TextEditingController(
        text: (widget.data['min_order'] ?? 0).toString());
    _leadTimeCtrl = TextEditingController(
        text: (widget.data['lead_time'] ?? 0).toString());
    _tipe = (widget.data['type'] ?? 'hajatan').toString().toLowerCase();

    final existing = List<String>.from(widget.data['menu_items'] ?? []);
    _menuCtrls = existing.isNotEmpty
        ? existing.map((e) => TextEditingController(text: e)).toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _minOrderCtrl.dispose();
    _leadTimeCtrl.dispose();
    for (final c in _menuCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Paket',
          style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _namaCtrl,
                  decoration: inputStyle('Nama Paket')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipe,
                decoration: inputStyle('Kategori'),
                items: const [
                  DropdownMenuItem(value: 'hajatan',  child: Text('Hajatan')),
                  DropdownMenuItem(value: 'tahlilan', child: Text('Tahlilan')),
                  DropdownMenuItem(value: 'snackbox', child: Text('Snack Box')),
                ],
                onChanged: (v) => setState(() => _tipe = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hargaCtrl,
                keyboardType: TextInputType.number,
                decoration: inputStyle('Harga per porsi (Rp)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: inputStyle('Min. pesanan (porsi)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _leadTimeCtrl,
                keyboardType: TextInputType.number,
                decoration: inputStyle('Waktu persiapan (hari)'),
              ),
              const SizedBox(height: 16),
              const Text('Isi Paket',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: primary)),
              const SizedBox(height: 8),
              ..._menuCtrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                            controller: e.value,
                            decoration: inputStyle('Menu ${e.key + 1}')),
                      ),
                      if (_menuCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () =>
                              setState(() => _menuCtrls.removeAt(e.key)),
                        ),
                    ]),
                  )),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _menuCtrls.add(TextEditingController())),
                icon: const Icon(Icons.add, color: primary),
                label: const Text('Tambah Item',
                    style: TextStyle(color: primary)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: primary, foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _update,
          child: _isLoading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _update() async {
    setState(() => _isLoading = true);
    try {
      final menu = _menuCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.docId)
          .update({
        'name':      _namaCtrl.text.trim(),
        'type':      _tipe,
        'price':     int.tryParse(_hargaCtrl.text)    ?? 0,
        'min_order': int.tryParse(_minOrderCtrl.text) ?? 0,
        'lead_time': int.tryParse(_leadTimeCtrl.text) ?? 0,
        'menu_items': menu,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}