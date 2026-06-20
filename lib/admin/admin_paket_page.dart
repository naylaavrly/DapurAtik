import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// ================= KONSTANTA =================
const Color primary  = Color(0xFF7A1C1C);
const Color bgColor  = Color(0xFFF5E6DA);
const Color textSoft = Color(0xFF8E8E8E);

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

// ================= MODEL KATEGORI =================
class KategoriModel {
  final String id;
  final String label;
  final Color  colorBg;
  final Color  colorText;
  final Color  colorStrip;

  KategoriModel({
    required this.id,
    required this.label,
    required this.colorBg,
    required this.colorText,
    required this.colorStrip,
  });

  factory KategoriModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return KategoriModel(
      id:         doc.id,
      label:      d['label'] ?? doc.id,
      colorBg:    Color(int.tryParse(d['color_bg']   ?? '0xFFEEEDFE') ?? 0xFFEEEDFE),
      colorText:  Color(int.tryParse(d['color_text'] ?? '0xFF3C3489') ?? 0xFF3C3489),
      colorStrip: Color(int.tryParse(d['color_strip']?? '0xFF7A1C1C') ?? 0xFF7A1C1C),
    );
  }
}

// ================= PAGE =================
class AdminPaketPage extends StatefulWidget {
  const AdminPaketPage({super.key});
  @override
  State<AdminPaketPage> createState() => _AdminPaketPageState();
}

class _AdminPaketPageState extends State<AdminPaketPage> {
  String _search     = '';
  String _filterType = 'semua';

  // Warna default per ID kategori kalau ditemukan dari packages
  static const Map<String, Map<String, dynamic>> _defaultColors = {
    'hajatan':  {'bg': '0xFFEEEDFE', 'text': '0xFF3C3489', 'strip': '0xFF534AB7'},
    'tahlilan': {'bg': '0xFFE1F5EE', 'text': '0xFF0F6E56', 'strip': '0xFF1D9E75'},
    'snackbox': {'bg': '0xFFFAEEDA', 'text': '0xFF854F0B', 'strip': '0xFFBA7517'},
  };

  @override
  void initState() {
    super.initState();
    _seedKategoriJikaKosong();
  }

  Future<void> _seedKategoriJikaKosong() async {
    // Ambil semua tipe unik dari packages
    final pkgsSnap = await FirebaseFirestore.instance
        .collection('packages')
        .get();

    final tipeSet = <String>{};
    for (final doc in pkgsSnap.docs) {
      final type = (doc.data()['type'] ?? '').toString().toLowerCase().trim();
      if (type.isNotEmpty) tipeSet.add(type);
    }

    if (tipeSet.isEmpty) return;

    // Ambil kategori yang sudah ada
    final catsSnap = await FirebaseFirestore.instance
        .collection('categories')
        .get();
    final existingIds = catsSnap.docs.map((d) => d.id).toSet();
    final lastUrutan = catsSnap.docs.isEmpty
        ? 0
        : catsSnap.docs
            .map((d) => (d.data()['urutan'] ?? 0) as int)
            .reduce((a, b) => a > b ? a : b);

    // Hanya seed tipe yang BELUM ada di categories
    final belumAda = tipeSet.where((t) => !existingIds.contains(t)).toList();
    if (belumAda.isEmpty) return;

    // Urutkan: yang dikenal duluan, sisanya alphabetical
    const urutanDikenal = ['hajatan', 'tahlilan', 'snackbox'];
    final sisanya = belumAda.where((t) => !urutanDikenal.contains(t)).toList()
      ..sort();
    final sorted = [
      ...urutanDikenal.where((t) => belumAda.contains(t)),
      ...sisanya,
    ];

    // Preset warna fallback
    const fallbackPresets = [
      {'bg': '0xFFE6F1FB', 'text': '0xFF0C447C', 'strip': '0xFF185FA5'},
      {'bg': '0xFFFBEAF0', 'text': '0xFF72243E', 'strip': '0xFF993556'},
      {'bg': '0xFFF1EFE8', 'text': '0xFF444441', 'strip': '0xFF5F5E5A'},
      {'bg': '0xFFFCEBEB', 'text': '0xFF791F1F', 'strip': '0xFF7A1C1C'},
    ];
    int fallbackIdx = 0;

    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < sorted.length; i++) {
      final id     = sorted[i];
      final colors = _defaultColors[id] ??
          fallbackPresets[fallbackIdx++ % fallbackPresets.length];
      final ref    = FirebaseFirestore.instance
          .collection('categories')
          .doc(id);

      // Label: capitalize tiap kata, snackbox → Snack Box
      String label = id.replaceAll('_', ' ');
      if (id == 'snackbox') label = 'Snack Box';
      label = label
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');

      batch.set(ref, {
        'label':       label,
        'urutan':      lastUrutan + i + 1,
        'color_bg':    colors['bg'],
        'color_text':  colors['text'],
        'color_strip': colors['strip'],
      });
    }

    await batch.commit();
  }

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

              // ===== JUDUL + TOMBOL KELOLA KATEGORI =====
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Kelola Paket',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AdminKategoriDialog(),
                    ),
                    icon: const Icon(Icons.category_outlined,
                        color: primary, size: 18),
                    label: const Text('Kategori',
                        style: TextStyle(color: primary, fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== TOOLBAR =====
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) =>
                          setState(() => _search = v.toLowerCase()),
                      decoration: inputStyle('Cari paket...').copyWith(
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filter — baca dari Firestore
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .orderBy('urutan')
                        .snapshots(),
                    builder: (context, snap) {
                      final cats = snap.hasData
                          ? snap.data!.docs
                              .map(KategoriModel.fromDoc)
                              .toList()
                          : <KategoriModel>[];
                      return PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filter kategori',
                        onSelected: (v) =>
                            setState(() => _filterType = v),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'semua',
                              child: Text('Semua')),
                          ...cats.map((c) => PopupMenuItem(
                              value: c.id,
                              child: Text(c.label))),
                        ],
                      );
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: primary, size: 32),
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
                      .collection('categories')
                      .orderBy('urutan')
                      .snapshots(),
                  builder: (context, catSnap) {
                    if (!catSnap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final categories = catSnap.data!.docs
                        .map(KategoriModel.fromDoc)
                        .toList();

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('packages')
                          .snapshots(),
                      builder: (context, pkgSnap) {
                        if (!pkgSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // Filter & sort
                        final allDocs =
                            pkgSnap.data!.docs.where((doc) {
                          final d = doc.data()
                              as Map<String, dynamic>;
                          final name = (d['name'] ?? '')
                              .toString()
                              .toLowerCase();
                          final type = (d['type'] ?? '')
                              .toString()
                              .toLowerCase();
                          final matchSearch =
                              name.contains(_search);
                          final matchType =
                              _filterType == 'semua' ||
                                  type == _filterType;
                          return matchSearch && matchType;
                        }).toList();

                        // Urutan section = urutan dari Firestore categories
                        final catIds =
                            categories.map((c) => c.id).toList();

                        allDocs.sort((a, b) {
                          final da =
                              a.data() as Map<String, dynamic>;
                          final db =
                              b.data() as Map<String, dynamic>;
                          final ta = (da['type'] ?? '')
                              .toString()
                              .toLowerCase();
                          final tb = (db['type'] ?? '')
                              .toString()
                              .toLowerCase();
                          final oa = catIds.indexOf(ta);
                          final ob = catIds.indexOf(tb);
                          final ia = oa < 0 ? 99 : oa;
                          final ib = ob < 0 ? 99 : ob;
                          if (ia != ib) return ia.compareTo(ib);
                          return (da['name'] ?? '')
                              .toString()
                              .toLowerCase()
                              .compareTo((db['name'] ?? '')
                                  .toString()
                                  .toLowerCase());
                        });

                        if (allDocs.isEmpty) {
                          return const Center(
                              child:
                                  Text('Paket tidak ditemukan'));
                        }

                        // Kelompokkan per kategori
                        final Map<String,
                                List<QueryDocumentSnapshot>>
                            grouped = {};
                        for (final doc in allDocs) {
                          final type = ((doc.data()
                                      as Map<String, dynamic>)[
                                      'type'] ??
                                  '')
                              .toString()
                              .toLowerCase();
                          grouped
                              .putIfAbsent(type, () => [])
                              .add(doc);
                        }

                        // Section sesuai urutan kategori
                        final sections = [
                          ...catIds
                              .where((id) => grouped.containsKey(id)),
                          ...grouped.keys.where(
                              (k) => !catIds.contains(k)),
                        ];

                        final crossCount = screenW < 700
                            ? 1
                            : screenW < 1100
                                ? 2
                                : 3;

                        return ListView.builder(
                          itemCount: sections.length,
                          itemBuilder: (context, si) {
                            final typeId  = sections[si];
                            final items   = grouped[typeId]!;
                            final katModel = categories
                                .where((c) => c.id == typeId)
                                .firstOrNull;
                            final label = katModel?.label ??
                                typeId;
                            final badgeBg =
                                katModel?.colorBg ??
                                    primary.withOpacity(0.1);
                            final badgeText =
                                katModel?.colorText ?? primary;

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                // SECTION HEADER
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 4, bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 12,
                                            vertical: 5),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                        ),
                                        child: Text(
                                          label,
                                          style:
                                              GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: badgeText,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Container(
                                              height: 1,
                                              color:
                                                  Colors.black12)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${items.length} paket',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: textSoft),
                                      ),
                                    ],
                                  ),
                                ),

                                // GRID KARTU OPSI B
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: 210,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, ii) {
                                    final doc  = items[ii];
                                    final d    = doc.data()
                                        as Map<String, dynamic>;
                                    final menu = List<String>.from(
                                        d['menu_items'] ?? []);
                                    final harga =
                                        d['price'] ?? 0;
                                    final minOrder =
                                        d['min_order'] ?? 0;
                                    final leadTime =
                                        d['lead_time'] ?? 0;
                                    final stripColor =
                                        katModel?.colorStrip ??
                                            primary;
                                    final extraMenu = menu.length > 3
                                        ? menu.length - 3
                                        : 0;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(
                                                14),
                                        border: Border.all(
                                          color: Colors.black
                                              .withOpacity(0.07),
                                        ),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [

                                          // TOP STRIP
                                          Container(
                                            height: 4,
                                            color: stripColor,
                                          ),

                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .fromLTRB(
                                                      14, 10, 14, 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [

                                                  // Badge kategori
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal:
                                                            8,
                                                        vertical:
                                                            2),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: badgeBg,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  20),
                                                    ),
                                                    child: Text(
                                                      label,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                        color:
                                                            badgeText,
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(
                                                      height: 6),

                                                  // Nama + harga
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          d['name'] ??
                                                              '-',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize:
                                                                13,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            color: const Color(
                                                                0xFF1A1A1A),
                                                          ),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 6),
                                                      Text(
                                                        'Rp $harga',
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                          color:
                                                              primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(
                                                      height: 8),

                                                  // Divider
                                                  Container(
                                                      height: 0.5,
                                                      color: Colors
                                                          .black12),

                                                  const SizedBox(
                                                      height: 8),

                                                  // Min pesanan + persiapan
                                                  Row(
                                                    children: [
                                                      _StatItem(
                                                        label:
                                                            'Min. pesan',
                                                        value:
                                                            '$minOrder porsi',
                                                      ),
                                                      const SizedBox(
                                                          width: 16),
                                                      _StatItem(
                                                        label:
                                                            'Persiapan',
                                                        value:
                                                            '$leadTime hari',
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(
                                                      height: 8),

                                                  // Chip menu
                                                  Expanded(
                                                    child: Wrap(
                                                      spacing: 4,
                                                      runSpacing: 4,
                                                      children: [
                                                        ...menu
                                                            .take(3)
                                                            .map(
                                                              (e) =>
                                                                  _MenuChip(
                                                                      label:
                                                                          e),
                                                            ),
                                                        if (extraMenu >
                                                            0)
                                                          _MenuChip(
                                                              label:
                                                                  '+$extraMenu lainnya',
                                                              muted:
                                                                  true),
                                                      ],
                                                    ),
                                                  ),

                                                  // Footer: aksi
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .end,
                                                    children: [
                                                      _ActionBtn(
                                                        icon: Icons
                                                            .edit_outlined,
                                                        color: primary,
                                                        tooltip:
                                                            'Edit',
                                                        onTap: () =>
                                                            showDialog(
                                                          context:
                                                              context,
                                                          builder: (_) =>
                                                              EditPaketDialog(
                                                                  docId:
                                                                      doc.id,
                                                                  data:
                                                                      d),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 4),
                                                      _ActionBtn(
                                                        icon: Icons
                                                            .delete_outline,
                                                        color:
                                                            Colors.red,
                                                        tooltip:
                                                            'Hapus',
                                                        onTap: () =>
                                                            _confirmDelete(
                                                                context,
                                                                doc.id),
                                                      ),
                                                    ],
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

                                const SizedBox(height: 20),
                              ],
                            );
                          },
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
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: textSoft)),
          const SizedBox(height: 1),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
        ],
      );
}

class _MenuChip extends StatelessWidget {
  final String label;
  final bool   muted;
  const _MenuChip({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: muted
              ? Colors.transparent
              : const Color(0xFFF5F0ED),
          border: Border.all(
              color: muted ? Colors.black12 : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 10,
              color: muted ? textSoft : const Color(0xFF555555)),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
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
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      );
}

// ================= DIALOG KELOLA KATEGORI =================
class AdminKategoriDialog extends StatefulWidget {
  const AdminKategoriDialog({super.key});
  @override
  State<AdminKategoriDialog> createState() =>
      _AdminKategoriDialogState();
}

class _AdminKategoriDialogState extends State<AdminKategoriDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('Kelola Kategori',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: primary)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: primary),
            tooltip: 'Tambah kategori',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _TambahEditKategoriDialog(),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('categories')
              .orderBy('urutan')
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox(
                  height: 80,
                  child: Center(
                      child: CircularProgressIndicator()));
            }

            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('Belum ada kategori.',
                        style: TextStyle(color: textSoft))),
              );
            }

            return SizedBox(
              height: 320,
              child: ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d =
                      doc.data() as Map<String, dynamic>;
                  final kat = KategoriModel.fromDoc(doc);

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kat.colorBg,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          kat.label[0].toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kat.colorText),
                        ),
                      ),
                    ),
                    title: Text(kat.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    subtitle: Text('ID: ${kat.id}',
                        style: const TextStyle(
                            fontSize: 11, color: textSoft)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: primary),
                          tooltip: 'Edit',
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) =>
                                _TambahEditKategoriDialog(
                                    docId: doc.id, data: d),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red),
                          tooltip: 'Hapus',
                          onPressed: () =>
                              _hapusKategori(context, doc.id, kat.label),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup')),
      ],
    );
  }

  void _hapusKategori(
      BuildContext context, String docId, String label) async {
    // Cek apakah masih ada paket yang pakai kategori ini
    final pkgs = await FirebaseFirestore.instance
        .collection('packages')
        .where('type', isEqualTo: docId)
        .limit(1)
        .get();

    if (!context.mounted) return;

    if (pkgs.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tidak bisa dihapus'),
          content: Text(
              'Kategori "$label" masih dipakai oleh beberapa paket. Hapus atau pindahkan paketnya terlebih dahulu.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary),
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content:
            Text('Yakin hapus kategori "$label"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('categories')
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

// ================= DIALOG TAMBAH / EDIT KATEGORI =================

// Pilihan warna preset
const List<Map<String, dynamic>> _colorPresets = [
  {'label': 'Merah Tua',  'bg': 0xFFFCEBEB, 'text': 0xFF791F1F, 'strip': 0xFF7A1C1C},
  {'label': 'Ungu',       'bg': 0xFFEEEDFE, 'text': 0xFF3C3489, 'strip': 0xFF534AB7},
  {'label': 'Hijau',      'bg': 0xFFE1F5EE, 'text': 0xFF0F6E56, 'strip': 0xFF1D9E75},
  {'label': 'Amber',      'bg': 0xFFFAEEDA, 'text': 0xFF854F0B, 'strip': 0xFFBA7517},
  {'label': 'Biru',       'bg': 0xFFE6F1FB, 'text': 0xFF0C447C, 'strip': 0xFF185FA5},
  {'label': 'Pink',       'bg': 0xFFFBEAF0, 'text': 0xFF72243E, 'strip': 0xFF993556},
  {'label': 'Abu',        'bg': 0xFFF1EFE8, 'text': 0xFF444441, 'strip': 0xFF5F5E5A},
];

class _TambahEditKategoriDialog extends StatefulWidget {
  final String?              docId;
  final Map<String, dynamic>? data;
  const _TambahEditKategoriDialog({this.docId, this.data});
  @override
  State<_TambahEditKategoriDialog> createState() =>
      _TambahEditKategoriDialogState();
}

class _TambahEditKategoriDialogState
    extends State<_TambahEditKategoriDialog> {
  late TextEditingController _labelCtrl;
  int _selectedColor = 0;
  bool _isLoading    = false;
  bool _isEdit       = false;

  @override
  void initState() {
    super.initState();
    _isEdit    = widget.docId != null;
    _labelCtrl = TextEditingController(
        text: widget.data?['label'] ?? '');

    // Cari preset warna yang cocok
    if (widget.data != null) {
      final bgVal = int.tryParse(
              widget.data!['color_bg'] ?? '') ??
          0xFFEEEDFE;
      final idx = _colorPresets.indexWhere(
          (p) => p['bg'] == bgVal);
      if (idx >= 0) _selectedColor = idx;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  // Auto-generate ID dari label
  String _generateId(String label) => label
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '');

  @override
  Widget build(BuildContext context) {
    // Preview ID otomatis
    final previewId = _isEdit
        ? widget.docId!
        : _generateId(_labelCtrl.text);

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Kategori' : 'Tambah Kategori',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: primary)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _labelCtrl,
                decoration: inputStyle('Nama Kategori'),
                onChanged: (_) => setState(() {}), // rebuild preview ID
              ),

              // Preview ID otomatis
              if (!_isEdit && _labelCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 13, color: textSoft),
                    const SizedBox(width: 4),
                    Text(
                      'ID: $previewId',
                      style: const TextStyle(
                          fontSize: 12, color: textSoft),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              const Text('Warna',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary)),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorPresets
                    .asMap()
                    .entries
                    .map((e) {
                  final selected = _selectedColor == e.key;
                  final preset   = e.value;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColor = e.key),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(preset['bg'] as int),
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Color(
                                  preset['strip'] as int)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        preset['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color:
                              Color(preset['text'] as int),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
              backgroundColor: primary,
              foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _simpan,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(_isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }

  Future<void> _simpan() async {
    final label = _labelCtrl.text.trim();
    final id    = _isEdit ? widget.docId! : _generateId(label);

    if (label.isEmpty || id.isEmpty) return;

    setState(() => _isLoading = true);

    final preset = _colorPresets[_selectedColor];
    final data = {
      'label':       label,
      'color_bg':    '0x${(preset['bg'] as int).toRadixString(16).toUpperCase()}',
      'color_text':  '0x${(preset['text'] as int).toRadixString(16).toUpperCase()}',
      'color_strip': '0x${(preset['strip'] as int).toRadixString(16).toUpperCase()}',
    };

    try {
      if (_isEdit) {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.docId)
            .update(data);
      } else {
        // Hitung urutan terakhir
        final snap = await FirebaseFirestore.instance
            .collection('categories')
            .orderBy('urutan', descending: true)
            .limit(1)
            .get();
        final lastUrutan = snap.docs.isEmpty
            ? 0
            : (snap.docs.first.data()['urutan'] ?? 0) as int;

        await FirebaseFirestore.instance
            .collection('categories')
            .doc(id)
            .set({...data, 'urutan': lastUrutan + 1});
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ================= DIALOG TAMBAH PAKET =================
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
  final List<TextEditingController> _menuCtrls = [
    TextEditingController()
  ];

  String? _tipe;
  bool    _isLoading = false;

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
          style: TextStyle(
              fontWeight: FontWeight.bold, color: primary)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: _namaCtrl,
                  decoration: inputStyle('Nama Paket')),
              const SizedBox(height: 12),

              // Dropdown kategori dinamis
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .orderBy('urutan')
                    .snapshots(),
                builder: (context, snap) {
                  final cats = snap.hasData
                      ? snap.data!.docs
                          .map(KategoriModel.fromDoc)
                          .toList()
                      : <KategoriModel>[];

                  return DropdownButtonFormField<String>(
                    value: _tipe,
                    decoration: inputStyle('Kategori'),
                    hint: const Text('Pilih kategori'),
                    items: cats
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.label),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _tipe = v),
                  );
                },
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
                decoration:
                    inputStyle('Waktu persiapan (hari)'),
              ),
              const SizedBox(height: 16),

              const Text('Isi Paket',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary)),
              const SizedBox(height: 8),

              ..._menuCtrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                            controller: e.value,
                            decoration:
                                inputStyle('Menu ${e.key + 1}')),
                      ),
                      if (_menuCtrls.length > 1)
                        IconButton(
                          icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => setState(
                              () => _menuCtrls.removeAt(e.key)),
                        ),
                    ]),
                  )),

              TextButton.icon(
                onPressed: () => setState(() =>
                    _menuCtrls.add(TextEditingController())),
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
              backgroundColor: primary,
              foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _simpan,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _simpan() async {
    if (_tipe == null) return;
    setState(() => _isLoading = true);
    try {
      final menu = _menuCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await FirebaseFirestore.instance
          .collection('packages')
          .add({
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

// ================= DIALOG EDIT PAKET =================
class EditPaketDialog extends StatefulWidget {
  final String               docId;
  final Map<String, dynamic> data;
  const EditPaketDialog(
      {super.key, required this.docId, required this.data});
  @override
  State<EditPaketDialog> createState() =>
      _EditPaketDialogState();
}

class _EditPaketDialogState extends State<EditPaketDialog> {
  late TextEditingController _namaCtrl;
  late TextEditingController _hargaCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _leadTimeCtrl;
  late List<TextEditingController> _menuCtrls;
  String? _tipe;
  bool    _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl     = TextEditingController(
        text: widget.data['name'] ?? '');
    _hargaCtrl    = TextEditingController(
        text: (widget.data['price']     ?? 0).toString());
    _minOrderCtrl = TextEditingController(
        text: (widget.data['min_order'] ?? 0).toString());
    _leadTimeCtrl = TextEditingController(
        text: (widget.data['lead_time'] ?? 0).toString());
    _tipe = (widget.data['type'] ?? '').toString();

    final existing =
        List<String>.from(widget.data['menu_items'] ?? []);
    _menuCtrls = existing.isNotEmpty
        ? existing
            .map((e) => TextEditingController(text: e))
            .toList()
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
          style: TextStyle(
              fontWeight: FontWeight.bold, color: primary)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: _namaCtrl,
                  decoration: inputStyle('Nama Paket')),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .orderBy('urutan')
                    .snapshots(),
                builder: (context, snap) {
                  final cats = snap.hasData
                      ? snap.data!.docs
                          .map(KategoriModel.fromDoc)
                          .toList()
                      : <KategoriModel>[];

                  // Pastikan nilai _tipe ada di list
                  final validIds =
                      cats.map((c) => c.id).toList();
                  final currentTipe =
                      validIds.contains(_tipe) ? _tipe : null;

                  return DropdownButtonFormField<String>(
                    value: currentTipe,
                    decoration: inputStyle('Kategori'),
                    hint: const Text('Pilih kategori'),
                    items: cats
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.label),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _tipe = v),
                  );
                },
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
                decoration:
                    inputStyle('Waktu persiapan (hari)'),
              ),
              const SizedBox(height: 16),

              const Text('Isi Paket',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary)),
              const SizedBox(height: 8),

              ..._menuCtrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                            controller: e.value,
                            decoration:
                                inputStyle('Menu ${e.key + 1}')),
                      ),
                      if (_menuCtrls.length > 1)
                        IconButton(
                          icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => setState(
                              () => _menuCtrls.removeAt(e.key)),
                        ),
                    ]),
                  )),

              TextButton.icon(
                onPressed: () => setState(() =>
                    _menuCtrls.add(TextEditingController())),
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
              backgroundColor: primary,
              foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _update,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _update() async {
    if (_tipe == null) return;
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