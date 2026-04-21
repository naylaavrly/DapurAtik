import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ================= WARNA =================
const Color primary = Color(0xFF7A1C1C);
const Color bgColor = Color(0xFFF5E6DA);
const Color textSoft = Color(0xFF8E8E8E);

// ================= STYLE INPUT =================
InputDecoration inputStyle(String label) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: const Color(0xFFF9F3EF),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          const BorderSide(color: primary, width: 2),
    ),
  );
}

// ================= PAGE =================
class AdminUserPage extends StatefulWidget {
  const AdminUserPage({super.key});

  @override
  State<AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  String searchQuery = "";
  String selectedRole = "semua"; // 🔥 filter role

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              // ===== TITLE =====
              const Text(
                "Data User",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),

              const SizedBox(height: 20),

              // ===== SEARCH + FILTER =====
              Row(
                children: [

                  // 🔍 SEARCH
                  Expanded(
                    child: TextField(
                      onChanged: (v) {
                        setState(() {
                          searchQuery = v.toLowerCase();
                        });
                      },
                      decoration: inputStyle("Cari user...")
                          .copyWith(
                            prefixIcon: const Icon(Icons.search),
                          ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 🔥 FILTER ROLE
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: (v) {
                      setState(() {
                        selectedRole = v.toLowerCase();
                      });
                    },
                    itemBuilder: (_) => [
                      "Semua",
                      "Admin",
                      "Customer",
                    ]
                        .map((e) =>
                            PopupMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== TOTAL USER =====
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Total: ${snapshot.data!.docs.length} user",
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // ===== LIST USER =====
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),

                  builder: (context, snapshot) {

                    // LOADING
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    var data = snapshot.data!.docs;

                    // 🔥 FILTER LOGIC
                    var filtered = data.where((doc) {
                      final d =
                          doc.data() as Map<String, dynamic>;

                      final name =
                          (d['name'] ?? "").toString().toLowerCase();
                      final email =
                          (d['email'] ?? "").toString().toLowerCase();

                      String role =
                          (d['role'] ?? 'customer').toString().toLowerCase();

                      // 🔥 FIX ROLE (hapus "user")
                      if (role != "admin") role = "customer";

                      final matchSearch =
                          name.contains(searchQuery) ||
                          email.contains(searchQuery);

                      return matchSearch &&
                          (selectedRole == "semua"
                              ? true
                              : role == selectedRole);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                          child: Text("User tidak ditemukan"));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {

                        final d = filtered[index].data()
                            as Map<String, dynamic>;

                        final name = d['name'] ?? 'No Name';
                        final email = d['email'] ?? '-';

                        String role =
                            (d['role'] ?? 'customer').toString();

                        // 🔥 NORMALISASI ROLE
                        if (role != "admin") {
                          role = "customer";
                        }

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(20),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),

                          child: Row(
                            children: [

                              // AVATAR
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: primary,
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 18),

                              // DATA
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style:
                                          const TextStyle(
                                        color: textSoft,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ROLE BADGE
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: role == "admin"
                                      ? Colors.red
                                          .withOpacity(0.1)
                                      : primary
                                          .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: TextStyle(
                                    color: role == "admin"
                                        ? Colors.red
                                        : primary,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
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
}