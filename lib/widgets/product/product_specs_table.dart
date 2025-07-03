import 'package:flutter/material.dart';

class ProductSpecsTable extends StatelessWidget {
  final Map<String, dynamic> specifications;

  const ProductSpecsTable({super.key, required this.specifications});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      children: specifications.entries.map((entry) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(entry.value.toString()),
            ),
          ],
        );
      }).toList(),
    );
  }
}