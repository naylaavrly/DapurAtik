import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AppColors {
  static const primary = Color(0xFF7A0C0C);
  static const secondary = Color(0xFFF5E9E2);
  static const background = Color(0xFFF8F8F8);
  static const white = Colors.white;
  static const textDark = Color(0xFF2E2E2E);
}

/// 🔥 FILTER ENUM
enum DateFilter { weekly, monthly }

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  DateFilter selectedFilter = DateFilter.weekly;

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Selamat Pagi";
    if (hour < 15) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  /// 🔥 DATA LINE CHART BERDASARKAN FILTER
  List<FlSpot> getLineData() {
    if (selectedFilter == DateFilter.weekly) {
      return const [
        FlSpot(0, 2),
        FlSpot(1, 4),
        FlSpot(2, 3),
        FlSpot(3, 6),
        FlSpot(4, 5),
        FlSpot(5, 8),
      ];
    } else {
      return const [
        FlSpot(0, 5),
        FlSpot(1, 7),
        FlSpot(2, 6),
        FlSpot(3, 9),
        FlSpot(4, 8),
        FlSpot(5, 12),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            /// 🔥 GREETING
            Text(
              "${getGreeting()}, Admin DapurAtik 👋🏻",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 FILTER
            Row(
              children: [
                _filterButton("Mingguan", DateFilter.weekly),
                const SizedBox(width: 10),
                _filterButton("Bulanan", DateFilter.monthly),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 SUMMARY
            Row(
              children: const [
                Expanded(child: SummaryCard("Total Pesanan", "120", Icons.shopping_cart)),
                SizedBox(width: 10),
                Expanded(child: SummaryCard("Pendapatan", "Rp 8.5jt", Icons.attach_money)),
                SizedBox(width: 10),
                Expanded(child: SummaryCard("Menu Terjual", "340", Icons.fastfood)),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 LINE CHART (PAKAI FILTER)
            SalesLineChart(spots: getLineData()),

            const SizedBox(height: 20),

            const SalesPieChart(),

            const SizedBox(height: 20),

            /// 🔥 PRODUK TERLARIS
            _cardWrapper(
              "Produk Terlaris",
              Column(
                children: [
                  _productItem("Nasi Ayam Goreng", "120 terjual"),
                  _productItem("Nasi Rendang", "98 terjual"),
                  _productItem("Paket Hemat", "85 terjual"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 RECENT ORDERS
            _cardWrapper(
              "Pesanan Terbaru",
              Column(
                children: [
                  _orderItem("Budi", "Nasi Ayam Goreng", "2x"),
                  _orderItem("Siti", "Nasi Rendang", "1x"),
                  _orderItem("Andi", "Paket Hemat", "3x"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 BUTTON FILTER
  Widget _filterButton(String text, DateFilter value) {
    final isActive = selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 🔥 ITEM PRODUK
  Widget _productItem(String name, String total) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.fastfood, color: AppColors.primary),
      ),
      title: Text(name),
      subtitle: Text(total),
    );
  }

  /// 🔥 ITEM ORDER
  Widget _orderItem(String name, String menu, String qty) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.person, color: AppColors.primary),
      ),
      title: Text(name),
      subtitle: Text("$menu • $qty"),
    );
  }
}

/// =======================
/// 🔥 LINE CHART
/// =======================
class SalesLineChart extends StatelessWidget {
  final List<FlSpot> spots;

  const SalesLineChart({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    return _cardWrapper(
      "Grafik Penjualan",
      SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFFB3B3)],
                ),
                barWidth: 4,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================
class SalesPieChart extends StatelessWidget {
  const SalesPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return _cardWrapper(
      "Distribusi Menu",
      SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: [
              _section(40, "Ayam", AppColors.primary),
              _section(30, "Rendang", Color(0xFFB23A3A)),
              _section(20, "Paket", Color(0xFFE5A5A5)),
              _section(10, "Lainnya", Color(0xFFF5DCDC)),
            ],
          ),
        ),
      ),
    );
  }

  PieChartSectionData _section(double value, String title, Color color) {
    return PieChartSectionData(
      value: value,
      title: "$title\n${value.toInt()}%",
      color: color,
    );
  }
}

/// =======================
/// 🔥 WRAPPER
/// =======================
Widget _cardWrapper(String title, Widget child) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

/// =======================
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SummaryCard(this.title, this.value, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(title),
        ],
      ),
    );
  }
}