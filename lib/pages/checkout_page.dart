import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/cart.dart';
import '../data/database_helper.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'customer_form.dart';

/// หน้ายืนยันคำสั่งซื้อ: เลือกลูกค้าเดิม หรือกรอกข้อมูลลูกค้าใหม่ -> บันทึกลงฐานข้อมูล
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _db = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _fields = CustomerFormFields();
  final _searchCtrl = TextEditingController();

  bool _isNew = true;
  List<Customer> _customers = [];
  Customer? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _fields.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final list = await _db.getCustomers(query: _searchCtrl.text);
    if (mounted) setState(() => _customers = list);
  }

  Future<void> _sendOrderToServer({
    required Customer customer,
    required List<OrderItem> items,
  }) async {
    try {
      final url = Uri.parse('http://localhost:3000/api/orders');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer': {
            'name': customer.name,
            'phone': customer.phone,
            'address': customer.address,
            'note': customer.note,
          },
          'items': items.map((item) => {
            'product_id': item.productId,
            'product_name': item.productName,
            'price': item.price,
            'quantity': item.quantity,
          }).toList(),
        }),
      ).timeout(const Duration(seconds: 4));

      debugPrint('Sync order to server status: ${res.statusCode}');
    } catch (e) {
      debugPrint('Could not sync to server (offline or server not reachable): $e');
    }
  }

  Future<void> _confirm() async {
    final cart = Cart.instance;
    if (cart.isEmpty) return;

    int customerId;
    String customerName;
    Customer orderCustomer;

    if (_isNew) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _saving = true);
      final c = _fields.toCustomer();
      customerId = await _db.insertCustomer(c);
      customerName = c.name;
      orderCustomer = Customer(
        id: customerId,
        name: c.name,
        phone: c.phone,
        address: c.address,
        note: c.note,
        createdAt: c.createdAt,
      );
    } else {
      if (_selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ກະລຸນາເລືອກລູກຄ້າ')),
        );
        return;
      }
      setState(() => _saving = true);
      customerId = _selected!.id!;
      customerName = _selected!.name;
      orderCustomer = _selected!;
    }

    final total = cart.totalPrice;
    final orderItems = cart.toOrderItems();
    final orderId = await _db.createOrder(customerId, orderItems);

    // ส่งข้อมูลออเดอร์ไปยังเซิร์ฟเวอร์หลังบ้าน (http://localhost:3000/api/orders) ทันที
    await _sendOrderToServer(customer: orderCustomer, items: orderItems);

    cart.clear();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.mint, size: 64),
        title: const Text('ສັ່ງຊື້ສຳເລັດ!'),
        content: Text(
          'ເລກທີຄຳສັ່ງຊື້ #${orderId.toString().padLeft(5, '0')}\n'
          'ລູກຄ້າ: $customerName\n'
          'ຍອດລວມ: ${formatPrice(total)}\n\n'
          'ບັນທຶກຂໍ້ມູນລົງຖານຂໍ້ມູນຮຽບຮ້ອຍ',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ຕົກລົງ'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('ຢືນຢັນຄຳສັ່ງຊື້')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- สรุปรายการ ----
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ສະຫຼຸບລາຍການ',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const Divider(),
                  for (final i in cart.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text('${i.product.name}  x${i.quantity}')),
                          Text(formatPrice(i.subtotal)),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('ຍອດລວມ',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Text(
                        formatPrice(cart.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.strawberry,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ---- ข้อมูลลูกค้า ----
          const Text('ຂໍ້ມູນລູກຄ້າ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('ລູກຄ້າໃໝ່'), icon: Icon(Icons.person_add)),
              ButtonSegment(value: false, label: Text('ລູກຄ້າເກົ່າ'), icon: Icon(Icons.people)),
            ],
            selected: {_isNew},
            onSelectionChanged: (s) => setState(() => _isNew = s.first),
          ),
          const SizedBox(height: 16),
          if (_isNew)
            Form(key: _formKey, child: CustomerFormBody(fields: _fields))
          else ...[
            SearchField(
              controller: _searchCtrl,
              hint: 'ຄົ້ນຫາຊື່ ຫຼື ເບີໂທລູກຄ້າ',
              onChanged: (_) => _loadCustomers(),
            ),
            const SizedBox(height: 8),
            if (_customers.isEmpty)
              const EmptyState(
                icon: Icons.person_search,
                message: 'ບໍ່ພົບລູກຄ້າ\nລອງເລືອກ "ລູກຄ້າໃໝ່"',
              )
            else
              RadioGroup<int>(
                groupValue: _selected?.id,
                onChanged: (id) => setState(
                  () => _selected = _customers.firstWhere((c) => c.id == id),
                ),
                child: Column(
                  children: [
                    for (final c in _customers)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: RadioListTile<int>(
                          value: c.id!,
                          activeColor: AppColors.caramel,
                          title: Text(c.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(c.phone.isEmpty ? '-' : c.phone),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _saving || cart.isEmpty ? null : _confirm,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text('ຢືນຢັນການສັ່ງຊື້ ${formatPrice(cart.totalPrice)}'),
          ),
        ),
      ),
    );
  }
}

