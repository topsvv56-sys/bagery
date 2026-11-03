import 'dart:async';

import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'customer_form.dart';

/// หน้ารายชื่อลูกค้า (ข้อมูลจากฐานข้อมูล) + ค้นหา + เพิ่ม/แก้ไข/ลบ
class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _db = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();
  List<Customer> _customers = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _db.changes.addListener(_load);
  }

  @override
  void dispose() {
    _db.changes.removeListener(_load);
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _db.getCustomers(query: _searchCtrl.text);
    if (!mounted) return;
    setState(() {
      _customers = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSales = _customers.fold<double>(0, (s, c) => s + c.totalSpent);

    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลลูกค้า')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerFormPage()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('เพิ่มลูกค้า'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'ค้นหาชื่อ เบอร์โทร หรือที่อยู่',
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), _load);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatBox(
                  icon: Icons.people,
                  label: 'ลูกค้า',
                  value: '${_customers.length} คน',
                  color: AppColors.caramel,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  icon: Icons.payments,
                  label: 'ยอดขายรวม',
                  value: formatPrice(totalSales),
                  color: AppColors.strawberry,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search,
                        message: _searchCtrl.text.isEmpty
                            ? 'ยังไม่มีข้อมูลลูกค้า\nกด "เพิ่มลูกค้า" หรือสั่งซื้อสินค้าได้เลย'
                            : 'ไม่พบลูกค้าที่ค้นหา',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: _customers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final c = _customers[i];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.butter,
                                child: Text(
                                  c.name.characters.first,
                                  style: const TextStyle(
                                    color: AppColors.caramel,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(c.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${c.phone.isEmpty ? '-' : c.phone}  •  สั่ง ${c.orderCount} ครั้ง',
                                style: const TextStyle(color: AppColors.mocha),
                              ),
                              trailing: Text(
                                formatPrice(c.totalSpent),
                                style: const TextStyle(
                                  color: AppColors.strawberry,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerDetailPage(customer: c),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.mocha, fontSize: 12)),
                  Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// รายละเอียดลูกค้า + ประวัติการสั่งซื้อ
class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final _db = DatabaseHelper.instance;
  late Customer _customer = widget.customer;
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await _db.getOrdersForCustomer(_customer.id!);
    final updated = (await _db.getCustomers())
        .where((c) => c.id == _customer.id)
        .firstOrNull;
    if (!mounted) return;
    setState(() {
      _orders = orders;
      if (updated != null) _customer = updated;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CustomerFormPage(customer: _customer)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบลูกค้า?'),
        content: Text('ลบ "${_customer.name}" และประวัติการสั่งซื้อทั้งหมด'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ', style: TextStyle(color: AppColors.strawberry)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteCustomer(_customer.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _customer;
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดลูกค้า'),
        actions: [
          IconButton(onPressed: _edit, icon: const Icon(Icons.edit)),
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete, color: AppColors.strawberry),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.butter,
                    child: Text(
                      c.name.characters.first,
                      style: const TextStyle(
                        fontSize: 30,
                        color: AppColors.caramel,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(c.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _InfoRow(Icons.phone, c.phone),
                  _InfoRow(Icons.location_on, c.address),
                  _InfoRow(Icons.sticky_note_2, c.note),
                  _InfoRow(Icons.calendar_today, 'สมาชิกตั้งแต่ ${formatDate(c.createdAt)}'),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Column(children: [
                          Text('${c.orderCount}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.caramel)),
                          const Text('คำสั่งซื้อ', style: TextStyle(color: AppColors.mocha)),
                        ]),
                      ),
                      Expanded(
                        child: Column(children: [
                          Text(formatPrice(c.totalSpent),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.strawberry)),
                          const Text('ยอดซื้อรวม', style: TextStyle(color: AppColors.mocha)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('ประวัติการสั่งซื้อ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_orders.isEmpty)
            const EmptyState(icon: Icons.receipt_long, message: 'ยังไม่มีคำสั่งซื้อ')
          else
            for (final o in _orders)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  shape: const Border(),
                  leading: const Icon(Icons.receipt_long, color: AppColors.caramel),
                  title: Text('#${o.id.toString().padLeft(5, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(formatDate(o.createdAt)),
                  trailing: Text(
                    formatPrice(o.total),
                    style: const TextStyle(
                        color: AppColors.strawberry, fontWeight: FontWeight.bold),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    for (final it in o.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text('${it.productName}  x${it.quantity}')),
                            Text(formatPrice(it.subtotal)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.caramel),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.mocha))),
        ],
      ),
    );
  }
}

