import 'package:flutter/material.dart';

// ============================================================
// 🎨 DESIGN SYSTEM (sama dengan dashboard)
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
  static const info = Color(0xFF1565C0);
  static const infoBg = Color(0xFFE3F2FD);
  static const cancelled = Color(0xFF616161);
  static const cancelledBg = Color(0xFFF5F5F5);
}

// ============================================================
// 🗃️ MODEL
// ============================================================
enum OrderStatus { semua, pending, diproses, selesai, dibatalkan }

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final List<OrderItemDetail> items;
  final int total;
  final OrderStatus status;
  final DateTime createdAt;
  final String paymentMethod;
  final String address;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
    required this.address,
  });
}

class OrderItemDetail {
  final String name;
  final int qty;
  final int price;
  OrderItemDetail(this.name, this.qty, this.price);
}

// ============================================================
// 🔥 DUMMY DATA
// ============================================================
final List<OrderModel> _dummyOrders = [
  OrderModel(
    id: "ORD-001",
    customerName: "Budi Santoso",
    customerPhone: "0812-3456-7890",
    items: [
      OrderItemDetail("Nasi Ayam Goreng", 2, 18000),
      OrderItemDetail("Es Teh Manis", 2, 5000),
    ],
    total: 46000,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    paymentMethod: "Transfer Bank",
    address: "Jl. Merdeka No. 12, Jakarta",
  ),
  OrderModel(
    id: "ORD-002",
    customerName: "Siti Rahayu",
    customerPhone: "0813-9876-5432",
    items: [
      OrderItemDetail("Nasi Rendang", 1, 22000),
    ],
    total: 22000,
    status: OrderStatus.diproses,
    createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    paymentMethod: "QRIS",
    address: "Jl. Sudirman No. 5, Jakarta",
  ),
  OrderModel(
    id: "ORD-003",
    customerName: "Andi Wijaya",
    customerPhone: "0811-2345-6789",
    items: [
      OrderItemDetail("Paket Hemat", 3, 15000),
      OrderItemDetail("Jus Alpukat", 1, 12000),
    ],
    total: 57000,
    status: OrderStatus.selesai,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    paymentMethod: "COD",
    address: "Jl. Gatot Subroto No. 88, Jakarta",
  ),
  OrderModel(
    id: "ORD-004",
    customerName: "Dewi Lestari",
    customerPhone: "0819-1234-5678",
    items: [
      OrderItemDetail("Nasi Ayam Goreng", 1, 18000),
      OrderItemDetail("Nasi Rendang", 2, 22000),
    ],
    total: 62000,
    status: OrderStatus.selesai,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    paymentMethod: "Transfer Bank",
    address: "Jl. Kebon Jeruk No. 3, Jakarta",
  ),
  OrderModel(
    id: "ORD-005",
    customerName: "Rudi Hartono",
    customerPhone: "0856-7654-3210",
    items: [
      OrderItemDetail("Paket Hemat", 2, 15000),
    ],
    total: 30000,
    status: OrderStatus.dibatalkan,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    paymentMethod: "QRIS",
    address: "Jl. Cipete No. 7, Jakarta",
  ),
  OrderModel(
    id: "ORD-006",
    customerName: "Maya Putri",
    customerPhone: "0877-3456-7890",
    items: [
      OrderItemDetail("Nasi Ayam Goreng", 1, 18000),
      OrderItemDetail("Es Teh Manis", 1, 5000),
      OrderItemDetail("Jus Alpukat", 1, 12000),
    ],
    total: 35000,
    status: OrderStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    paymentMethod: "COD",
    address: "Jl. Tebet Barat No. 21, Jakarta",
  ),
];

// ============================================================
// 📄 ADMIN ORDER PAGE
// ============================================================
class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key});

  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage>
    with SingleTickerProviderStateMixin {
  OrderStatus _selectedStatus = OrderStatus.semua;
  String _searchQuery = "";
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final TextEditingController _searchCtrl = TextEditingController();

  // Tab labels & status map
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Semua', 'status': OrderStatus.semua},
    {'label': 'Menunggu', 'status': OrderStatus.pending},
    {'label': 'Diproses', 'status': OrderStatus.diproses},
    {'label': 'Selesai', 'status': OrderStatus.selesai},
    {'label': 'Dibatalkan', 'status': OrderStatus.dibatalkan},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderModel> get _filteredOrders {
    return _dummyOrders.where((o) {
      final matchStatus = _selectedStatus == OrderStatus.semua || o.status == _selectedStatus;
      final matchSearch = _searchQuery.isEmpty ||
          o.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.id.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();
  }

  int _countByStatus(OrderStatus s) =>
      s == OrderStatus.semua ? _dummyOrders.length : _dummyOrders.where((o) => o.status == s).length;

  void _switchTab(OrderStatus s) {
    setState(() => _selectedStatus = s);
    _animController.forward(from: 0);
  }

  // ── UPDATE STATUS (simulasi) ────────────────────────────
  void _updateStatus(OrderModel order, OrderStatus newStatus) {
    final idx = _dummyOrders.indexWhere((o) => o.id == order.id);
    if (idx != -1) {
      setState(() {
        _dummyOrders[idx] = OrderModel(
          id: order.id,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          items: order.items,
          total: order.total,
          status: newStatus,
          createdAt: order.createdAt,
          paymentMethod: order.paymentMethod,
          address: order.address,
        );
      });
      _showToast("Status pesanan ${order.id} diperbarui!");
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTabRow(),
          _buildSummaryStrip(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _filteredOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (_, i) => _buildOrderCard(_filteredOrders[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Manajemen Pesanan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "${_dummyOrders.length} total pesanan hari ini",
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          // Notif bell dengan badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_rounded, color: AppColors.primary, size: 20),
              ),
              Positioned(
                top: -2, right: -2,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: Text("2", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: "Cari nama pelanggan atau ID pesanan...",
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = "");
                    },
                    child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── Tab Row ──────────────────────────────────────────────
  Widget _buildTabRow() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _tabs.map((t) {
                final s = t['status'] as OrderStatus;
                final isActive = _selectedStatus == s;
                final count = _countByStatus(s);
                return GestureDetector(
                  onTap: () => _switchTab(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? AppColors.primary : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          t['label'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white.withOpacity(0.25) : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$count",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isActive ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Strip ────────────────────────────────────────
  Widget _buildSummaryStrip() {
    final pending = _countByStatus(OrderStatus.pending);
    final diproses = _countByStatus(OrderStatus.diproses);
    final selesai = _countByStatus(OrderStatus.selesai);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stripStat("$pending", "Menunggu", Icons.hourglass_top_rounded),
          _stripDivider(),
          _stripStat("$diproses", "Diproses", Icons.local_fire_department_rounded),
          _stripDivider(),
          _stripStat("$selesai", "Selesai", Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _stripStat(String count, String label, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 5),
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _stripDivider() {
    return Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2));
  }

  // ── Order Card ───────────────────────────────────────────
  Widget _buildOrderCard(OrderModel order) {
    final cfg = _statusConfig(order.status);
    final timeAgo = _timeAgo(order.createdAt);

    return GestureDetector(
      onTap: () => _showOrderDetail(order),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Card Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(order.id,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            const Text(" • ", style: TextStyle(color: AppColors.textMuted)),
                            Text(timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cfg['bg'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cfg['icon'], size: 12, color: cfg['color']),
                        const SizedBox(width: 4),
                        Text(
                          cfg['label'],
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg['color']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),

            // ── Items preview ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: order.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${item.name} x${item.qty}",
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                      Text(
                        "Rp ${_formatPrice(item.price * item.qty)}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("+${order.items.length - 2} item lainnya",
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              ),

            // ── Card Footer ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  // Payment method pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payment_rounded, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(order.paymentMethod,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Total: ",
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    "Rp ${_formatPrice(order.total)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Action Buttons (hanya jika pending/diproses) ──
            if (order.status == OrderStatus.pending || order.status == OrderStatus.diproses)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Tolak / Batalkan
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _confirmUpdateStatus(order, OrderStatus.dibatalkan),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: const Center(
                            child: Text("Batalkan",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Proses / Selesaikan
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _confirmUpdateStatus(
                          order,
                          order.status == OrderStatus.pending ? OrderStatus.diproses : OrderStatus.selesai,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              order.status == OrderStatus.pending ? "✓  Proses Sekarang" : "✓  Tandai Selesai",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Confirm Dialog ───────────────────────────────────────
  void _confirmUpdateStatus(OrderModel order, OrderStatus newStatus) {
    final cfg = _statusConfig(newStatus);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: cfg['bg'], shape: BoxShape.circle),
                child: Icon(cfg['icon'], color: cfg['color'], size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                "Ubah Status Pesanan?",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                "Pesanan ${order.id} akan diubah menjadi \"${cfg['label']}\".",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      child: const Text("Batal", style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateStatus(order, newStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Ya, Ubah", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Order Detail Bottom Sheet ────────────────────────────
  void _showOrderDetail(OrderModel order) {
    final cfg = _statusConfig(order.status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detail Pesanan",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      Text(order.id,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: cfg['bg'], borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(cfg['icon'], size: 13, color: cfg['color']),
                        const SizedBox(width: 5),
                        Text(cfg['label'],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cfg['color'])),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Customer info
              _detailRow(Icons.person_rounded, "Pelanggan", order.customerName),
              _detailRow(Icons.phone_rounded, "Nomor HP", order.customerPhone),
              _detailRow(Icons.location_on_rounded, "Alamat", order.address),
              _detailRow(Icons.payment_rounded, "Pembayaran", order.paymentMethod),
              _detailRow(Icons.access_time_rounded, "Waktu", _formatDate(order.createdAt)),

              const SizedBox(height: 16),

              // Items
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Daftar Menu",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 10),
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text("${item.name} ×${item.qty}",
                                style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                          ),
                          Text("Rp ${_formatPrice(item.price * item.qty)}",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        ],
                      ),
                    )),
                    const Divider(color: Color(0xFFE0E0E0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        Text("Rp ${_formatPrice(order.total)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (order.status == OrderStatus.pending || order.status == OrderStatus.diproses)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmUpdateStatus(
                        order,
                        order.status == OrderStatus.pending ? OrderStatus.diproses : OrderStatus.selesai,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      order.status == OrderStatus.pending ? "Proses Pesanan Ini" : "Tandai Selesai",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 10),
          Text("$label  ", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          const Text("Tidak ada pesanan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Text("Belum ada pesanan di kategori ini",
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ============================================================
  // 🛠️ HELPERS
  // ============================================================
  Map<String, dynamic> _statusConfig(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return {
          'label': 'Menunggu',
          'color': AppColors.warning,
          'bg': AppColors.warningBg,
          'icon': Icons.hourglass_top_rounded,
        };
      case OrderStatus.diproses:
        return {
          'label': 'Diproses',
          'color': AppColors.info,
          'bg': AppColors.infoBg,
          'icon': Icons.local_fire_department_rounded,
        };
      case OrderStatus.selesai:
        return {
          'label': 'Selesai',
          'color': AppColors.success,
          'bg': AppColors.successBg,
          'icon': Icons.check_circle_rounded,
        };
      case OrderStatus.dibatalkan:
        return {
          'label': 'Dibatalkan',
          'color': AppColors.cancelled,
          'bg': AppColors.cancelledBg,
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'label': 'Semua',
          'color': AppColors.textMuted,
          'bg': AppColors.background,
          'icon': Icons.list_rounded,
        };
    }
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam lalu";
    return "${diff.inDays} hari lalu";
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}