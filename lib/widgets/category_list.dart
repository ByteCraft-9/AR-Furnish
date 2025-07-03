// import 'package:flutter/material.dart';
// import 'package:ar_furnish/data/dummy_data.dart';

// class CategoryList extends StatelessWidget {
//   const CategoryList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 120,
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: DummyData.categories.length,
//         itemBuilder: (context, index) {
//           final category = DummyData.categories[index];
//           return Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: GestureDetector(
//               onTap: () => Navigator.pushNamed(
//                 context,
//                 '/categories',
//                 arguments: category['name'],
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: category['color'].withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Icon(
//                       category['icon'],
//                       color: category['color'],
//                       size: 30,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     category['name'],
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }