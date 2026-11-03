import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// จัดการฐานข้อมูล SQLite ของร้าน (bakery.db)
///
/// ตาราง:
///  - products    : สินค้า ราคา รูป จำนวนคงเหลือ
///  - customers   : ข้อมูลลูกค้า
///  - orders      : คำสั่งซื้อของลูกค้า
///  - order_items : รายการสินค้าในแต่ละคำสั่งซื้อ
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'bakery.db';
  static const _dbVersion = 1;

  /// เพิ่มค่าทุกครั้งที่ข้อมูลเปลี่ยน เพื่อให้หน้าจอต่าง ๆ โหลดข้อมูลใหม่
  final ValueNotifier<int> changes = ValueNotifier(0);
  void _notify() => changes.value++;

  Database? _db;
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        image TEXT NOT NULL,
        description TEXT,
        stock INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        total REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    final batch = db.batch();
    for (final product in _seedProducts) {
      batch.insert('products', product.toMap());
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------- products

  static const categories = ['ທັງໝົດ', 'ເຂົ້າໜົມປັງ', 'ເຄັກ', 'ເຂົ້າໜົມຫວານ'];

  /// ดึงสินค้า พร้อมค้นหาจากชื่อ / หมวด / คำอธิบาย
  Future<List<Product>> getProducts({String query = '', String? category}) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    final q = query.trim();
    if (q.isNotEmpty) {
      where.add('(name LIKE ? OR category LIKE ? OR description LIKE ?)');
      args.addAll(['%$q%', '%$q%', '%$q%']);
    }
    if (category != null && category != categories.first) {
      where.add('category = ?');
      args.add(category);
    }
    final rows = await db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'id',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  // --------------------------------------------------------------- customers

  /// ดึงลูกค้า พร้อมค้นหาจากชื่อ / เบอร์โทร / ที่อยู่
  Future<List<Customer>> getCustomers({String query = ''}) async {
    final db = await database;
    final q = query.trim();
    final rows = await db.rawQuery('''
      SELECT c.*,
             COUNT(o.id)            AS order_count,
             IFNULL(SUM(o.total),0) AS total_spent
      FROM customers c
      LEFT JOIN orders o ON o.customer_id = c.id
      ${q.isEmpty ? '' : 'WHERE c.name LIKE ? OR c.phone LIKE ? OR c.address LIKE ?'}
      GROUP BY c.id
      ORDER BY c.id DESC
    ''', q.isEmpty ? [] : ['%$q%', '%$q%', '%$q%']);
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> insertCustomer(Customer c) async {
    final db = await database;
    final id = await db.insert('customers', c.toMap()..remove('id'));
    _notify();
    return id;
  }

  Future<void> updateCustomer(Customer c) async {
    final db = await database;
    await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    _notify();
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  // ------------------------------------------------------------------ orders

  /// สร้างคำสั่งซื้อ + ตัดสต็อกสินค้า (ทำใน transaction เดียว)
  Future<int> createOrder(int customerId, List<OrderItem> items) async {
    final db = await database;
    final total = items.fold<double>(0, (sum, i) => sum + i.subtotal);
    final orderId = await db.transaction((txn) async {
      final id = await txn.insert('orders', {
        'customer_id': customerId,
        'total': total,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (final item in items) {
        await txn.insert('order_items', {
          'order_id': id,
          'product_id': item.productId,
          'product_name': item.productName,
          'price': item.price,
          'quantity': item.quantity,
        });
        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(stock - ?, 0) WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      return id;
    });
    _notify();
    return orderId;
  }

  Future<List<Order>> getOrdersForCustomer(int customerId) async {
    final db = await database;
    final orderRows = await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'id DESC',
    );
    final result = <Order>[];
    for (final o in orderRows) {
      final itemRows = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [o['id']],
      );
      result.add(Order(
        id: o['id'] as int,
        customerId: customerId,
        total: (o['total'] as num).toDouble(),
        createdAt: o['created_at'] as String,
        items: itemRows.map(OrderItem.fromMap).toList(),
      ));
    }
    return result;
  }

  // -------------------------------------------------------------- seed data

  static const _seedProducts = [
    Product(
      name: 'ຄົວຊອງເນີຍສົດ',
      category: 'ເຂົ້າໜົມປັງ',
      price: 25000,
      image: 'assets/images/croissant.jpg',
      description: 'ຄົວຊອງອົບໃໝ່ທຸກເຊົ້າ ໃຊ້ເນີຍສົດແທ້ຈາກຝຣັ່ງ ກອບນອກນຸ້ມໃນ ຫອມເນີຍທຸກຄຳ',
      stock: 30,
    ),
    Product(
      name: 'ເຄັກຊັອກໂກແລັດເຂັ້ມຂຸ້ນ',
      category: 'ເຄັກ',
      price: 45000,
      image: 'assets/images/chocolate_cake.jpg',
      description: 'ເຄັກຊັອກໂກແລັດເນື້ອແໜ້ນ ລາດດ້ວຍການາສດາກຊັອກໂກແລັດ 70% ເຂັ້ມຂຸ້ນເຖິງໃຈ',
      stock: 15,
    ),
    Product(
      name: 'ບາແກັດຝຣັ່ງ',
      category: 'ເຂົ້າໜົມປັງ',
      price: 35000,
      image: 'assets/images/baguette.jpg',
      description: 'ເຂົ້າໜົມປັງບາແກັດເປືອກກອບ ເນື້ອໜຽວນຸ້ມ ເໝາະເຮັດແຊນວິດ ຫຼື ກິນກັບແກງ',
      stock: 20,
    ),
    Product(
      name: 'ໂດນັດສະຕໍເບີຣີ',
      category: 'ເຂົ້າໜົມຫວານ',
      price: 20000,
      image: 'assets/images/donut.jpg',
      description: 'ໂດນັດເນື້ອນຸ້ມຟູ ເຄືອບໄອຊິງສະຕໍເບີຣີສີບົວ ໂຣຍເມັດນ້ຳຕານສີສັນສົດໃສ',
      stock: 40,
    ),
    Product(
      name: 'ຊິນນາມອນໂຣລ',
      category: 'ເຂົ້າໜົມປັງ',
      price: 30000,
      image: 'assets/images/cinnamon_roll.jpg',
      description: 'ເຂົ້າໜົມປັງມ້ວນອົບເຊີຍ ຫອມກຸ່ນ ລາດຄຣີມຊີສໄອຊິງ ກິນຄູ່ກາເຟແຊບຫຼາຍ',
      stock: 25,
    ),
    Product(
      name: 'ສະຕໍເບີຣີຊອດເຄັກ',
      category: 'ເຄັກ',
      price: 55000,
      image: 'assets/images/strawberry_cake.jpg',
      description: 'ເຄັກສະປັນຈ໌ນຸ້ມເບົາ ສະຫຼັບຊັ້ນວິບຄຣີມສົດ ແລະ ສະຕໍເບີຣີສົດຫວານອົມສົ້ມ',
      stock: 12,
    ),
    Product(
      name: 'ຊູຄຣີມວານິລາ',
      category: 'ເຂົ້າໜົມຫວານ',
      price: 15000,
      image: 'assets/images/cream_puff.jpg',
      description: 'ແປ້ງຊູກອບເບົາ ສອດໄສ້ຄັສຕາດວານິລາແທ້ເຕັມຄຳ ຫວານພໍດີ',
      stock: 50,
    ),
    Product(
      name: 'ເມລອນປັງ',
      category: 'ເຂົ້າໜົມປັງ',
      price: 22000,
      image: 'assets/images/melon_pan.jpg',
      description: 'ເຂົ້າໜົມປັງສະໄຕລ໌ຍີ່ປຸ່ນ ຜິວຄຸກກີ້ກອບຫວານ ເນື້ອໃນນຸ້ມຟູຫອມນົມ',
      stock: 35,
    ),
  ];
}
