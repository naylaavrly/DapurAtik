import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ============================================================
// 🎨 DESIGN SYSTEM
// ============================================================
class AppColors {
  static const primary = Color(0xFF7A0C0C);
  static const primaryLight = Color(0xFFB23A3A);
  static const primarySoft = Color(0xFFFFF0F0);
  static const accent = Color(0xFFFF6B35);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F4F4);
  static const textDark = Color(0xFF1A1A1A);
  static const textMuted = Color(0xFF9E9E9E);
  static const success = Color(0xFF2E7D32);
  static const successBg = Color(0xFFE8F5E9);
  static const warning = Color(0xFFE65100);
  static const warningBg = Color(0xFFFFF3E0);
}

class AppText {
  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const subheading = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static const number = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );
}

// ============================================================
// 🔥 FILTER ENUM
// ============================================================
enum DateFilter { weekly, monthly }

// ============================================================
// 🏠 MAIN DASHBOARD
// ============================================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  DateFilter selectedFilter = DateFilter.weekly;
  int _touchedPieIndex = -1;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Selamat Pagi";
    if (hour < 15) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  List<FlSpot> getLineData() {
    if (selectedFilter == DateFilter.weekly) {
      return const [
        FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3),
        FlSpot(3, 6), FlSpot(4, 5), FlSpot(5, 8),
      ];
    } else {
      return const [
        FlSpot(0, 5), FlSpot(1, 7), FlSpot(2, 6),
        FlSpot(3, 9), FlSpot(4, 8), FlSpot(5, 12),
      ];
    }
  }

  List<String> getLineLabels() {
    if (selectedFilter == DateFilter.weekly) {
      return ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    } else {
      return ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun'];
    }
  }

  void _switchFilter(DateFilter f) {
    setState(() => selectedFilter = f);
    _fadeController.forward(from: 0.3);
    _slideController.forward(from: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Sticky Header ──────────────────────────────
              SliverAppBar(
                expandedHeight: 130,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.surface,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(),
                  collapseMode: CollapseMode.parallax,
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: const Color(0xFFEEEEEE),
                  ),
                ),
              ),

              // ── Content ────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildFilterRow(),
                    const SizedBox(height: 20),
                    _buildSummaryRow(),
                    const SizedBox(height: 20),
                    _buildLineChartCard(),
                    const SizedBox(height: 20),
                    _buildPieChartCard(),
                    const SizedBox(height: 20),
                    _buildTopProducts(),
                    const SizedBox(height: 20),
                    _buildRecentOrders(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "${getGreeting()}, Admin 👋🏻",
                  style: AppText.subheading.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text("DapurAtik", style: AppText.display),
              ],
            ),
          ),
          _buildAvatarBadge(),
        ],
      ),
    );
  }

  Widget _buildAvatarBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 26),
        ),
        Positioned(
          top: -3,
          right: -3,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              border: Border.all(color: Colors.white, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // ── Filter Row ──────────────────────────────────────────
  Widget _buildFilterRow() {
    return Row(
      children: [
        _filterChip("Mingguan", DateFilter.weekly, Icons.view_week_rounded),
        const SizedBox(width: 10),
        _filterChip("Bulanan", DateFilter.monthly, Icons.calendar_month_rounded),
        const Spacer(),
        _dateRangeButton(),
      ],
    );
  }

  Widget _filterChip(String label, DateFilter value, IconData icon) {
    final active = selectedFilter == value;
    return GestureDetector(
      onTap: () => _switchFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary : const Color(0xFFE0E0E0),
          ),
          boxShadow: active
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRangeButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text("Jun 2025", style: AppText.label),
        ],
      ),
    );
  }

  // ── Summary Row ─────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Row(
      children: const [
        Expanded(
          child: EnhancedSummaryCard(
            title: "Total Pesanan",
            value: "120",
            icon: Icons.receipt_long_rounded,
            trend: "+12%",
            isPositive: true,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: EnhancedSummaryCard(
            title: "Pendapatan",
            value: "8.5jt",
            prefix: "Rp ",
            icon: Icons.trending_up_rounded,
            trend: "+8.3%",
            isPositive: true,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: EnhancedSummaryCard(
            title: "Menu Terjual",
            value: "340",
            icon: Icons.local_fire_department_rounded,
            trend: "-2%",
            isPositive: false,
          ),
        ),
      ],
    );
  }

  // ── Line Chart Card ──────────────────────────────────────
  Widget _buildLineChartCard() {
    final spots = getLineData();
    final labels = getLineLabels();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Grafik Penjualan", style: AppText.heading),
                  const SizedBox(height: 2),
                  Text(
                    selectedFilter == DateFilter.weekly ? "7 hari terakhir" : "6 bulan terakhir",
                    style: AppText.subheading,
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.success),
                    SizedBox(width: 3),
                    Text("Naik 15%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFF0F0F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[idx], style: AppText.label),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => AppColors.primary,
                  tooltipRoundedRadius: 10,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                    return LineTooltipItem(
                      "${s.y.toInt()} pesanan",
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  // ── Pie Chart Card ──────────────────────────────────────
  Widget _buildPieChartCard() {
    final pieData = [
      _PieItem("Ayam", 40, AppColors.primary),
      _PieItem("Rendang", 30, AppColors.primaryLight),
      _PieItem("Paket", 20, const Color(0xFFE5A5A5)),
      _PieItem("Lainnya", 10, const Color(0xFFF5DCDC)),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Distribusi Menu", style: AppText.heading),
          const SizedBox(height: 4),
          Text("Proporsi penjualan per kategori", style: AppText.subheading),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    centerSpaceRadius: 40,
                    sectionsSpace: 3,
                    sections: pieData.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedPieIndex;
                      return PieChartSectionData(
                        value: e.value.value,
                        color: e.value.color,
                        radius: isTouched ? 60 : 50,
                        title: isTouched ? "${e.value.value.toInt()}%" : "",
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pieData.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: e.value.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(e.value.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                          ),
                          Text(
                            "${e.value.value.toInt()}%",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Top Products ─────────────────────────────────────────
  Widget _buildTopProducts() {
    final products = [
      _ProductItem("Nasi Ayam Goreng", "120 terjual", 1, 120, 200),
      _ProductItem("Nasi Rendang", "98 terjual", 2, 98, 200),
      _ProductItem("Paket Hemat", "85 terjual", 3, 85, 200),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Produk Terlaris", style: AppText.heading),
                  const SizedBox(height: 2),
                  Text("Berdasarkan jumlah pesanan", style: AppText.subheading),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text("Lihat semua", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...products.map((p) => _buildProductRow(p)),
        ],
      ),
    );
  }

  Widget _buildProductRow(_ProductItem p) {
    final pct = p.sold / p.total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: p.rank == 1 ? const Color(0xFFFFF8E1) : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: p.rank == 1
                  ? const Text("🥇", style: TextStyle(fontSize: 16))
                  : Text(
                      "#${p.rank}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      p.rank == 1 ? AppColors.primary : AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            p.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ── Recent Orders ─────────────────────────────────────────
  Widget _buildRecentOrders() {
    final orders = [
      _OrderItem("Budi Santoso", "Nasi Ayam Goreng", "2x", "Rp 36.000", _OrderStatus.done),
      _OrderItem("Siti Rahayu", "Nasi Rendang", "1x", "Rp 22.000", _OrderStatus.process),
      _OrderItem("Andi Wijaya", "Paket Hemat", "3x", "Rp 45.000", _OrderStatus.pending),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pesanan Terbaru", style: AppText.heading),
                  const SizedBox(height: 2),
                  Text("Update real-time", style: AppText.subheading),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text("Live", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...orders.map((o) => _buildOrderRow(o)),
        ],
      ),
    );
  }

  Widget _buildOrderRow(_OrderItem o) {
    final statusConfig = _getStatusConfig(o.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.customer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text("${o.menu} • ${o.qty}", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(o.price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusConfig['bg'],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusConfig['label'],
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusConfig['color']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(_OrderStatus s) {
    switch (s) {
      case _OrderStatus.done:
        return {'label': 'Selesai', 'color': AppColors.success, 'bg': AppColors.successBg};
      case _OrderStatus.process:
        return {'label': 'Diproses', 'color': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD)};
      case _OrderStatus.pending:
        return {'label': 'Menunggu', 'color': AppColors.warning, 'bg': AppColors.warningBg};
    }
  }
}

// ============================================================
// 🧱 REUSABLE COMPONENTS
// ============================================================

/// Card wrapper
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Summary Card dengan trend badge
class EnhancedSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? prefix;
  final IconData icon;
  final String trend;
  final bool isPositive;

  const EnhancedSummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.prefix,
    required this.icon,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.successBg : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isPositive ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                if (prefix != null)
                  TextSpan(
                    text: prefix,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                TextSpan(
                  text: value,
                  style: AppText.number.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: AppText.label.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ============================================================
// 🗃️ DATA MODELS
// ============================================================
class _PieItem {
  final String name;
  final double value;
  final Color color;
  _PieItem(this.name, this.value, this.color);
}

class _ProductItem {
  final String name;
  final String label;
  final int rank;
  final double sold;
  final double total;
  _ProductItem(this.name, this.label, this.rank, this.sold, this.total);
}

enum _OrderStatus { done, process, pending }

class _OrderItem {
  final String customer;
  final String menu;
  final String qty;
  final String price;
  final _OrderStatus status;
  _OrderItem(this.customer, this.menu, this.qty, this.price, this.status);
}