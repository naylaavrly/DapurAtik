import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> addToCart(DocumentSnapshot menu) async {
    final user = auth.currentUser;

    if (user == null) return;

    final cartRef = firestore.collection('carts');

    // 🔥 cek apakah menu sudah ada di cart user
    final existing = await cartRef
        .where('user_id', isEqualTo: user.uid)
        .where('menu_id', isEqualTo: menu.id)
        .get();

    if (existing.docs.isNotEmpty) {
      // ✅ UPDATE QTY
      final doc = existing.docs.first;

      int currentQty = doc['qty'];
      int price = doc['price'];

      int newQty = currentQty + 1;

      await cartRef.doc(doc.id).update({
        'qty': newQty,
        'total_price': newQty * price,
      });
    } else {
      // ✅ INSERT BARU
      await cartRef.add({
        'user_id': user.uid,
        'menu_id': menu.id,
        'name': menu['name'],
        'price': menu['price'],
        'qty': 1,
        'total_price': menu['price'],
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }
}