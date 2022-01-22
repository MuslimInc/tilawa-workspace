import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RecitersModel extends ChangeNotifier {
  final baseUrl = Uri.parse('http://mp3quran.net/api/_arabic.json');
  Map<String, dynamic> mapData = {};
  List<dynamic> reciters = [];
  List<dynamic> recitersNames = [];
  final List<String> _names = [];
  final List<String> _dupicatedNames = [];
  final List<String> _allRewaya = [];

  bool hasAnotherRewaya = false;
  int? counter = 0;

  int? get getCounts => counter;

  List<dynamic> get getRecitersName => recitersNames;

// GET ALL RECITERS FROM MP3 QURAN API
  Future<List<Reciter>> getAllReciters() async {
    var response = await http.get(baseUrl);
    counter = reciters.length;
    if (response.statusCode == 200) {
      final recitersData = await jsonDecode(response.body);
      List<dynamic> recievedData = recitersData['reciters'];
      List<Reciter> allReciters =
          recievedData.map((data) => Reciter.fromJson(data)).toList();

      // Will return a list of reciters...
      return allReciters;
    } else {
      throw Exception('حدث خطأ، حاول مرة آخرى');
    }
  }
  // End - GET ALL RECITERS

// GET ALL RECITERS FROM MP3 QURAN API
  Future<Map> getAllData() async {
    var response = await http.get(baseUrl);
    counter = reciters.length;
    if (response.statusCode == 200) {
      final recitersData = await jsonDecode(response.body);
      List<dynamic> recievedData = recitersData['reciters'];
      Map allReciters = recievedData.asMap();

      // Will return a list of reciters...
      return allReciters;
    } else {
      throw Exception('حدث خطأ، حاول مرة آخرى');
    }
  }
  // End - GET ALL RECITERS

  Future getNames() async {
    var response = await http.get(baseUrl);

    Map<String, dynamic> data = await jsonDecode(response.body);
    List dataList = data['reciters'];
    for (int i = 0; i < dataList.length; i++) {
      if (dataList.contains(dataList[i])) {
        // print('NAME: ${dataList[i]['name']} END');
      }
    }
    // print('I am data: ${data['reciters']} end');
    // data.forEach((key, value) {
    //   for (int i = 0; i < value.length; i++) {
    //     // print('I am listss: ${value[i]['name']} end');
    //     // print('I am length: $i end');
    //     final currentName = value[i]['name'];
    //     final currentRewaya = value[i]['rewaya'];
    //     List<String> myList = [];
    //     names.add(currentName);
    //     myList.insert(0, currentRewaya);

    //     if (1 > 4) {
    //       print('I am value: $currentName end');
    //     } else {}
    //   }
    //   print('Names length: ${names.length - 1} end!');
    //   print('rewayaList: ${rewayaList}  rewayaList:end!');
    // });

    return data['name'];
  }

  get allRecitersCount => getAllRecitersCount();

  // Get repeated name
  List<String> get repeatedNames => _dupicatedNames;
  List<String> get allRewaya => _allRewaya;

  Future<int> getAllRecitersCount() async {
    var response = await http.get(baseUrl);

    mapData = jsonDecode(response.body);

    return mapData.length;
  }

  Future<List<dynamic>> getAllDuplicatedNames() async {
    var response = await http.get(baseUrl);
    mapData = await jsonDecode(response.body);
    if (mapData.isNotEmpty) {
      reciters = mapData['reciters'];

      for (var reciter in reciters) {
        final name = reciter['name'];
        final rewaya = reciter['rewaya'];
        _names.add(name);
        if (_names.contains(name)) {
          _dupicatedNames.add(name);
          _allRewaya.add(rewaya);
          hasAnotherRewaya = true;
          print('Name: $name & \nReways: $rewaya');
        }
      }
      counter = reciters.length;
    }
    // notifyListeners();
    return _dupicatedNames;
  }
}

class Reciter {
  Reciter({
    required this.id,
    required this.name,
    required this.server,
    required this.rewaya,
    required this.count,
    required this.letter,
    required this.suras,
  });
  final String id;
  final String name;
  final String server;
  final String rewaya;
  final String count;
  final String letter;
  final String suras;

  String? get getId => id;

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'],
      name: json['name'],
      server: json['Server'],
      rewaya: json['rewaya'],
      count: json['count'],
      letter: json['letter'],
      suras: json['suras'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['Server'] = server;
    data['rewaya'] = rewaya;
    data['count'] = count;
    data['letter'] = letter;
    data['suras'] = suras;
    return data;
  }
}

// class RecitersHelper {
//   RecitersHelper({required this.reciters});
//   final List<dynamic> reciters;

//   factory RecitersHelper.fromJson(Map<String, dynamic> json) {
//     return RecitersHelper(reciters: json['reciters']);
//   }
// }
