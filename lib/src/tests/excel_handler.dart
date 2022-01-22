// import 'dart:convert';
// import 'package:excel/excel.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:http/http.dart' as http;

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _index = 0;

//   List<String> listProductsId = [];

//   late var myFile;
//   _pickExcelFile() async {
//     var file = await FilePicker.platform.pickFiles(allowedExtensions: ['xlsx']);
//     setState(() {
//       myFile = file;
//     });
//   }

//   void _readDataFromExcel() async {
//     // var bytes = File(myFile!.files.single.name).readAsBytesSync();
//     ByteData data = await rootBundle.load('assets/Book.xlsx');
//     // var excel = Excel.decodeBytes(bytes);
//     var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//     var excel = Excel.decodeBytes(bytes);

//     excel.tables.values.forEach((val) {
//       // Get all fields - in the first column "Name column"
//       // for (int i = 1; i < val.rows.length; i++) {
//       //   // print('Rows length: ${val.rows.length} end');

//       //   for (int y = 0; y <= 1; y++) {
//       //     if (val.rows[i][y] != null) {
//       //       print('val.rows[$i][$y]: ${val.rows[i][y]!.value}');
//       //     }
//       //   }
//       // }

//       // Will print all productIds in the first column
//       for (int i = 1; i < val.rows.length; i++) {
//         // print('I am row - header $i & Index: $i;');
//         if (val.rows.isNotEmpty &&
//             val.rows[i][0] != null &&
//             val.rows[i][1] != null) {
//           var productIdCol = val.rows[i][0]!.value;
//           var availableItemsCol = val.rows[i][1]!.value;
//           if (listProductsId.contains(productIdCol) &&
//               val.rows[i][0] != null &&
//               val.rows[i][1] != null) {
//             print('productIdCol: $productIdCol');
//             print('availableItemsCol: $availableItemsCol');

//             //TODO: update data by id
//             _updateDataById(
//                 id: productIdCol, availableItems: availableItemsCol);
//           }
//           // print(
//           //     'ProductId $i: $productIdCol & AvailableItems $i: $availableItemsCol');
//         }
//       }
//       // val.rows[i].forEach((row) {
//       //   // print('I am row: ${row!.value.toString()} end');
//       //   if (row!.value == 'productId') {
//       //     print('I am row value name: ${val.rows[i][0]!.value}');
//       //     // Will print all fields in first column
//       //     // print('All column fields: ${val.rows[0]}');
//       //   }
//       // });
//       // for (int i = 1; i < val.rows.length; i++) {
//       //   val.rows[i].forEach((row) {
//       //     print('cell val: ${row!.value.toString()}');
//       //   });
//       //   updateDataById(
//       //     id: 'CAu3Cm14RaCvkuwLvR6l',
//       //     // name: val.rows[1][0]!.props[0].toString(),
//       //     name: 'Nour',
//       //     age: 30,
//       //   );
//       //   // getRequest(name: valById(.rows[1][0]!.props[0].toString(), age: 20);
//       // }
//     });
//   }

//   late int recitersCount = 0;

//   Future _getProductIds() async {
//     var url = Uri.parse(
//         'https://firestore.googleapis.com/v1/projects/electric-market/databases/(default)/documents/APIs/');
//     try {
//       await http.get(url).then((value) {
//         // print('response.statusCode: ${value.statusCode} end');
//         // print('response.body: ${value.body} end');
//         var decodedData = jsonDecode(value.body);
//         var documents = decodedData['documents'];

//         for (int i = 0; i < documents.length; i++) {
//           Map<String, dynamic> doc = documents[i]['fields']['productId'];
//           doc.values.forEach((value) {
//             listProductsId.add(value);
//             print('productId: $value');
//           });
//         }
//         return listProductsId;
//       });
//     } catch (e) {
//       print('I am catch error: ${e.toString()}');
//     }
//   }

//   void _updateDataById(
//       {required String id, required int availableItems}) async {
//     var url = Uri.parse(
//         'https://firestore.googleapis.com/v1/projects/electric-market/databases/(default)/documents/APIs/$id?updateMask.fieldPaths=availableItems');
//     final data = jsonEncode({
//       "fields": {
//         "availableItems": {"integerValue": availableItems},
//       },
//     });
//     try {
//       await http.patch(url, body: data).then((value) {
//         // print('response.statusCode: ${value.statusCode} end');
//         // print('response.body: ${value.body} end');
//       });
//     } catch (e) {
//       print('I am catch error: ${e.toString()}');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setSystemUIOverlayStyle(
//       SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//       ),
//     );
//     return Scaffold(
//       backgroundColor: const Color(0xFF121212),
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             backgroundColor: Color(0xFF45CB88),
//             floating: true,
//             pinned: true,
//             centerTitle: true,
//             title: Text(
//               'مذكري',
//               style: TextStyle(
//                 // fontWeight: FontWeight.w300,
//                 fontSize: 22,
//               ),
//             ),
//             // expandedHeight: 120,
//             collapsedHeight: 100,
//             flexibleSpace: FlexibleSpaceBar(
//               centerTitle: true,
//               title: Text(
//                 'خليه أول تطبيق تشوفه عينك',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w300,
//                   fontSize: 20,
//                 ),
//               ),
//             ),
//           ),
//           // SliverList(
//           //   delegate: SliverChildBuilderDelegate(
//           //     (context, index) => ListTile(
//           //       title: Text('$index'),
//           //     ),
//           //     childCount: 10,
//           //   ),
//           // ),
//           SliverPadding(
//             padding: const EdgeInsets.all(20.0),
//             sliver: SliverGrid.count(
//               childAspectRatio: 1,
//               crossAxisSpacing: 20,
//               mainAxisSpacing: 30,
//               crossAxisCount: 2,
//               children: [
//                 // CustomCard(
//                 //   onTap: () {},
//                 //   title: 'أذكار الصباح',
//                 //   image: 'assets/images/sun.svg',
//                 //   color: Color(0xFFF79400),
//                 // ),
//                 // CustomCard(
//                 //   onTap: () {},
//                 //   title: 'أذكار المساء',
//                 //   image: 'assets/images/sunset.svg',
//                 //   color: Color(0xFF00C750),
//                 // ),
//                 // CustomCard(
//                 //   onTap: () {},
//                 //   title: 'أذكار بعد الصلاة',
//                 //   image: 'assets/images/pray.svg',
//                 //   color: Color(0xFF45B5FF),
//                 // ),
//                 // CustomCard(
//                 //   onTap: () {},
//                 //   title: 'أذكار النوم',
//                 //   image: 'assets/images/brightness.svg',
//                 //   color: Color(0xFF42BDB7),
//                 // ),

//                 // //TODO: handle http requests here

//                 // ElevatedButton(
//                 //   onPressed: _getProductIds,
//                 //   child: Text(
//                 //     'Get api data',
//                 //     style: TextStyle(
//                 //       color: Colors.black,
//                 //     ),
//                 //   ),
//                 // ),

//                 // ElevatedButton(
//                 //   onPressed: _readDataFromExcel,
//                 //   child: Text(
//                 //     'عرض الملف',
//                 //     style: TextStyle(
//                 //       color: Colors.black,
//                 //     ),
//                 //   ),
//                 // ),

//                 // ElevatedButton(
//                 //   onPressed: openAudio,
//                 //   child: Column(
//                 //     mainAxisAlignment: MainAxisAlignment.center,
//                 //     children: [
//                 //       Text(
//                 //         'عرض القراء',
//                 //         style: TextStyle(
//                 //           color: Colors.black,
//                 //         ),
//                 //       ),
//                 //       const SizedBox(height: 10),
//                 //       Text(
//                 //         'عدد القراء $recitersCount',
//                 //         style: TextStyle(
//                 //           color: Colors.black,
//                 //         ),
//                 //       ),
//                 //     ],
//                 //   ),
//                 // ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         onTap: (val) {
//           setState(() {
//             _index = val;
//           });
//         },
//         backgroundColor: Color(0xFF242424),
//         selectedItemColor: Color(0xFFC3E5FF),
//         selectedFontSize: 14.0,
//         unselectedFontSize: 14.0,
//         unselectedItemColor: Color(0xFF8BA2B3),
//         type: BottomNavigationBarType.fixed,
//         // showUnselectedLabels: false,
//         currentIndex: _index,
//         items: [
//           BottomNavigationBarItem(
//             label: 'أذكاري',
//             icon: SvgPicture.asset(
//               'assets/images/book.svg',
//               width: 23,
//               height: 23,
//               color: _index == 0 ? Color(0xFFC3E5FF) : Color(0xFF8BA2B3),
//             ),
//           ),
//           BottomNavigationBarItem(
//             label: 'السبحة',
//             icon: SvgPicture.asset(
//               'assets/images/sibha.svg',
//               width: 25,
//               height: 25,
//               color: _index == 1 ? Color(0xFFC3E5FF) : Color(0xFF8BA2B3),
//             ),
//           ),
//           BottomNavigationBarItem(
//             label: 'مشاركة',
//             icon: Icon(Icons.share),
//           ),
//         ],
//       ),
//     );
//     // return Scaffold(
//     //   appBar: AppBar(
//     //     title: Text('الصفحة الرئيسية'),
//     //   ),
//     //   body: GestureDetector(
//     //     onTap: () => Navigator.push(
//     //       context,
//     //       CustomPageRoute(
//     //         child: ViewPage(),
//     //       ),
//     //     ),
//     //     child: Container(
//     //       color: Colors.blue,
//     //       width: 153,
//     //       height: 152,
//     //     ),
//     //   ),
//     // );
//   }
// }

// class CustomCard extends StatelessWidget {
//   const CustomCard({
//     required this.onTap,
//     required this.title,
//     required this.image,
//     required this.color,
//   });

//   final Function() onTap;
//   final String title;
//   final String image;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SvgPicture.asset(
//             image,
//             // width: 60.0,
//             height: 60.0,
//           ),
//           const SizedBox(height: 20),
//           Text(
//             title,
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//       decoration: BoxDecoration(
//         color: const Color(0xFF242424),
//         borderRadius: BorderRadius.all(
//           Radius.circular(20),
//         ),
//       ),
//     );
//   }
// }
