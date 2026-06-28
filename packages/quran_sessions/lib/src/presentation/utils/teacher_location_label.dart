import '../../domain/entities/quran_teacher.dart';

/// Public location line for teacher discovery — null when unknown.
String? teacherLocationLabel(QuranTeacher teacher) {
  final city = teacher.cityName?.trim();
  final country = teacher.countryName?.trim();
  final hasCity = city != null && city.isNotEmpty;
  final hasCountry = country != null && country.isNotEmpty;
  if (hasCity && hasCountry) return '$city, $country';
  if (hasCity) return city;
  if (hasCountry) return country;
  return null;
}
