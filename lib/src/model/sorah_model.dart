class SorahModel {
  SorahModel({
    required this.index,
    required this.sorahName,
    required this.isPlaying,
    required this.isPause,
  });

  final int index;
  final String sorahName;
  final bool isPlaying;
  final bool isPause;

  factory SorahModel.fromJson(Map<String, dynamic> json) {
    return SorahModel(
      index: json['index'],
      sorahName: json['sorahName'],
      isPlaying: json['isPlaying'],
      isPause: json['isPause'],
    );
  }
}
