/// สินค้า (ขนม)
class Product {
  final int? id;
  final String name;
  final String category;
  final double price;
  final String image;
  final String description;
  final int stock;

  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.description,
    required this.stock,
  });

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        price: (m['price'] as num).toDouble(),
        image: m['image'] as String,
        description: (m['description'] as String?) ?? '',
        stock: (m['stock'] as num).toInt(),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'price': price,
        'image': image,
        'description': description,
        'stock': stock,
      };
}

/// ลูกค้า
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String note;
  final String createdAt;

  // ข้อมูลสรุป (คำนวณจากตาราง orders)
  final int orderCount;
  final double totalSpent;

  const Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.note = '',
    String? createdAt,
    this.orderCount = 0,
    this.totalSpent = 0,
  }) : createdAt = createdAt ?? '';

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: (m['phone'] as String?) ?? '',
        address: (m['address'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
        createdAt: (m['created_at'] as String?) ?? '',
        orderCount: ((m['order_count'] as num?) ?? 0).toInt(),
        totalSpent: ((m['total_spent'] as num?) ?? 0).toDouble(),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'note': note,
        'created_at':
            createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt,
      };

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    String? note,
  }) =>
      Customer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        note: note ?? this.note,
        createdAt: createdAt,
      );
}

/// รายการในคำสั่งซื้อ
class OrderItem {
  final int productId;
  final String productName;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, Object?> m) => OrderItem(
        productId: (m['product_id'] as num).toInt(),
        productName: m['product_name'] as String,
        price: (m['price'] as num).toDouble(),
        quantity: (m['quantity'] as num).toInt(),
      );
}

/// คำสั่งซื้อ
class Order {
  final int id;
  final int customerId;
  final double total;
  final String createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.customerId,
    required this.total,
    required this.createdAt,
    this.items = const [],
  });
}

