import 'package:flutter/material.dart';

import '../data/cart.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'checkout_page.dart';
import 'product_detail_page.dart';

/// หน้าตะกร้า: ปรับจำนวน • ลบ • สรุปราคา • ไปชำระเงิน
class CartPage extends StatelessWidget {
  final VoidCallback onShopMore;
  const CartPage({super.key, required this.onShopMore});

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตะกร้าของฉัน'),
        actions: [
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) => cart.isEmpty
                ? const SizedBox.shrink()
                : TextButton.icon(
                    onPressed: () => _confirmClear(context),
                    icon: const Icon(Icons.delete_sweep, color: AppColors.strawberry),
                    label: const Text('ล้าง', style: TextStyle(color: AppColors.strawberry)),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    message: 'ตะกร้ายังว่างอยู่\nเลือกขนมอร่อย ๆ กันเถอะ',
                  ),
                  ElevatedButton(onPressed: onShopMore, child: const Text('ไปที่เมนู')),
                ],
              ),
            );
          }
          final items = cart.items;
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final p = item.product;
                    return Dismissible(
                      key: ValueKey(p.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => cart.remove(p.id!),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AppColors.strawberry,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: ProductImage(p.image),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('${formatPrice(p.price)} / ชิ้น',
                                        style: const TextStyle(color: AppColors.mocha)),
                                    const SizedBox(height: 6),
                                    QuantityStepper(
                                      compact: true,
                                      value: item.quantity,
                                      min: 0,
                                      max: p.stock,
                                      onChanged: (v) => cart.setQuantity(p.id!, v),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatPrice(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.strawberry,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _Summary(cart: cart),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ล้างตะกร้า?'),
        content: const Text('ต้องการลบสินค้าทั้งหมดในตะกร้าใช่ไหม'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ล้าง')),
        ],
      ),
    );
    if (ok == true) Cart.instance.clear();
  }
}

class _Summary extends StatelessWidget {
  final Cart cart;
  const _Summary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: AppColors.cocoa.withValues(alpha: 0.08), blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('จำนวนทั้งหมด', style: TextStyle(color: AppColors.mocha)),
              const Spacer(),
              Text('${cart.totalQuantity} ชิ้น'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('ยอดรวม',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                formatPrice(cart.totalPrice),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.strawberry,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutPage()),
              ),
              icon: const Icon(Icons.receipt_long),
              label: const Text('สั่งซื้อ'),
            ),
          ),
        ],
      ),
    );
  }
}

