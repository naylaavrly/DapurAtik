import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ================= WARNA DAPUR ATIK =================
const Color primary = Color(0xFF7A1C1C);
const Color bgColor = Color(0xFFF5E6DA);
const Color textSoft = Color(0xFF8E8E8E);

// ================= SCREEN =================
class AdminUserScreen extends StatelessWidget {
  const AdminUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: const [
              // ===== TITLE =====
              Text(
                "Data User",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),

              SizedBox(height: 20),

              // ===== LIST USER =====
              Expanded(child: _UserList()),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= LIST USER =================
class _UserList extends StatelessWidget {
  const _UserList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users') // 🔥 ambil dari firebase
          .snapshots(),

      builder: (context, snapshot) {
        // ===== LOADING =====
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // ===== KOSONG =====
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Belum ada user"));
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,

          itemBuilder: (context, index) {
            final data =
                users[index].data() as Map<String, dynamic>;

            final name = data['name'] ?? 'No Name';
            final email = data['email'] ?? '-';
            final role = data['role'] ?? 'customer';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primary,
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: textSoft,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            );


          },
        );
      },
    );
  }
}