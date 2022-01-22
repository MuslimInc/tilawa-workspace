class Reciter {
  String? id;
  String? name;
  String? server;
  String? rewaya;
  String? count;
  String? letter;
  String? suras;

  Reciter.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    server = json['Server'];
    rewaya = json['rewaya'];
    count = json['count'];
    letter = json['letter'];
    suras = json['suras'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
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
