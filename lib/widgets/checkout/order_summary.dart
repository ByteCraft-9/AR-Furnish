import 'package:flutter/material.dart';
import 'package:ar_furnish/providers/cart_provider.dart';

class OrderSummary extends StatelessWidget {
  final CartProvider cart;

  const OrderSummary({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...cart.items.values.map((item) => ListTile(
              title: Text(item.product.name),
              subtitle: Text('Quantity: ${item.quantity}'),
              trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
            )),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${cart.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
