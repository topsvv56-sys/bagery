import 'package:flutter/foundation.dart';

import '../models/models.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem(this.product, this.quantity);
  double get subtotal => product.price * quantity;
}

/// ตะกร้าสินค้า (เก็บในหน่วยความจำ)
class Cart extends ChangeNotifier {
  Cart._();
  static final Cart instance = Cart._();

  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get totalQuantity => _items.values.fold(0, (s, i) => s + i.quantity);
  double get totalPrice => _items.values.fold(0, (s, i) => s + i.subtotal);
  bool get isEmpty => _items.isEmpty;

  int quantityOf(int productId) => _items[productId]?.quantity ?? 0;

  /// เพิ่มสินค้า (ไม่เกินจำนวนคงเหลือ)
  void add(Product product, int quantity) {
    final existing = _items[product.id!];
    final newQty = (existing?.quantity ?? 0) + quantity;
    _items[product.id!] = CartItem(product, newQty.clamp(1, product.stock));
    notifyListeners();
  }

  void setQuantity(int productId, int quantity) {
    final item = _items[productId];
    if (item == null) return;
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      item.quantity = quantity.clamp(1, item.product.stock);
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<OrderItem> toOrderItems() => _items.values
      .map((i) => OrderItem(
            productId: i.product.id!,
            productName: i.product.name,
            price: i.product.price,
            quantity: i.quantity,
          ))
      .toList();
}

