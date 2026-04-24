import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'user_home.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  Set<String> selectedItems = {};

  String formatRupiah(int number) {
    return "Rp ${number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      // 🔥 APPBAR FIX
      appBar: AppBar(
        backgroundColor: const Color(0xFF61100D),
        elevation: 0,

        // 🔥 BACK KE HOME
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const UserHome()),
              (route) => false,
            );
          },
        ),

        // 🔥 TITLE POPPINS
        title: Text(
          "Keranjang",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        // 🔥 DELETE PUTIH
        actions: [
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                for (var id in selectedItems) {
                  await FirebaseFirestore.instance
                      .collection('carts')
                      .doc(id)
                      .delete();
                }
                setState(() => selectedItems.clear());
              },
            )
        ],
      ),

      body: user == null
          ? const Center(child: Text("User belum login"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('carts')
                  .where('user_id', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final carts = snapshot.data!.docs;

                int total = 0;

                for (var doc in carts) {
                  if (selectedItems.contains(doc.id)) {
                    final data = doc.data() as Map<String, dynamic>;
                    total += (data['total_price'] ?? 0) as int;
                  }
                }

                return Column(
                  children: [

                    // 🔥 LIST CART
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: carts.length,
                        itemBuilder: (context, index) {

                          final doc = carts[index];
                          final data =
                              doc.data() as Map<String, dynamic>;

                          final image = data['image_url'] ?? "";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [

                                // 🔥 CHECKBOX
                                Checkbox(
                                  value: selectedItems.contains(doc.id),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedItems.add(doc.id);
                                      } else {
                                        selectedItems.remove(doc.id);
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(width: 10),

                                // 🔥 IMAGE
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: image.isNotEmpty
                                      ? Image.network(
                                          image,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image),
                                        ),
                                ),

                                const SizedBox(width: 20),

                                // 🔥 INFO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        data['name'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 7),

                                      Text(
                                        formatRupiah(
                                            data['total_price'] ?? 0),
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),

                                      const SizedBox(height: 7),

                                      // 🔥 QTY
                                      Row(
                                        children: [

                                          _qtyBtn("-", () async {
                                            int qty = data['qty'] ?? 1;
                                            if (qty > 1) {
                                              qty--;

                                              await FirebaseFirestore.instance
                                                  .collection('carts')
                                                  .doc(doc.id)
                                                  .update({
                                                'qty': qty,
                                                'total_price':
                                                    qty * (data['price'] ?? 0),
                                              });
                                            }
                                          }),

                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(horizontal: 10),
                                            child: Text("${data['qty']}"),
                                          ),

                                          _qtyBtn("+", () async {
                                            int qty = data['qty'] ?? 1;
                                            qty++;

                                            await FirebaseFirestore.instance
                                                .collection('carts')
                                                .doc(doc.id)
                                                .update({
                                              'qty': qty,
                                              'total_price':
                                                  qty * (data['price'] ?? 0),
                                            });
                                          }),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // 🔥 TOTAL
                    if (selectedItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total"),
                                Text(
                                  formatRupiah(total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF61100D),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF61100D),
                                ),
                                onPressed: () {},
                                child: const Text(
                                  "Checkout",
                                  style:
                                      TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                  ],
                );
              },
            ),
    );
  }

  // 🔥 QTY BUTTON
  Widget _qtyBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF61100D),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}