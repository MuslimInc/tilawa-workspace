import 'dart:convert';

import 'package:http/http.dart' as http;

class QuranServices {
  Future<Map<String, dynamic>> get allReciters => getAllReciters();
  Future<Map<String, dynamic>> getAllReciters() async {
    var baseUrl = Uri.parse('http://mp3quran.net/api/_arabic.json');
    var response = await http.get(baseUrl);

    Map<String, dynamic> reciters = jsonDecode(response.body);
    // print('I am reciters; $reciters');
    return reciters;
  }
}
