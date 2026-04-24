import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_detail_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {

  String selectedCategory = "Semua";
  String searchQuery = "";

  String formatRupiah(int number) {
    return "Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Column(
        children: [

          // 🔥 NAVBAR
          _buildNavbar(),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {

                final width = constraints.maxWidth;

                int crossAxisCount = 2;
                if (width > 600) crossAxisCount = 3;
                if (width > 1000) crossAxisCount = 4;
                if (width > 1400) crossAxisCount = 5;

                return Column(
                  children: [

                    // 🔍 SEARCH (FULL WIDTH)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: TextField(
                        onChanged: (v) {
                          setState(() {
                            searchQuery = v.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Cari menu...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // 🔥 CHIP
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 10,
                          children: [
                            _chip("Semua"),
                            _chip("Ayam"),
                            _chip("Daging"),
                            _chip("Ikan & laut"),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔥 LIST MENU
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: selectedCategory == "Semua"
                            ? FirebaseFirestore.instance
                                .collection('packages')
                                .where('is_active', isEqualTo: true)
                                .snapshots()
                            : FirebaseFirestore.instance
                                .collection('packages')
                                .where('is_active', isEqualTo: true)
                                .where('category',
                                    isEqualTo: selectedCategory.toLowerCase())
                                .snapshots(),
                        builder: (context, snapshot) {

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData) {
                            return const Center(child: Text("Tidak ada data"));
                          }

                          final menus = snapshot.data!.docs.where((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? "")
                                .toString()
                                .toLowerCase();
                            return name.contains(searchQuery);
                          }).toList();

                          if (menus.isEmpty) {
                            return Center(
                              child: Text(
                                "Tidak ada menu 😢",
                                style: GoogleFonts.poppins(),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                            itemCount: menus.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 0.95,
                            ),
                            itemBuilder: (context, index) {

                              final data = menus[index].data()
                                  as Map<String, dynamic>;

                              final name = data['name'] ?? '';
                              final image = data['image_url'] ?? '';
                              final description = data['description'] ?? '';

                              final priceRaw = data['price'];
                              int price = 0;

                              if (priceRaw is int) price = priceRaw;
                              if (priceRaw is String) {
                                price = int.tryParse(priceRaw) ?? 0;
                              }

                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MenuDetailPage(
                                        name: name,
                                        price: price,
                                        image: image,
                                        description: description,
                                      ),
                                    ),
                                  );
                                },
                                child: _menuCard(
                                  name: name,
                                  price: price,
                                  image: image,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= NAVBAR =================
  Widget _buildNavbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      color: const Color(0xFF61100D),
      child: Text(
        "Katalog Menu",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ================= CHIP =================
  Widget _chip(String text) {
    final isActive = selectedCategory == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF61100D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget _menuCard({
    required String name,
    required int price,
    required String image,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [

          // 🔥 IMAGE
          Positioned.fill(
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
          ),

          // 🔥 GRADIENT (BIAR GA NUTUP KLIK)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 🔥 TEXT
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 2),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      formatRupiah(price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF61100D),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.add,
                            size: 18, color: Colors.white),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}