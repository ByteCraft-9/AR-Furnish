import 'package:flutter/material.dart';
import 'package:ar_furnish/models/order.dart';
import 'package:ar_furnish/widgets/orders/order_card.dart';

class OrderList extends StatelessWidget {
  final List<Order> orders;

  const OrderList({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders yet'),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) => OrderCard(order: orders[index]),
    );
  }
}