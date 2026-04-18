import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

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

      appBar: AppBar(
        backgroundColor: const Color(0xFF7A1C1C),
        centerTitle: true,
        title: Text(
          "Menu",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('packages') // ✅ FIX
            .where('is_active', isEqualTo: true) // ✅ hanya aktif
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Menu belum tersedia"));
          }

          final menus = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: menus.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final data = menus[index].data() as Map<String, dynamic>;

              return _menuCard(
                name: data['name'] ?? '',
                price: data['price'] ?? 0,
                category: data['category'] ?? '',
                image: data['image_url'] ?? '', // ✅ FIX
              );
            },
          );
        },
      ),
    );
  }

  Widget _menuCard({
    required String name,
    required int price,
    required String category,
    required String image,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔥 IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: const Color(0xFFF3E3DA),
                        child: const Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Color(0xFF7A1C1C),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 120,
                    color: const Color(0xFFF3E3DA),
                    child: const Icon(
                      Icons.fastfood,
                      size: 40,
                      color: Color(0xFF7A1C1C),
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔥 CATEGORY
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E3DA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF7A1C1C),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 🔥 NAME
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                // 🔥 PRICE
                Text(
                  formatRupiah(price), // ✅ FIX FORMAT
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7A1C1C),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}