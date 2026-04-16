import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🔥 STYLE INPUT
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
          const BorderSide(color: Color(0xFF7A1C1C), width: 2),
    ),
  );
}

class AdminPaketPage extends StatefulWidget {
  const AdminPaketPage({super.key});

  @override
  State<AdminPaketPage> createState() => _AdminPaketPageState();
}

class _AdminPaketPageState extends State<AdminPaketPage> {
  String selectedCategory = "semua";
  String searchQuery = "";

  Color _getCategoryColor(String category) {
    switch (category) {
      case "hemat":
        return Colors.green;
      case "favorit":
        return Colors.orange;
      case "premium":
        return Colors.purple;
      case "spesial":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [

          Text(
            "Menu",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [

              Expanded(
                child: TextField(
                  onChanged: (v) {
                    setState(() {
                      searchQuery = v.toLowerCase();
                    });
                  },
                  decoration: inputStyle("Cari paket...")
                      .copyWith(prefixIcon: const Icon(Icons.search)),
                ),
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (v) {
                  setState(() {
                    selectedCategory = v;
                  });
                },
                itemBuilder: (_) => [
                  "semua",
                  "hemat",
                  "favorit",
                  "premium",
                  "spesial"
                ]
                    .map((e) =>
                        PopupMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),

              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddPaketDialog(),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('packages')
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                var data = snapshot.data!.docs;

                var filtered = data.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  final name =
                      (d['name'] ?? "").toString().toLowerCase();
                  final category = d['category'] ?? "";

                  return name.contains(searchQuery) &&
                      (selectedCategory == "semua"
                          ? true
                          : category == selectedCategory);
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final d =
                        filtered[i].data() as Map<String, dynamic>;
                    final include = (d['include'] as List?) ?? [];

                    return AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [

                              Text(
                                d['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold),
                              ),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      _getCategoryColor(
                                          d['category']),
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                ),
                                child: Text(
                                  d['category'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text("Rp ${d['price']}"),

                          if (include.isNotEmpty)
                            Text(
                              "Include: ${include.join(', ')}",
                              style:
                                  const TextStyle(fontSize: 12),
                            ),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end,
                            children: [

                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        EditPaketDialog(
                                      docId:
                                          filtered[i].id,
                                      data: d,
                                    ),
                                  );
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red,
                                    size: 18),
                                onPressed: () async {
                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          'packages')
                                      .doc(filtered[i].id)
                                      .delete();
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}






/// 🔥 ADD DIALOG
class AddPaketDialog extends StatefulWidget {
  const AddPaketDialog({super.key});

  @override
  State<AddPaketDialog> createState() =>
      _AddPaketDialogState();
}

class _AddPaketDialogState extends State<AddPaketDialog> {

  final nameController = TextEditingController();
  final priceController = TextEditingController();

  String category = "hemat";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text("Tambah Paket",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            TextField(
                controller: nameController,
                decoration: inputStyle("Nama Paket")),

            const SizedBox(height: 10),

            TextField(
                controller: priceController,
                decoration: inputStyle("Harga")),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: category,
              decoration: inputStyle("Kategori"),
              items: ["hemat", "favorit", "premium", "spesial"]
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('packages')
                    .add({
                  'name': nameController.text,
                  'price': int.parse(priceController.text),
                  'category': category,
                  'include': [],
                  'exclude': [],
                  'created_at': Timestamp.now(),
                });

                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}




/// 🔥 EDIT DIALOG
class EditPaketDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditPaketDialog({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditPaketDialog> createState() =>
      _EditPaketDialogState();
}

class _EditPaketDialogState extends State<EditPaketDialog> {

  late TextEditingController name;
  late TextEditingController price;
  String category = "hemat";

  @override
  void initState() {
    name = TextEditingController(text: widget.data['name']);
    price =
        TextEditingController(text: widget.data['price'].toString());
    category = widget.data['category'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text("Edit Paket",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            TextField(
                controller: name,
                decoration: inputStyle("Nama")),

            const SizedBox(height: 10),

            TextField(
                controller: price,
                decoration: inputStyle("Harga")),

            const SizedBox(height: 10),

            DropdownButtonFormField(
              value: category,
              decoration: inputStyle("Kategori"),
              items: ["hemat", "favorit", "premium", "spesial"]
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('packages')
                    .doc(widget.docId)
                    .update({
                  'name': name.text,
                  'price': int.parse(price.text),
                  'category': category,
                });

                Navigator.pop(context);
              },
              child: const Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}