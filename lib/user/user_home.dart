import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cart_service.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Dapur Atik"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('menus')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada menu"));
          }

          var menus = snapshot.data!.docs;

          return ListView.builder(
            itemCount: menus.length,
            itemBuilder: (context, index) {
              var data = menus[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['name']),
                  subtitle: Text(data['description']),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Rp ${data['price']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          await cartService.addToCart(data);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Berhasil tambah ke keranjang"),
                            ),
                          );
                        },
                        child: const Text("Tambah"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}