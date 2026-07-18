/// DTO for MP3Quran `/radios` API response items.
class RadioStationDto {
  const RadioStationDto({
    required this.id,
    required this.name,
    required this.url,
    this.recentDate,
  });

  factory RadioStationDto.fromJson(Map<String, dynamic> json) {
    return RadioStationDto(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      recentDate: json['recent_date'] as String?,
    );
  }

  final int id;
  final String name;
  final String url;
  final String? recentDate;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'url': url,
    if (recentDate != null) 'recent_date': recentDate,
  };
}
