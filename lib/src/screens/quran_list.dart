import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/sorah_model.dart';
import '../model/test_rectiters.dart';
import '../shared/custom_page_route.dart';
import '../widgets/custom_player.dart';
import 'play_online.dart';

class QuranList extends StatefulWidget {
  const QuranList({
    required this.title,
    required this.server,
    required this.listSuras,
    required this.reciterName,
  });
  final String title;
  final String server;
  final List<String> listSuras;
  final String reciterName;

  @override
  State<QuranList> createState() => _QuranListState();
}

class _QuranListState extends State<QuranList> {
  late List<SorahModel> listSorah;
  final baseUrl = Uri.parse('http://mp3quran.net/api/_arabic.json');

  Future<Reciter> getListOfSorah({required String id}) async {
    var response = await http.get(baseUrl);
    late Reciter reciterss;
    if (response.statusCode == 200) {
      final recitersData = await jsonDecode(response.body);
      List<dynamic> recievedData = recitersData['reciters'];
      // for (var reciter in recievedData) {
      //   final baseUrl = Uri.parse(reciter['Server']);

      //   var response = await http.get(baseUrl);
      //   final datas = await jsonDecode(response.body);
      //   print('reciterdatas: ${datas} endreciter;');
      // }
      // Get only one reciter info by id
      for (var reciter in recievedData) {
        reciterss = Reciter.fromJson(reciter);
        if (reciterss.id == id) {
          print(
            'Reciter info: ${reciterss.name}, reciterss.server: ${reciterss.server} end',
          );
        }
      }
      // List<Reciter> allReciters = recievedData.map((data) {
      //   return Reciter.fromJson(data);
      // }).toList();

      // Will return a list of reciters...
      return reciterss;
    } else {
      throw Exception('حدث خطأ، حاول مرة آخرى');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            // widget.title.toString(),
            'widget.title.toString()',
            style: TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          itemCount: widget.listSuras.length,
          itemBuilder: (context, index) {
            final String singleSurahUrl =
                "${widget.server}/${widget.listSuras[index].padLeft(3, '0')}.mp3";
            // print("Mr: ${widget.server}/00${widget.listSuras[index]}.mp3");

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 5.5,
              ),
              child: CustomPlayerButton(
                onTap: () => Navigator.push(
                  context,
                  CustomPageRoute(
                    child: PlayOnline(
                      surahTitle: 'surahTitle',
                      rewaya: 'reeewww',
                      singleSurahUrl: singleSurahUrl,
                      reciterName: widget.reciterName,
                    ),
                  ),
                ),
                urlAudio: singleSurahUrl,
                index: index + 1,
                title: widget.listSuras[index],
                color: const Color(0xFF00DBFF),
              ),
            );

            // return HomePages();
          },
        ),
      ),
    );
  }
}
