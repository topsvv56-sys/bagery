import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';

/// แสดงรูปสินค้า (ถ้าไม่มีไฟล์รูปจะแสดงไอคอนแทน)
class ProductImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  const ProductImage(this.path, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.butter,
        alignment: Alignment.center,
        child: const Icon(Icons.bakery_dining, size: 48, color: AppColors.caramel),
      ),
    );
  }
}

/// การ์ดสินค้า: รูป • ชื่อ • ราคา • จำนวนคงเหลือ
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final soldOut = product.stock <= 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-${product.id}',
                    child: ProductImage(product.image),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(
                      text: soldOut ? 'ໝົດ' : 'ຍັງເຫຼືອ ${product.stock}',
                      color: soldOut ? Colors.grey : AppColors.cocoa,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.cocoa,
                    ),
                  ),
                  Text(
                    product.category,
                    style: const TextStyle(fontSize: 12, color: AppColors.mocha),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatPrice(product.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppColors.strawberry,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: IconButton.filled(
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.caramel,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          onPressed: soldOut ? null : onAdd,
                          icon: const Icon(Icons.add, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// ช่องค้นหาสำเร็จรูป
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: AppColors.caramel),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.mocha),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        ),
      ),
    );
  }
}

/// แสดงข้อความเมื่อไม่มีข้อมูล
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.caramel.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mocha, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

void showAddedSnack(BuildContext context, Product p, int qty) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.cocoa,
      duration: const Duration(seconds: 2),
      content: Text('ເພີ່ມ ${p.name} x$qty ໃສ່ກະຕ່າແລ້ວ'),
    ));
}

