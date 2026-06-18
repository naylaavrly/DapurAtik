import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedPackages() async {
  final db = FirebaseFirestore.instance;

  final packages = [

    // ================= HAJATAN =================
    {
      "name": "Paket Hajatan A",
      "type": "hajatan",
      "price": 5000000,
      "min_order": 100,
      "lead_time": 90,
      "menu_items": [
        "Nasi Putih",
        "Ayam Goreng",
        "Tongseng",
        "Sayur Buncis",
        "Zuppa Soup"
      ]
    },

    {
      "name": "Paket Hajatan B",
      "type": "hajatan",
      "price": 7500000,
      "min_order": 150,
      "lead_time": 90,
      "menu_items": [
        "Nasi Putih",
        "Ayam Bakar",
        "Rendang",
        "Capcay",
        "Puding"
      ]
    },

    {
      "name": "Paket Hajatan C",
      "type": "hajatan",
      "price": 10000000,
      "min_order": 200,
      "lead_time": 90,
      "menu_items": [
        "Nasi Putih",
        "Ayam Goreng",
        "Daging Semur",
        "Sop Kimlo",
        "Buah Potong"
      ]
    },

    // ================= TAHLILAN =================
    {
      "name": "Paket Tahlilan A",
      "type": "tahlilan",
      "price": 15000,
      "min_order": 25,
      "lead_time": 7,
      "menu_items": [
        "Nasi Putih",
        "Ayam Kecap",
        "Mie Goreng",
      ]
    },

    {
      "name": "Paket Tahlilan B",
      "type": "tahlilan",
      "price": 20000,
      "min_order": 25,
      "lead_time": 7,
      "menu_items": [
        "Nasi Putih",
        "Ayam Goreng",
        "Sambal Goreng Kentang",
      ]
    },

    {
      "name": "Paket Tahlilan C",
      "type": "tahlilan",
      "price": 25000,
      "min_order": 25,
      "lead_time": 7,
      "menu_items": [
        "Nasi Putih",
        "Rendang",
        "Telur Balado",
      ]
    },

    // ================= SNACK BOX =================
    {
      "name": "Paket Snack Box A",
      "type": "snackbox",
      "price": 10000,
      "min_order": 20,
      "lead_time": 3,
      "menu_items": [
        "Lemper",
        "Risoles",
        "Air Mineral"
      ]
    },

    {
      "name": "Paket Snack Box B",
      "type": "snackbox",
      "price": 15000,
      "min_order": 20,
      "lead_time": 3,
      "menu_items": [
        "Lemper",
        "Pastel",
        "Brownies",
        "Air Mineral"
      ]
    },

    {
      "name": "Paket Snack Box C",
      "type": "snackbox",
      "price": 20000,
      "min_order": 20,
      "lead_time": 3,
      "menu_items": [
        "Lemper",
        "Risoles",
        "Brownies",
        "Kue Sus",
        "Air Mineral"
      ]
    },
  ];

  for (var paket in packages) {
    await db.collection('packages').add(paket);
  }

  print("9 PAKET BERHASIL DITAMBAHKAN");
}