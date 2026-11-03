import 'package:flutter/material.dart';

import '../data/cart.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

/// หน้ารายละเอียดสินค้า: รูปใหญ่ • ราคา • จำนวน • เพิ่มลงตะกร้า
class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1;

  Product get p => widget.product;
  int get _available => p.stock - Cart.instance.quantityOf(p.id!);

  @override
  Widget build(BuildContext context) {
    final canAdd = _available > 0;
    if (_qty > _available && _available > 0) _qty = _available;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppColors.cream,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.cocoa),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${p.id}',
                child: ProductImage(p.image),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(p.category),
                    backgroundColor: AppColors.butter,
                    labelStyle: const TextStyle(color: AppColors.caramel, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cocoa,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formatPrice(p.price),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.strawberry,
                        ),
                      ),
                      const Text(' / ชิ้น', style: TextStyle(color: AppColors.mocha)),
                      const Spacer(),
                      Icon(Icons.inventory_2_outlined,
                          size: 18, color: p.stock > 0 ? AppColors.mint : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        p.stock > 0 ? 'คงเหลือ ${p.stock} ชิ้น' : 'สินค้าหมด',
                        style: TextStyle(
                          color: p.stock > 0 ? AppColors.mint : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('รายละเอียด',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(p.description,
                      style: const TextStyle(color: AppColors.mocha, height: 1.6, fontSize: 15)),
                  const SizedBox(height: 24),
                  const Text('จำนวน',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuantityStepper(
                        value: canAdd ? _qty : 0,
                        min: 1,
                        max: _available,
                        onChanged: (v) => setState(() => _qty = v),
                      ),
                      const SizedBox(width: 12),
                      if (Cart.instance.quantityOf(p.id!) > 0)
                        Text(
                          'อยู่ในตะกร้า ${Cart.instance.quantityOf(p.id!)} ชิ้น',
                          style: const TextStyle(color: AppColors.mocha),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: AppColors.cocoa.withValues(alpha: 0.08), blurRadius: 12),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ราคารวม', style: TextStyle(color: AppColors.mocha)),
                  Text(
                    formatPrice(canAdd ? p.price * _qty : 0),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cocoa,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canAdd
                      ? () {
                          Cart.instance.add(p, _qty);
                          showAddedSnack(context, p, _qty);
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.shopping_bag),
                  label: Text(canAdd ? 'เพิ่มลงตะกร้า' : 'ไม่มีสินค้าเพิ่ม'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ปุ่ม - จำนวน +
class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool compact;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 40.0;
    Widget btn(IconData icon, VoidCallback? onTap) => SizedBox(
          width: size,
          height: size,
          child: IconButton.filledTonal(
            padding: EdgeInsets.zero,
            iconSize: compact ? 16 : 20,
            style: IconButton.styleFrom(backgroundColor: AppColors.butter),
            onPressed: onTap,
            icon: Icon(icon, color: AppColors.caramel),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove, value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: compact ? 32 : 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: compact ? 15 : 20, fontWeight: FontWeight.bold),
          ),
        ),
        btn(Icons.add, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

