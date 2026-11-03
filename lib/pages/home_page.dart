import 'package:flutter/material.dart';

import '../data/cart.dart';
import '../data/database_helper.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'product_detail_page.dart';

/// หน้าหลัก: แบนเนอร์ • ช่องค้นหา • หมวดหมู่ • สินค้าแนะนำ
class HomePage extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onCategory;
  final VoidCallback onSeeAll;

  const HomePage({
    super.key,
    required this.onSearch,
    required this.onCategory,
    required this.onSeeAll,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  final _db = DatabaseHelper.instance;
  List<Product> _products = [];
  bool _loading = true;

  static const _categoryIcons = {
    'ขนมปัง': Icons.bakery_dining,
    'เค้ก': Icons.cake,
    'ขนมหวาน': Icons.icecream,
  };

  @override
  void initState() {
    super.initState();
    _load();
    _db.changes.addListener(_load);
  }

  @override
  void dispose() {
    _db.changes.removeListener(_load);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _db.getProducts();
    if (!mounted) return;
    setState(() {
      _products = list;
      _loading = false;
    });
  }

  void _submitSearch(String q) {
    widget.onSearch(q);
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _openDetail(Product p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = [..._products]..sort((a, b) => b.price.compareTo(a.price));

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // ---------- หัวข้อ ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('สวัสดีค่ะ 👋',
                                  style: TextStyle(color: AppColors.mocha, fontSize: 15)),
                              Text(
                                'Sweet Crumb Bakery',
                                style: TextStyle(
                                  color: AppColors.cocoa,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.butter,
                          child: const Icon(Icons.storefront, color: AppColors.caramel),
                        ),
                      ],
                    ),
                  ),

                  // ---------- ค้นหา ----------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: SearchField(
                      controller: _searchCtrl,
                      hint: 'ค้นหาขนมที่คุณชอบ...',
                      onSubmitted: _submitSearch,
                    ),
                  ),

                  // ---------- แบนเนอร์ ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 16 / 8,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ProductImage('assets/images/banner.jpg'),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.cocoa.withValues(alpha: 0.85),
                                    AppColors.cocoa.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'อบสดใหม่ทุกวัน',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'หอมกรุ่นจากเตาถึงมือคุณ',
                                    style: TextStyle(color: AppColors.butter),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.strawberry,
                                    ),
                                    onPressed: widget.onSeeAll,
                                    child: const Text('สั่งเลย'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ---------- หมวดหมู่ ----------
                  const _SectionTitle('หมวดหมู่'),
                  SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        for (final c in DatabaseHelper.categories.skip(1))
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => widget.onCategory(c),
                              child: Container(
                                width: 92,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.butter, width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.butter,
                                      child: Icon(_categoryIcons[c], color: AppColors.caramel),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(c,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.cocoa)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ---------- แนะนำ ----------
                  _SectionTitle('เมนูแนะนำ', action: 'ดูทั้งหมด', onAction: widget.onSeeAll),
                  SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: featured.take(5).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final p = featured[i];
                        return SizedBox(
                          width: 170,
                          child: ProductCard(
                            product: p,
                            onTap: () => _openDetail(p),
                            onAdd: () {
                              Cart.instance.add(p, 1);
                              showAddedSnack(context, p, 1);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // ---------- ราคาประหยัด ----------
                  const _SectionTitle('ขนมราคาสบายกระเป๋า'),
                  for (final p in [..._products]
                    ..sort((a, b) => a.price.compareTo(b.price)))
                    if (p.price <= 45)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            onTap: () => _openDetail(p),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: ProductImage(p.image),
                              ),
                            ),
                            title: Text(p.name,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('คงเหลือ ${p.stock} ชิ้น',
                                style: const TextStyle(color: AppColors.mocha)),
                            trailing: Text(
                              formatPrice(p.price),
                              style: const TextStyle(
                                color: AppColors.strawberry,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionTitle(this.title, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.cocoa,
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
