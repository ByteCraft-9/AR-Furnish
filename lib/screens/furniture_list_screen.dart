import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FurnitureListScreen extends StatelessWidget {
  final String category;

  FurnitureListScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$category Furniture')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('furniture')
            .where('category', isEqualTo: category)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['name']),
                // Add more details as needed
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
