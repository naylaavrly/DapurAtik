import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ============================================================
// 🎨 DESIGN TOKENS
// ============================================================
const Color primary      = Color(0xFF7A1C1C);
const Color primaryLight = Color(0xFFB23A3A);
const Color primarySoft  = Color(0xFFFFF0F0);
const Color bgPage       = Color(0xFFF5E6DA);
const Color bgCard       = Color(0xFFFFFFFF);
const Color textDark     = Color(0xFF1A1A1A);
const Color textMuted    = Color(0xFF9E9E9E);
const Color colSuccess   = Color(0xFF2E7D32);
const Color bgSuccess    = Color(0xFFE8F5E9);
const Color colWarning   = Color(0xFFE65100);
const Color bgWarning    = Color(0xFFFFF3E0);
const Color colInfo      = Color(0xFF1565C0);
const Color bgInfo       = Color(0xFFE3F2FD);

const String sMenunggu   = 'Menunggu Konfirmasi';
const String sDiproses   = 'Diproses';
const String sSelesai    = 'Selesai';
const String sDibatalkan = 'Dibatalkan';

TextStyle _p({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = textDark,
  double? height,
}) =>
    GoogleFonts.poppins(
        fontSize: size, fontWeight: weight, color: color, height: height);

String _formatRp(dynamic val) {
  final n = (val is int) ? val : (int.tryParse('$val') ?? 0);
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp ${buf.toString()}';
}

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
    case sMenunggu:   return {'label': 'Menunggu', 'color': colWarning, 'bg': bgWarning};
    case sDiproses:   return {'label': 'Diproses', 'color': colInfo,    'bg': bgInfo};
    case sSelesai:    return {'label': 'Selesai',  'color': colSuccess,  'bg': bgSuccess};
    default:          return {'label': 'Dibatalkan','color': textMuted,  'bg': const Color(0xFFF5F5F5)};
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1)  return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

// ============================================================
// 🏠 ADMIN DASHBOARD
// ============================================================
class AdminDashboard extends StatefulWidget {
  final void Function(int)? onNavigateTo;
  final VoidCallback?        onOpenNotif;

  const AdminDashboard({
    super.key,
    this.onNavigateTo,
    this.onOpenNotif,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPage,
      // Hapus AppBar bawaan — tidak ada back button
      body: FadeTransition(
        opacity: _fadeAnim,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .snapshots(),
          builder: (context, snap) {
            final orders = snap.data?.docs ?? [];

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Sticky Header (tanpa back button) ──
                SliverAppBar(
                  automaticallyImplyLeading: false, // ← hapus back button
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: bgCard,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: _buildHeader(orders),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                        height: 1, color: const Color(0xFFEEEEEE)),
                  ),
                ),

                SliverPadding(
                  // Tambah bottom padding agar konten tidak ketutup navbar
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SummaryRow(orders: orders),
                      const SizedBox(height: 20),
                      _RecentOrdersCard(
                        orders: orders,
                        onLihatSemua: () =>
                            widget.onNavigateTo?.call(2),
                      ),
                      const SizedBox(height: 20),
                      // Dua grafik side-by-side di layar lebar, stack di mobile
                      _ChartRow(orders: orders),
                      const SizedBox(height: 20),
                      _TopPackagesCard(orders: orders),
                      const SizedBox(height: 20),
                      _LaporanCard(orders: orders),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(List<QueryDocumentSnapshot> orders) {
    final unseen = orders.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return _normalizeStatus(data['status']) == sMenunggu &&
          data['is_seen'] != true;
    }).length;

    return Container(
      color: bgCard,
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${_greeting()}, Admin 👋',
                    style: _p(
                        size: 12,
                        weight: FontWeight.w600,
                        color: primary)),
                Text('Dapur Atik',
                    style: _p(
                        size: 22,
                        weight: FontWeight.w800,
                        color: textDark)),
              ],
            ),
          ),

          // Bell — buka EndDrawer di AdminHome
          GestureDetector(
            onTap: widget.onOpenNotif,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primarySoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.notifications_rounded,
                      color: primary, size: 22),
                ),
                if (unseen > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                          minWidth: 17, minHeight: 17),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          unseen > 9 ? '9+' : '$unseen',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 📊 SUMMARY ROW
// ============================================================
class _SummaryRow extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _SummaryRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    final total   = orders.length;
    final proses  = orders.where((d) =>
        _normalizeStatus((d.data() as Map)['status']) == sDiproses).length;
    final selesai = orders.where((d) =>
        _normalizeStatus((d.data() as Map)['status']) == sSelesai).length;
    int pendapatan = 0;
    for (final d in orders) {
      final data = d.data() as Map<String, dynamic>;
      if (_normalizeStatus(data['status']) == sSelesai) {
        pendapatan += (data['grand_total'] ?? 0) as int;
      }
    }

    return Row(children: [
      Expanded(child: _SummaryCard(
          icon: Icons.receipt_long_rounded,
          label: 'Pesanan',
          value: '$total',
          color: primary)),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(
          icon: Icons.local_fire_department_rounded,
          label: 'Diproses',
          value: '$proses',
          color: colInfo)),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(
          icon: Icons.check_circle_rounded,
          label: 'Selesai',
          value: '$selesai',
          color: colSuccess)),
      const SizedBox(width: 10),
      Expanded(child: _SummaryCard(
          icon: Icons.trending_up_rounded,
          label: 'Pendapatan',
          value: _formatRp(pendapatan),
          color: colWarning,
          smallText: true)),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final bool     smallText;
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.smallText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: _p(
                  size: smallText ? 12 : 18,
                  weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: _p(
                  size: 10,
                  color: textMuted,
                  weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================
// 🕐 PESANAN TERBARU
// ============================================================
class _RecentOrdersCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  final VoidCallback? onLihatSemua;
  const _RecentOrdersCard(
      {required this.orders, this.onLihatSemua});

  @override
  Widget build(BuildContext context) {
    final recent = [...orders]..sort((a, b) {
        final ta =
            ((a.data() as Map)['created_at'] as Timestamp?)
                ?.toDate() ??
                DateTime(2000);
        final tb =
            ((b.data() as Map)['created_at'] as Timestamp?)
                ?.toDate() ??
                DateTime(2000);
        return tb.compareTo(ta);
      });
    final preview = recent.take(5).toList();

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pesanan Terbaru',
                      style: _p(size: 15, weight: FontWeight.w700)),
                  Text('Update real-time',
                      style: _p(size: 11, color: textMuted)),
                ],
              ),
            ),
            // Live badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: primary, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('Live',
                    style: _p(
                        size: 10,
                        weight: FontWeight.w700,
                        color: primary)),
              ]),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onLihatSemua,
              style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4)),
              child: Text('Lihat semua',
                  style: _p(
                      size: 12,
                      weight: FontWeight.w600,
                      color: primary)),
            ),
          ]),

          const SizedBox(height: 12),

          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child:
                      Text('Belum ada pesanan', style: _p(color: textMuted))),
            )
          else
            ...preview.map((doc) {
              final d      = doc.data() as Map<String, dynamic>;
              final status = _normalizeStatus(d['status']);
              final nama   = d['nama_pemesan'] ?? '-';
              final total  = (d['grand_total'] ?? 0) as int;
              final ts     = (d['created_at'] as Timestamp?)?.toDate();
              final cfg    = _statusCfg(status);
              final shortId = doc.id.length > 6
                  ? doc.id.substring(0, 6).toUpperCase()
                  : doc.id.toUpperCase();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: bgPage,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: primarySoft,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_rounded,
                        color: primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nama,
                            style: _p(
                                size: 12, weight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                            '#$shortId · ${ts != null ? _timeAgo(ts) : ''}',
                            style: _p(size: 10, color: textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatRp(total),
                          style: _p(
                              size: 12,
                              weight: FontWeight.w700,
                              color: primary)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: cfg['bg'],
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(cfg['label'],
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: cfg['color'])),
                      ),
                    ],
                  ),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

// ============================================================
// 📈📊 CHART ROW — dua grafik berdampingan
// ============================================================
class _ChartRow extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _ChartRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _TrendLineChart(orders: orders)),
          const SizedBox(width: 16),
          Expanded(child: _CategoryBarChart(orders: orders)),
        ],
      );
    }
    return Column(children: [
      _TrendLineChart(orders: orders),
      const SizedBox(height: 16),
      _CategoryBarChart(orders: orders),
    ]);
  }
}

// ── Line Chart ──
class _TrendLineChart extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _TrendLineChart({required this.orders});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(7, 0);
    const days   = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      labels.add(days[day.weekday % 7]);
    }
    for (final doc in orders) {
      final d  = doc.data() as Map<String, dynamic>;
      final ts = (d['created_at'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final dayTs = DateTime(ts.year, ts.month, ts.day);
      final diff  = today.difference(dayTs).inDays;
      if (diff >= 0 && diff < 7) counts[6 - diff]++;
    }

    final spots = List.generate(
        7, (i) => FlSpot(i.toDouble(), counts[i].toDouble()));
    final maxY =
    ((counts.reduce((a, b) => a > b ? a : b) + 2)
            .toDouble()
            .clamp(4.0, double.infinity))
        .toDouble();

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tren Pesanan',
              style: _p(size: 14, weight: FontWeight.w700)),
          Text('7 hari terakhir',
              style: _p(size: 11, color: textMuted)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 3,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF0F0F0), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labels[i],
                            style: _p(size: 9, color: textMuted)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => primary,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${s.y.toInt()}',
                            const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  gradient: const LinearGradient(
                      colors: [primary, primaryLight]),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: primary,
                      strokeColor: Colors.white,
                      strokeWidth: 1.5,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        primary.withOpacity(0.12),
                        primary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

// ── Bar Chart ──
class _CategoryBarChart extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _CategoryBarChart({required this.orders});

  @override
  Widget build(BuildContext context) {
    // Hitung per kategori dari semua orders (bukan cuma selesai)
    // — supaya data muncul meski belum ada yang selesai
    final Map<String, int> countPerKat = {};
    for (final doc in orders) {
      final d     = doc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(d['items'] ?? []);
      for (final item in items) {
        final kat = (item['type'] ?? 'lainnya').toString().toLowerCase().trim();
        if (kat.isNotEmpty) countPerKat[kat] = (countPerKat[kat] ?? 0) + 1;
      }
    }

    final barColors = [primary, primaryLight, colWarning, colInfo, colSuccess];

    if (countPerKat.isEmpty) {
      return _DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesanan per Kategori',
                style: _p(size: 14, weight: FontWeight.w700)),
            Text('Berdasarkan semua pesanan',
                style: _p(size: 11, color: textMuted)),
            const SizedBox(height: 30),
            Center(child: Text('Belum ada data', style: _p(color: textMuted))),
            const SizedBox(height: 30),
          ],
        ),
      );
    }

    final keys   = countPerKat.keys.toList();
    final maxVal = countPerKat.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pesanan per Kategori',
              style: _p(size: 14, weight: FontWeight.w700)),
          Text('Berdasarkan semua pesanan',
              style: _p(size: 11, color: textMuted)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(BarChartData(
              maxY: maxVal * 1.25,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxVal / 3,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF0F0F0), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= keys.length) return const SizedBox();
                      String lbl = keys[i] == 'snackbox' ? 'Snack' : keys[i];
                      lbl = lbl.length > 7 ? '${lbl.substring(0, 6)}.' : lbl;
                      lbl = lbl[0].toUpperCase() + lbl.substring(1);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(lbl,
                            style: _p(size: 9, color: textMuted)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => primary,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, _, rod, __) {
                    String lbl = keys[group.x];
                    if (lbl == 'snackbox') lbl = 'Snack Box';
                    lbl = lbl[0].toUpperCase() + lbl.substring(1);
                    return BarTooltipItem(
                      '$lbl\n${rod.toY.toInt()} pesanan',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              barGroups: keys.asMap().entries.map((e) {
                final color = barColors[e.key % barColors.length];
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: (countPerKat[e.value] ?? 0).toDouble(),
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    width: (200 / keys.length).clamp(16, 36),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ]);
              }).toList(),
            )),
          ),

          // Legend
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: keys.asMap().entries.map((e) {
              final color = barColors[e.key % barColors.length];
              String lbl = e.value == 'snackbox' ? 'Snack Box' : e.value;
              lbl = lbl[0].toUpperCase() + lbl.substring(1);
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text(lbl, style: _p(size: 10, color: textMuted)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🏆 TOP PAKET
// ============================================================
class _TopPackagesCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _TopPackagesCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> sold = {};
    for (final doc in orders) {
      final d     = doc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(d['items'] ?? []);
      for (final item in items) {
        final name = (item['name'] ?? '').toString();
        if (name.isEmpty) continue;
        sold[name] = (sold[name] ?? 0) + ((item['qty'] ?? 1) as int);
      }
    }
    final sorted = sold.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top    = sorted.take(4).toList();
    final maxSold= top.isEmpty ? 1 : top.first.value;

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paket Terlaris',
              style: _p(size: 15, weight: FontWeight.w700)),
          Text('Berdasarkan jumlah dipesan',
              style: _p(size: 11, color: textMuted)),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text('Belum ada data', style: _p(color: textMuted)),
              ),
            )
          else
            ...top.asMap().entries.map((e) {
              final rank  = e.key + 1;
              final name  = e.value.key;
              final count = e.value.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFFFF8E1)
                          : primarySoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: rank == 1
                          ? const Text('🥇',
                              style: TextStyle(fontSize: 14))
                          : Text('#$rank',
                              style: _p(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: primary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: _p(
                                size: 12, weight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: count / maxSold,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFF0F0F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                rank == 1 ? primary : primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$count',
                      style: _p(
                          size: 12,
                          weight: FontWeight.w700,
                          color: primary)),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

// ============================================================
// 🖨️ CETAK LAPORAN
// ============================================================
class _LaporanCard extends StatefulWidget {
  final List<QueryDocumentSnapshot> orders;
  const _LaporanCard({required this.orders});
  @override
  State<_LaporanCard> createState() => _LaporanCardState();
}

class _LaporanCardState extends State<_LaporanCard> {
  String         _filterStatus = 'semua';
  String         _filterKat    = 'semua';
  DateTime?      _startDate;
  DateTime?      _endDate;

  // Ambil semua kategori unik dari orders
  Map<String, String> get _katItems {
    final cats = <String, String>{'semua': 'Semua Kategori'};
    for (final doc in widget.orders) {
      final d     = doc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(d['items'] ?? []);
      for (final item in items) {
        final kat = (item['type'] ?? '').toString().toLowerCase().trim();
        if (kat.isNotEmpty && !cats.containsKey(kat)) {
          String label = kat == 'snackbox' ? 'Snack Box' : kat;
          label = label[0].toUpperCase() + label.substring(1);
          cats[kat] = label;
        }
      }
    }
    return cats;
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            surface: bgCard,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: primary),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end jika sebelum start
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  List<QueryDocumentSnapshot> get _filtered {
    return widget.orders.where((doc) {
      final d      = doc.data() as Map<String, dynamic>;
      final status = _normalizeStatus(d['status']);
      final ts     = (d['created_at'] as Timestamp?)?.toDate();

      final matchStatus =
          _filterStatus == 'semua' || status == _filterStatus;

      bool matchKat = true;
      if (_filterKat != 'semua') {
        final items =
            List<Map<String, dynamic>>.from(d['items'] ?? []);
        matchKat = items.any((item) =>
            (item['type'] ?? '').toString().toLowerCase().trim() ==
            _filterKat);
      }

      bool matchDate = true;
      if (_startDate != null && ts != null) {
        matchDate = !ts.isBefore(
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day));
      }
      if (_endDate != null && ts != null) {
        matchDate = matchDate &&
            !ts.isAfter(DateTime(
                _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59));
      }

      return matchStatus && matchKat && matchDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final katItems = _katItems;
    // Pastikan value valid
    final katValue =
        katItems.containsKey(_filterKat) ? _filterKat : 'semua';

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.print_rounded, color: primary, size: 18),
            const SizedBox(width: 8),
            Text('Cetak Laporan',
                style: _p(size: 15, weight: FontWeight.w700)),
          ]),
          Text('Filter lalu preview & cetak sebagai PDF',
              style: _p(size: 11, color: textMuted)),

          const SizedBox(height: 16),

          // Filter status
          _dropdownFilter(
            label: 'Status',
            value: _filterStatus,
            items: const {
              'semua':    'Semua Status',
              sMenunggu:  'Menunggu Konfirmasi',
              sDiproses:  'Diproses',
              sSelesai:   'Selesai',
              sDibatalkan:'Dibatalkan',
            },
            onChanged: (v) => setState(() => _filterStatus = v!),
          ),

          const SizedBox(height: 10),

          // Filter kategori — dari data real
          _dropdownFilter(
            label: 'Kategori',
            value: katValue,
            items: katItems,
            onChanged: (v) => setState(() => _filterKat = v!),
          ),

          const SizedBox(height: 10),

          // Date range — dua input kecil berdampingan
          Row(children: [
            Expanded(child: _datePicker(
              label: 'Dari Tanggal',
              value: _startDate,
              onTap: () => _pickDate(true),
              onClear: () => setState(() => _startDate = null),
            )),
            const SizedBox(width: 10),
            Expanded(child: _datePicker(
              label: 'Sampai Tanggal',
              value: _endDate,
              onTap: () => _pickDate(false),
              onClear: () => setState(() => _endDate = null),
            )),
          ]),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showPreview(_filtered),
              icon: const Icon(Icons.preview_rounded, size: 17),
              label: Text('Lihat Preview & Cetak',
                  style: _p(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownFilter({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _p(size: 11, color: textMuted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F3EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.containsKey(value) ? value : items.keys.first,
              isExpanded: true,
              items: items.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value,
                          style: _p(size: 13),
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: textMuted, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker({
    required String   label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _p(size: 11, color: textMuted)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F3EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value == null ? 'Pilih tanggal' : _fmt(value),
                  style: _p(
                      size: 12,
                      color: value == null ? textMuted : textDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (value != null)
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close,
                      size: 14, color: textMuted),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  void _showPreview(List<QueryDocumentSnapshot> filtered) {
    showDialog(
      context: context,
      builder: (_) => _LaporanPreviewDialog(
        orders:       filtered,
        filterStatus: _filterStatus,
        filterKat:    _filterKat,
        startDate:    _startDate,
        endDate:      _endDate,
      ),
    );
  }
}

// ============================================================
// 📄 PREVIEW LAPORAN + PDF
// ============================================================
class _LaporanPreviewDialog extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  final String    filterStatus;
  final String    filterKat;
  final DateTime? startDate;
  final DateTime? endDate;

  const _LaporanPreviewDialog({
    required this.orders,
    required this.filterStatus,
    required this.filterKat,
    this.startDate,
    this.endDate,
  });

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  int get _totalPendapatan {
    int total = 0;
    for (final doc in orders) {
      final d = doc.data() as Map<String, dynamic>;
      if (_normalizeStatus(d['status']) == sSelesai) {
        total += (d['grand_total'] ?? 0) as int;
      }
    }
    return total;
  }

  // ── Generate PDF ──
  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DAPUR ATIK',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Laporan Pesanan',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Dicetak: ${_fmt(now)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                if (startDate != null || endDate != null)
                  pw.Text(
                    'Periode: ${startDate != null ? _fmt(startDate!) : 'awal'} – ${endDate != null ? _fmt(endDate!) : 'sekarang'}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
              ],
            ),
          ],
        ),

        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),

        // Info filter
        pw.Row(children: [
          _pdfBadge('Status: ${filterStatus == 'semua' ? 'Semua' : filterStatus}'),
          pw.SizedBox(width: 8),
          _pdfBadge('Kategori: ${filterKat == 'semua' ? 'Semua' : filterKat}'),
        ]),

        pw.SizedBox(height: 12),

        // Ringkasan
        pw.Row(children: [
          _pdfStatBox('Total Pesanan', '${orders.length}'),
          pw.SizedBox(width: 12),
          _pdfStatBox('Pendapatan (Selesai)', _formatRp(_totalPendapatan)),
        ]),

        pw.SizedBox(height: 16),

        // Tabel
        if (orders.isEmpty)
          pw.Center(
            child: pw.Text('Tidak ada data untuk filter ini',
                style: const pw.TextStyle(color: PdfColors.grey)),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfTh('Pelanggan'),
                  _pdfTh('Tanggal'),
                  _pdfTh('Total'),
                  _pdfTh('Status'),
                ],
              ),
              // Rows
              ...orders.map((doc) {
                final d    = doc.data() as Map<String, dynamic>;
                final ts   = (d['created_at'] as Timestamp?)?.toDate();
                final stat = _normalizeStatus(d['status']);
                return pw.TableRow(children: [
                  _pdfTd(d['nama_pemesan'] ?? '-'),
                  _pdfTd(ts != null ? _fmt(ts) : '-'),
                  _pdfTd(_formatRp((d['grand_total'] ?? 0) as int)),
                  _pdfTd(stat),
                ]);
              }),
            ],
          ),
      ],
    ));

    return pdf.save();
  }

  pw.Widget _pdfBadge(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
          color: PdfColors.red50,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
      );

  pw.Widget _pdfStatBox(String label, String val) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
              pw.SizedBox(height: 3),
              pw.Text(val,
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );

  pw.Widget _pdfTh(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
      );

  pw.Widget _pdfTd(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 680,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dialog
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: primary,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Preview Laporan',
                      style: _p(
                          size: 15,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white70, size: 18),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),

            // Preview
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul laporan
                    Text('Dapur Atik — Laporan Pesanan',
                        style: _p(size: 15, weight: FontWeight.w800)),
                    Text('Dicetak: ${_fmt(now)}',
                        style: _p(size: 11, color: textMuted)),
                    const SizedBox(height: 10),

                    // Badge filter
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _filterBadge('Status',
                          filterStatus == 'semua' ? 'Semua' : filterStatus),
                      _filterBadge('Kategori',
                          filterKat == 'semua' ? 'Semua' : filterKat),
                      if (startDate != null || endDate != null)
                        _filterBadge(
                          'Periode',
                          '${startDate != null ? _fmt(startDate!) : 'awal'} – ${endDate != null ? _fmt(endDate!) : 'sekarang'}',
                        ),
                    ]),

                    const SizedBox(height: 14),

                    // Stat ringkasan
                    Row(children: [
                      Expanded(
                          child: _statBox(
                              'Total Pesanan', '${orders.length}')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statBox('Pendapatan (Selesai)',
                              _formatRp(_totalPendapatan))),
                    ]),

                    const SizedBox(height: 14),

                    // Tabel
                    if (orders.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('Tidak ada data untuk filter ini',
                              style: _p(color: textMuted)),
                        ),
                      )
                    else
                      Table(
                        border: TableBorder.all(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(1.8),
                          3: FlexColumnWidth(1.5),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                                color: Color(0xFFF5F0ED)),
                            children: [
                              _th('Pelanggan'),
                              _th('Tanggal'),
                              _th('Total'),
                              _th('Status'),
                            ],
                          ),
                          ...orders.map((doc) {
                            final d    = doc.data() as Map<String, dynamic>;
                            final ts   = (d['created_at'] as Timestamp?)?.toDate();
                            final stat = _normalizeStatus(d['status']);
                            final cfg  = _statusCfg(stat);
                            return TableRow(children: [
                              _td(d['nama_pemesan'] ?? '-'),
                              _td(ts != null ? _fmt(ts) : '-'),
                              _td(_formatRp((d['grand_total'] ?? 0) as int)),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cfg['bg'],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(cfg['label'],
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: cfg['color']),
                                      textAlign: TextAlign.center),
                                ),
                              ),
                            ]);
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Footer tombol
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: const BorderSide(color: primary),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Tutup', style: _p(size: 13, weight: FontWeight.w600, color: primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final pdfBytes = await _buildPdf();
                      await Printing.layoutPdf(
                        onLayout: (_) async => pdfBytes,
                        name: 'Laporan_DapurAtik_${_fmt(DateTime.now())}.pdf',
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
                    label: Text('Cetak / Unduh PDF',
                        style: _p(size: 13, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBadge(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: primarySoft, borderRadius: BorderRadius.circular(8)),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
                text: '$label: ',
                style: _p(size: 11, color: textMuted)),
            TextSpan(
                text: value,
                style: _p(
                    size: 11, weight: FontWeight.w700, color: primary)),
          ]),
        ),
      );

  Widget _statBox(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: primarySoft, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: _p(size: 10, color: textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: _p(size: 15, weight: FontWeight.w800, color: primary)),
        ]),
      );

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.all(9),
        child: Text(text,
            style: _p(size: 10, weight: FontWeight.w700, color: textMuted)),
      );

  Widget _td(String text) => Padding(
        padding: const EdgeInsets.all(9),
        child: Text(text, style: _p(size: 11)),
      );
}

// ============================================================
// 🧱 CARD WRAPPER
// ============================================================
class _DashCard extends StatelessWidget {
  final Widget child;
  const _DashCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );
}