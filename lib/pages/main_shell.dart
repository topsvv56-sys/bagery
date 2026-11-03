import 'package:flutter/material.dart';

import '../data/cart.dart';
import '../theme.dart';
import 'cart_page.dart';
import 'customers_page.dart';
import 'home_page.dart';
import 'menu_page.dart';

/// โครงหลักของแอพ: แถบเมนูด้านล่าง 4 หน้า (ไม่มีหน้าล็อกอิน)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// ใช้ส่งคำค้น / หมวดหมู่ จากหน้าหลักไปหน้าเมนู
  final menuRequest = ValueNotifier<MenuRequest?>(null);

  void _openMenu({String query = '', String? category}) {
    menuRequest.value = MenuRequest(query: query, category: category);
    setState(() => _index = 1);
  }

  @override
  void dispose() {
    menuRequest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onSearch: (q) => _openMenu(query: q),
        onCategory: (c) => _openMenu(category: c),
        onSeeAll: () => _openMenu(),
      ),
      MenuPage(request: menuRequest),
      CartPage(onShopMore: () => setState(() => _index = 1)),
      const CustomersPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) => NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.caramel),
              label: 'ໜ້າຫຼັກ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bakery_dining_outlined),
              selectedIcon: Icon(Icons.bakery_dining, color: AppColors.caramel),
              label: 'ເມນູ',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: Cart.instance.totalQuantity > 0,
                backgroundColor: AppColors.strawberry,
                label: Text('${Cart.instance.totalQuantity}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: Cart.instance.totalQuantity > 0,
                backgroundColor: AppColors.strawberry,
                label: Text('${Cart.instance.totalQuantity}'),
                child: const Icon(Icons.shopping_bag, color: AppColors.caramel),
              ),
              label: 'ກະຕ່າ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: AppColors.caramel),
              label: 'ລູກຄ້າ',
            ),
          ],
        ),
      ),
    );
  }
}

