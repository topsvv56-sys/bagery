import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:application_bagery/theme.dart';
import 'package:application_bagery/pages/product_detail_page.dart';

void main() {
  test('formatPrice adds kip sign and thousand separators', () {
    expect(formatPrice(45), '₭45');
    expect(formatPrice(1250), '₭1,250');
    expect(formatPrice(1234567.5), '₭1,234,567.50');
  });

  testWidgets('QuantityStepper increments and decrements', (tester) async {
    var value = 1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => QuantityStepper(
            value: value,
            min: 1,
            max: 3,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
