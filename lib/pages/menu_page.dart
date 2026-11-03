import 'dart:async';

import 'package:flutter/material.dart';

import '../data/cart.dart';
import '../data/database_helper.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'product_detail_page.dart';

class MenuRequest {
  final String query;
  final String? category;
  const MenuRequest({this.query = '', this.category});
}

/// หน้าเมนูทั้งหมด: ค้นหา + กรองตามหมวด + ตารางสินค้า
class MenuPage extends StatefulWidget {
  final ValueNotifier<MenuRequest?> request;
  const MenuPage({super.key, required this.request});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final _db = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();
  String _category = DatabaseHelper.categories.first;
  List<Product> _products = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _db.changes.addListener(_load);
    widget.request.addListener(_applyRequest);
  }

  @override
  void dispose() {
    _db.changes.removeListener(_load);
    widget.request.removeListener(_applyRequest);
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyRequest() {
    final r = widget.request.value;
    if (r == null) return;
    _searchCtrl.text = r.query;
    _category = r.category ?? DatabaseHelper.categories.first;
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getProducts(query: _searchCtrl.text, category: _category);
    if (!mounted) return;
    setState(() {
      _products = list;
      _loading = false;
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _load);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 1000 ? 4 : (width > 650 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(title: const Text('เมนูขนม')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'ค้นหาชื่อขนม หมวด หรือรายละเอียด',
              onChanged: _onSearchChanged,
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final c in DatabaseHelper.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _category == c ? Colors.white : AppColors.cocoa,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() => _category = c);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'พบ ${_products.length} รายการ',
                style: const TextStyle(color: AppColors.mocha),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        message: 'ไม่พบขนมที่ค้นหา\nลองใช้คำอื่นดูนะ',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, i) {
                          final p = _products[i];
                          return ProductCard(
                            product: p,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(product: p),
                              ),
                            ),
                            onAdd: () {
                              Cart.instance.add(p, 1);
                              showAddedSnack(context, p, 1);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

