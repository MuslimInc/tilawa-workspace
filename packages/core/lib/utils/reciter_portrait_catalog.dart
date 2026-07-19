/// CDN portrait URLs for reciters, keyed by mp3quran [ReciterEntity.id].
///
/// Primary source: tvQuran author images
/// (https://tvquran.com/en/quran/recitations/reciters-list).
/// Gaps filled from Kalamalah / Quran.com / manual pinimg where needed.
/// Unmapped ids keep letter-avatar fallbacks.
abstract final class ReciterPortraitCatalog {
  static const String _tvQuran = 'https://tvquran.com/uploads/authors/images';
  static const String _kalamalahProfile =
      'https://api.kalamalah.com/api/reciter-profile';

  static const Map<int, String> byId = <int, String>{
    // Ibrahim Al-Akdar
    1: '$_tvQuran/%D8%A5%D8%A8%D8%B1%D8%A7%D9%87%D9%8A%D9%85%20%D8%A7%D9%84%D8%A3%D8%AE%D8%B6%D8%B1.jpg',
    // Ibrahim Al-Jebreen
    2: '$_tvQuran/%D8%A7%D8%A8%D8%B1%D8%A7%D9%87%D9%8A%D9%85%20%D8%A7%D9%84%D8%AC%D8%A8%D8%B1%D9%8A%D9%86.jpg',
    // Ibrahim Al-Asiri
    3: '$_tvQuran/%D8%A5%D8%A8%D8%B1%D8%A7%D9%87%D9%8A%D9%85%20%D8%A7%D9%84%D8%B9%D8%B3%D9%8A%D8%B1%D9%8A.jpg',
    // Shaik Abu Bakr Al Shatri
    4: '$_tvQuran/%D8%B4%D9%8A%D8%AE%20%D8%A3%D8%A8%D9%88%20%D8%A8%D9%83%D8%B1%20%D8%A7%D9%84%D8%B4%D8%A7%D8%B7%D8%B1%D9%8A.jpg',
    // Ahmad Al-Ajmy
    5: '$_kalamalahProfile/ahmed-al-ajamy',
    // Ahmad Al-Hawashi
    6: '$_tvQuran/%D8%A3%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D8%AD%D9%88%D8%A7%D8%B4%D9%8A.jpg',
    // Ahmad Saber
    8: '$_tvQuran/%D8%A3%D8%AD%D9%85%D8%AF%20%D8%B5%D8%A7%D8%A8%D8%B1.jpg',
    // Akram Alalaqmi
    10: '$_tvQuran/%D8%A3%D9%83%D8%B1%D9%85%20%D8%A7%D9%84%D8%B9%D9%84%D8%A7%D9%82%D9%85%D9%8A.jpg',
    // Alhusayni Al-Azazi
    11: '$_tvQuran/%D8%A7%D9%84%D8%AD%D8%B3%D9%8A%D9%86%D9%8A%20%D8%A7%D9%84%D8%B9%D8%B2%D8%A7%D8%B2%D9%8A.jpg',
    // Idrees Abkr
    12: '$_tvQuran/%D8%A5%D8%AF%D8%B1%D9%8A%D8%B3%20%D8%A3%D8%A8%D9%83%D8%B1.jpg',
    // Alzain Mohammad Ahmad
    13: '$_tvQuran/%D8%A7%D9%84%D8%B2%D9%8A%D9%86%20%D9%85%D8%AD%D9%85%D8%AF%20%D8%A3%D8%AD%D9%85%D8%AF.jpg',
    // Alashri Omran
    15: '$_tvQuran/%D8%A7%D9%84%D8%B9%D8%B4%D8%B1%D9%8A%20%D8%B9%D9%85%D8%B1%D8%A7%D9%86.jpg',
    // Aloyoon Al-Koshi
    16: '$_tvQuran/%D8%A7%D9%84%D8%B9%D9%8A%D9%88%D9%86%20%D8%A7%D9%84%D9%83%D9%88%D8%B4%D9%8A.jpg',
    // Tawfeeq As-Sayegh
    17: '$_tvQuran/%D8%AA%D9%88%D9%81%D9%8A%D9%82%20%D8%A7%D9%84%D8%B5%D8%A7%D9%8A%D8%BA.jpg',
    // Jamal Shaker Abdullah
    18: '$_tvQuran/%D8%AC%D9%85%D8%A7%D9%84%20%D8%B4%D8%A7%D9%83%D8%B1%20%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%84%D9%87.jpg',
    // Hamad Al Daghriri
    19: '$_tvQuran/%D8%AD%D9%85%D8%AF%20%D8%AF%D8%BA%D8%B1%D9%8A%D8%B1%D9%8A.jpg',
    // Khalid Al-Jileel
    20: '$_tvQuran/%D8%AE%D8%A7%D9%84%D8%AF%20%D8%A7%D9%84%D8%AC%D9%84%D9%8A%D9%84.jpg',
    // Khaled Al-Qahtani
    21: '$_tvQuran/%D8%AE%D8%A7%D9%84%D8%AF%20%D8%A7%D9%84%D9%82%D8%AD%D8%B7%D8%A7%D9%86%D9%8A.jpg',
    // Khalid Abdulkafi
    22: '$_tvQuran/%D8%AE%D8%A7%D9%84%D8%AF%20%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%83%D8%A7%D9%81%D9%8A.jpg',
    // Khalifa Altunaiji
    24: 'https://static.qurancdn.com/images/reciters/11/khalifa-al-tunaiji-profile.jpeg',
    // Dawood Hamza
    25: '$_tvQuran/%D8%AF%D8%A7%D9%88%D8%AF%20%D8%AD%D9%85%D8%B2%D8%A9.jpg',
    // Rasheed Ifrad
    26: '$_tvQuran/%D8%B1%D8%B4%D9%8A%D8%AF%20%D8%A5%D9%81%D8%B1%D8%A7%D8%AF.jpg',
    // Rachid Belalya
    27: '$_tvQuran/%D8%B1%D8%B4%D9%8A%D8%AF%20%D8%A8%D9%84%D8%B9%D8%A7%D9%84%D9%8A%D8%A9.jpg',
    // Zakaria Hamamah
    28: '$_tvQuran/%D8%B2%D9%83%D8%B1%D9%8A%D8%A7%D8%A1%20%D8%AD%D9%85%D8%A7%D9%85%D8%A9.jpg',
    // Saad Al-Ghamdi
    30: '$_tvQuran/%D8%B3%D8%B9%D8%AF%20%D8%A7%D9%84%D8%BA%D8%A7%D9%85%D8%AF%D9%8A.jpg',
    // Saud Al-Shuraim
    31: '$_tvQuran/%D8%B3%D8%B9%D9%88%D8%AF%20%D8%A7%D9%84%D8%B4%D8%B1%D9%8A%D9%85.jpg',
    // Sahl Yassin
    32: '$_tvQuran/%D8%B3%D9%87%D9%84%20%D9%8A%D8%A7%D8%B3%D9%8A%D9%86.jpg',
    // Zaki Daghistani
    33: '$_tvQuran/%D8%B2%D9%83%D9%8A%20%D8%AF%D8%A7%D8%BA%D8%B3%D8%AA%D8%A7%D9%86%D9%8A.jpg',
    // Sami Al-Hasn
    34: '$_tvQuran/%D8%B3%D8%A7%D9%85%D9%8A%20%D8%A7%D9%84%D8%AD%D8%B3%D9%86.jpg',
    // Sami Al-Dosari
    35: '$_tvQuran/%D8%B3%D8%A7%D9%85%D9%8A%20%D8%A7%D9%84%D8%AF%D9%88%D8%B3%D8%B1%D9%8A.jpg',
    // Sayeed Ramadan
    36: '$_tvQuran/%D8%B3%D9%8A%D8%AF%20%D8%B1%D9%85%D8%B6%D8%A7%D9%86.jpg',
    // Shaban Al-Sayiaad
    37: '$_tvQuran/%D8%B4%D8%B9%D8%A8%D8%A7%D9%86%20%D8%A7%D9%84%D8%B5%D9%8A%D8%A7%D8%AF.jpg',
    // Shirazad Taher
    38: '$_tvQuran/%D8%B4%D9%8A%D8%B1%D8%B2%D8%A7%D8%AF%20%D8%B7%D8%A7%D9%87%D8%B1.jpg',
    // Saleh Alsahood
    40: '$_tvQuran/%D8%B5%D8%A7%D9%84%D8%AD%20%D8%A8%D9%86%20%D8%B3%D8%A7%D9%84%D9%85%20%D8%A7%D9%84%D8%B5%D8%A7%D9%87%D9%88%D8%AF.jpg',
    // Saleh Al-Talib
    41: '$_tvQuran/%D8%B5%D8%A7%D9%84%D8%AD%20%D8%A2%D9%84%20%D8%B7%D8%A7%D9%84%D8%A8.jpg',
    // Saleh Al-Habdan
    42: '$_tvQuran/%D8%B5%D8%A7%D9%84%D8%AD%20%D8%A7%D9%84%D9%87%D8%A8%D8%AF%D8%A7%D9%86.jpg',
    // Salah Alhashim
    44: '$_tvQuran/%D8%B5%D9%84%D8%A7%D8%AD%20%D8%A7%D9%84%D9%87%D8%A7%D8%B4%D9%85.jpg',
    // Slaah Bukhatir
    46: '$_tvQuran/%D8%B5%D9%84%D8%A7%D8%AD%20%D8%A8%D9%88%20%D8%AE%D8%A7%D8%B7%D8%B1.jpg',
    // Adel Ryyan
    48: '$_tvQuran/%D8%B9%D8%A7%D8%AF%D9%84%20%D8%B1%D9%8A%D8%A7%D9%86.jpg',
    // Abdulbasit Abdulsamad
    51: '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D8%A8%D8%A7%D8%B3%D8%B7%20%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D8%B5%D9%85%D8%AF.jpg',
    // Abdulrahman Alsudaes
    54: '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%86%20%D8%A7%D9%84%D8%B3%D8%AF%D9%8A%D8%B3.jpg',
    // Abdullah Albuajan
    58: '$_tvQuran/%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D9%84%D9%87%20%D8%A7%D9%84%D8%A8%D8%B9%D9%8A%D8%AC%D8%A7%D9%86.jpg',
    // Abdullah Al-Mattrod
    59: '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%84%D9%87%20%D8%A7%D9%84%D9%85%D8%B7%D8%B1%D9%88%D8%AF.jpg',
    // Abdullah Al-Johany
    62: '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%84%D9%87%20%D8%A7%D9%84%D8%AC%D9%87%D9%86%D9%8A(1).jpg',
    // Abdulrasheed Soufi
    64: '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D8%B1%D8%B4%D9%8A%D8%AF%20%D8%A8%D9%86%20%D8%B9%D9%84%D9%8A%20%D8%B5%D9%88%D9%81%D9%8A.jpg',
    // Abdulmohsen Al-Qasim
    67: '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%85%D8%AD%D8%B3%D9%86%20%D8%A7%D9%84%D9%82%D8%A7%D8%B3%D9%85.jpg',
    // Abdulmohsin Al-Askar
    68: '$_tvQuran/%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D9%85%D8%AD%D8%B3%D9%86%20%D8%A7%D9%84%D8%B9%D8%B3%D9%83%D8%B1.jpg',
    // Abdulmohsin Al-Obaikan
    69: '$_tvQuran/%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D9%85%D8%AD%D8%B3%D9%86%20%D8%A7%D9%84%D8%B9%D8%A8%D9%8A%D9%83%D8%A7%D9%86.jpg',
    // Abdulhadi Kanakeri
    70: '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%87%D8%A7%D8%AF%D9%8A%20%D9%83%D9%86%D8%A7%D9%83%D8%B1%D9%8A.jpg',
    // Abdulwali Al-Arkani
    72: '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%88%D9%84%D9%8A%20%D8%A7%D9%84%D8%A3%D8%B1%D9%83%D8%A7%D9%86%D9%8A.jpeg',
    // Ali Abo-Hashim
    73: '$_tvQuran/%D8%B9%D9%84%D9%8A%20%D8%A3%D8%A8%D9%88%20%D9%87%D8%A7%D8%B4%D9%85.jpg',
    // Ali Alhuthaifi
    74: '$_tvQuran/%D8%A3%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D8%AD%D8%B0%D9%8A%D9%81%D9%8A.jpg',
    // Ali Jaber
    76: '$_tvQuran/%D8%B9%D9%84%D9%8A%20%D8%AC%D8%A7%D8%A8%D8%B1.jpg',
    // Ali Hajjaj Alsouasi
    77: '$_tvQuran/%D8%B9%D9%84%D9%8A%20%D8%AD%D8%AC%D8%A7%D8%AC%20%D8%A7%D9%84%D8%B3%D9%88%D9%8A%D8%B3%D9%8A.jpg',
    // Emad Hafez
    78: '$_tvQuran/%D8%B9%D9%85%D8%A7%D8%AF%20%D8%B2%D9%87%D9%8A%D8%B1%20%D8%AD%D8%A7%D9%81%D8%B8.jpg',
    // Omar Al-Qazabri
    80: '$_tvQuran/%D8%B9%D9%85%D8%B1%20%D8%A7%D9%84%D9%82%D8%B2%D8%A7%D8%A8%D8%B1%D9%8A.jpg',
    // Fares Abbad
    81: '$_tvQuran/%D9%81%D8%A7%D8%B1%D8%B3%20%D8%B9%D8%A8%D8%A7%D8%AF.jpg',
    // Fahad Al-Kandari
    83: '$_tvQuran/%D9%81%D9%87%D8%AF%20%D8%A7%D9%84%D9%83%D9%86%D8%AF%D8%B1%D9%8A.jpeg',
    // Fawaz Alkabi
    84: '$_tvQuran/%D9%81%D9%88%D8%A7%D8%B2%20%D8%A7%D9%84%D9%83%D8%B9%D8%A8%D9%8A.jpg',
    // Lafi Al-Oni
    85: '$_tvQuran/%D9%84%D8%A7%D9%81%D9%8A%20%D8%A7%D9%84%D8%B9%D9%88%D9%86%D9%8A.png',
    // Nasser Alqatami
    86: '$_tvQuran/%D9%86%D8%A7%D8%B5%D8%B1%20%D8%A7%D9%84%D9%82%D8%B7%D8%A7%D9%85%D9%8A.jpg',
    // Nabil Al Rifay
    87: '$_tvQuran/%D9%86%D8%A8%D9%8A%D9%84%20%D8%A7%D9%84%D8%B1%D9%81%D8%A7%D8%B9%D9%8A.jpg',
    // Hani Arrifai
    89: '$_tvQuran/%D9%87%D8%A7%D9%86%D9%8A%20%D8%A7%D9%84%D8%B1%D9%81%D8%A7%D8%B9%D9%8A.jpg',
    // Walid Al-Dulaimi
    90: '$_tvQuran/%D9%88%D9%84%D9%8A%D8%AF%20%D8%A7%D9%84%D8%AF%D9%84%D9%8A%D9%85%D9%8A.jpg',
    // Waleed Alnaehi
    91: '$_tvQuran/%D9%88%D9%84%D9%8A%D8%AF%20%D8%A7%D9%84%D9%86%D8%A7%D8%A6%D8%AD%D9%8A.jpg',
    // Yasser Al-Dosari
    92: '$_tvQuran/%D9%8A%D8%A7%D8%B3%D8%B1%20%D8%A7%D9%84%D8%AF%D9%88%D8%B3%D8%B1%D9%8A.jpg',
    // Yasser Al-Qurashi
    93: '$_tvQuran/%D9%8A%D8%A7%D8%B3%D8%B1%20%D8%A7%D9%84%D9%82%D8%B1%D8%B4%D9%8A.jpg',
    // Yasser Al-Faylakawi
    94: '$_tvQuran/%D9%8A%D8%A7%D8%B3%D8%B1%20%D8%A7%D9%84%D9%81%D9%8A%D9%84%D9%83%D8%A7%D9%88%D9%8A.jpg',
    // Yasser Al-Mazroyee
    95: '$_tvQuran/%D9%8A%D8%A7%D8%B3%D8%B1%20%D8%A7%D9%84%D9%85%D8%B2%D8%B1%D9%88%D8%B9%D9%8A.jpg',
    // Yahya Hawwa
    96: '$_tvQuran/%D9%8A%D8%AD%D9%8A%D9%89%20%D8%AD%D9%88%D8%A7.jpg',
    // Yousef Alshoaey
    97: '$_tvQuran/%D9%8A%D9%88%D8%B3%D9%81%20%D8%A7%D9%84%D8%B4%D9%88%D9%8A%D8%B9%D9%8A.jpg',
    // Maher Al Meaqli
    102:
        '$_tvQuran/%D9%85%D8%A7%D9%87%D8%B1%20%D8%A7%D9%84%D9%85%D8%B9%D9%8A%D9%82%D9%84%D9%8A.jpg',
    // Mohammed Al-Barrak
    105:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D8%A8%D8%B1%D8%A7%D9%83.jpg',
    // Mohammed Al-Lohaidan
    107:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D9%84%D8%AD%D9%8A%D8%AF%D8%A7%D9%86.jpg',
    // Mohammed Al-Muhasny
    108:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D9%85%D8%AD%D9%8A%D8%B3%D9%86%D9%8A.jpg',
    // Mohammed Ayyub
    109: '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%A3%D9%8A%D9%88%D8%A8.jpg',
    // Mohammad Saleh Alim Shah
    110:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%B5%D8%A7%D9%84%D8%AD%20%D8%B4%D8%A7%D9%87.jpg',
    // Mohammed Jibreel
    111:
        'https://i.pinimg.com/564x/fa/8f/f8/fa8ff84527ff6c1611e304f94b1bf96d.jpg',
    // Mohammed Siddiq Al-Minshawi
    112:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%B5%D8%AF%D9%8A%D9%82%20%D8%A7%D9%84%D9%85%D9%86%D8%B4%D8%A7%D9%88%D9%8A%202.jpg',
    // Mohammad Abdullkarem
    115:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%83%D8%B1%D9%8A%D9%85.jpg',
    // Mahmoud Khalil Al-Hussary
    118:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D9%88%D8%AF%20%D8%AE%D9%84%D9%8A%D9%84%20%D8%A7%D9%84%D8%AD%D8%B5%D8%B1%D9%8A.jpg',
    // Mahmoud Ali  Albanna
    121:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D9%88%D8%AF%20%D8%B9%D9%84%D9%8A%20%D8%A7%D9%84%D8%A8%D9%86%D8%A7.jpg',
    // Mishary Alafasi
    123:
        '$_tvQuran/%D9%85%D8%B4%D8%A7%D8%B1%D9%8A%20%D8%A7%D9%84%D8%B9%D9%81%D8%A7%D8%B3%D9%8A.jpg',
    // Mustafa Ismail
    125:
        '$_tvQuran/%D9%85%D8%B5%D8%B7%D9%81%D9%89%20%D8%A5%D8%B3%D9%85%D8%A7%D8%B9%D9%8A%D9%84.jpg',
    // Mustafa Al-Lahoni
    126:
        '$_tvQuran/%D9%85%D8%B5%D8%B7%D9%81%D9%89%20%D8%A7%D9%84%D9%84%D8%A7%D9%87%D9%88%D9%86%D9%8A.png',
    // Mustafa raad Alazawy
    127:
        '$_tvQuran/%D9%85%D8%B5%D8%B7%D9%81%D9%89%20%D8%A8%D9%86%20%D8%B1%D8%B9%D8%AF%20%D8%A7%D9%84%D8%B9%D8%B2%D8%A7%D9%88%D9%8A.jpg',
    // Muftah Alsaltany
    129:
        '$_tvQuran/%D9%85%D9%81%D8%AA%D8%A7%D8%AD%20%D8%A7%D9%84%D8%B3%D9%84%D8%B7%D9%86%D9%8A.jpg',
    // Majed Al-Zamil
    139:
        '$_tvQuran/%D9%85%D8%A7%D8%AC%D8%AF%20%D8%A7%D9%84%D8%B2%D8%A7%D9%85%D9%84.jpg',
    // Maher Shakhashero
    149:
        '$_tvQuran/%D9%85%D8%A7%D9%87%D8%B1%20%D8%B4%D8%AE%D8%A7%D8%B4%D9%8A%D8%B1%D9%88.jpg',
    // Mohammad AlMonshed
    150:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D9%85%D9%86%D8%B4%D8%AF.jpg',
    // Mahmood AlSheimy
    151:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D9%88%D8%AF%20%D8%A7%D9%84%D8%B4%D9%8A%D9%85%D9%8A.jpg',
    // Yasser Salamah
    152:
        '$_tvQuran/%D9%8A%D8%A7%D8%B3%D8%B1%20%D8%B3%D9%84%D8%A7%D9%85%D8%A9.jpg',
    // Ustaz Zamri
    154:
        '$_tvQuran/%D8%A3%D8%B3%D8%AA%D8%A7%D8%B0%20%D8%B2%D8%A7%D9%85%D8%B1%D9%8A.jpg',
    // Khalid Almohana
    159:
        '$_tvQuran/%D8%AE%D8%A7%D9%84%D8%AF%20%D8%A7%D9%84%D9%85%D9%87%D9%86%D8%A7.jpg',
    // Adel Al-Khalbany
    160:
        '$_tvQuran/%D8%B9%D8%A7%D8%AF%D9%84%20%D8%A7%D9%84%D9%83%D9%84%D8%A8%D8%A7%D9%86%D9%8A.jpg',
    // Mousa Bilal
    161: '$_tvQuran/%D9%85%D9%88%D8%B3%D9%89%20%D8%A8%D9%84%D8%A7%D9%84.jpg',
    // Hussain Alshaik
    162:
        '$_tvQuran/%D8%AD%D8%B3%D9%8A%D9%86%20%D8%A2%D9%84%20%D8%A7%D9%84%D8%B4%D9%8A%D8%AE.jpg',
    // Hatem Fareed Alwaer
    163:
        '$_tvQuran/%D8%AD%D8%A7%D8%AA%D9%85%20%D9%81%D8%B1%D9%8A%D8%AF%20%D8%A7%D9%84%D9%88%D8%A7%D8%B9%D8%B1.jpg',
    // Ibrahim Aljormy
    164:
        '$_tvQuran/%D8%A5%D8%A8%D8%B1%D8%A7%D9%87%D9%8A%D9%85%20%D8%A7%D9%84%D8%AC%D8%B1%D9%85%D9%8A.jpg',
    // Mahmood Al rifai
    165:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D9%88%D8%AF%20%D8%A7%D9%84%D8%B1%D9%81%D8%A7%D8%B9%D9%8A.jpg',
    // Nasser Al obaid
    166:
        '$_tvQuran/%D9%86%D8%A7%D8%B5%D8%B1%20%D8%A7%D9%84%D8%B9%D8%A8%D9%8A%D8%AF.jpg',
    // Wasel Almethen
    167:
        '$_tvQuran/%D9%88%D8%A7%D8%B5%D9%84%20%D8%A7%D9%84%D9%85%D8%B0%D9%86.jpg',
    // Ibrahim Aldosari
    178:
        '$_tvQuran/%D8%A5%D8%A8%D8%B1%D8%A7%D9%87%D9%8A%D9%85%20%D8%A7%D9%84%D8%AF%D9%88%D8%B3%D8%B1%D9%8A.jpg',
    // Jamaan Alosaimi
    181:
        '$_tvQuran/%D8%AC%D9%85%D8%B9%D8%A7%D9%86%20%D8%A7%D9%84%D8%B9%D8%B5%D9%8A%D9%85%D9%8A.jpg',
    // Abdullah Fahmi
    189:
        '$_tvQuran/%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D9%84%D9%87%20%D9%81%D9%87%D9%85%D9%8A.jpg',
    // Muhammed Khairul Anuar
    192:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%AE%D9%8A%D8%B1%20%D8%A7%D9%84%D9%86%D9%88%D8%B1.jpg',
    // Jamal Addeen Alzailaie
    194:
        '$_tvQuran/%D8%AC%D9%85%D8%A7%D9%84%20%D8%A7%D9%84%D8%AF%D9%8A%D9%86%20%D8%A7%D9%84%D8%B2%D9%8A%D9%84%D8%B9%D9%8A.jpg',
    // Mohammad Rashad Alshareef
    198:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%B1%D8%B4%D8%A7%D8%AF%20%D8%A7%D9%84%D8%B4%D8%B1%D9%8A%D9%81.jpg',
    // Ahmed Al-trabulsi
    201:
        '$_tvQuran/%D8%A3%D8%AD%D9%85%D8%AF%20%D8%AE%D8%B6%D8%B1%20%D8%A7%D9%84%D8%B7%D8%B1%D8%A7%D8%A8%D9%84%D8%B3%D9%8A.jpg',
    // Abdullah Al-Kandari
    202:
        '$_tvQuran/%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D9%84%D9%87%20%D8%A7%D9%84%D9%83%D9%86%D8%AF%D8%B1%D9%8A.jpg',
    // Ahmed Amer
    203: '$_tvQuran/%D8%A3%D8%AD%D9%85%D8%AF%20%D8%B9%D8%A7%D9%85%D8%B1.jpg',
    // Ahmad Alhuthaifi
    205:
        '$_tvQuran/%D8%A3%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D8%AD%D8%B0%D9%8A%D9%81%D9%8A.jpg',
    // Mohammed Osman Khan
    206:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%B9%D8%AB%D9%85%D8%A7%D9%86%20%D8%AE%D8%A7%D9%86.jpg',
    // Youssef Edghouch
    207:
        '$_tvQuran/%D9%8A%D9%88%D8%B3%D9%81%20%D8%A7%D9%84%D8%AF%D8%BA%D9%88%D8%B4.jpg',
    // Addokali Mohammad Alalim
    208:
        '$_tvQuran/%D8%A7%D9%84%D8%AF%D9%88%D9%83%D8%A7%D9%84%D9%8A%20%D9%85%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D8%B9%D8%A7%D9%84%D9%85.jpg',
    // Wishear Hayder Arbili
    209:
        '$_tvQuran/%D9%88%D8%B4%DB%8C%D8%A7%D8%B1%20%D8%AD%DB%8C%D8%AF%D8%B1%20%D8%A7%D8%B1%D8%A8%DB%8C%D9%84%DB%8C.jpg',
    // Alfateh Alzubair
    211:
        '$_tvQuran/%D8%A7%D9%84%D9%81%D8%A7%D8%AA%D8%AD%20%D9%85%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D8%B2%D8%A8%D9%8A%D8%B1.jpg',
    // Bandar Balilah
    217:
        '$_tvQuran/%D8%A8%D9%86%D8%AF%D8%B1%20%D8%A8%D9%84%D9%8A%D9%84%D9%87.jpg',
    // Raad Al Kurdi
    221:
        '$_tvQuran/%D8%B1%D8%B9%D8%AF%20%D8%A7%D9%84%D9%83%D8%B1%D8%AF%D9%8A.jpg',
    // Abdulrahman Aloosi
    225:
        '$_tvQuran/%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%86%20%D8%A7%D9%84%D8%B9%D9%88%D8%B3%D9%8A.jpg',
    // Khalid Algamdi
    226:
        '$_tvQuran/%D8%AE%D8%A7%D9%84%D8%AF%20%D8%A7%D9%84%D8%BA%D8%A7%D9%85%D8%AF%D9%8A.jpg',
    // Ramadan Shakoor
    227:
        '$_tvQuran/%D8%B1%D9%85%D8%B6%D8%A7%D9%86%20%D8%B4%D9%83%D9%88%D8%B1.jpg',
    // Abdulmajeed Al-Arkani
    228:
        '$_tvQuran/%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D9%85%D8%AC%D9%8A%D8%AF%20%D8%A7%D9%84%D8%A3%D8%B1%D9%83%D8%A7%D9%86%D9%8A.jpg',
    // Mohammad Khalil Al-Qari
    229:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%AE%D9%84%D9%8A%D9%84%20%D8%A7%D9%84%D9%82%D8%A7%D8%B1%D8%A6.jpg',
    // Hazza Al-Balushi
    231:
        '$_tvQuran/%D9%87%D8%B2%D8%A7%D8%B9%20%D8%A7%D9%84%D8%A8%D9%84%D9%88%D8%B4%D9%8A.jpg',
    // Abdulrahman Al-Majed
    236:
        '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%86%20%D8%A7%D9%84%D9%85%D8%A7%D8%AC%D8%AF.jpg',
    // Salman Alotaibi
    240:
        '$_tvQuran/%D8%B3%D9%84%D9%85%D8%A7%D9%86%20%D8%A7%D9%84%D8%B9%D8%AA%D9%8A%D8%A8%D9%8A.jpg',
    // Mohammad Refat
    241: '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%B1%D9%81%D8%B9%D8%AA.jpg',
    // Abdullah Al-Khalaf
    244:
        '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%84%D9%87%20%D8%AE%D9%84%D9%81.jpg',
    // Mansour Al-Salemi
    245:
        '$_tvQuran/%D9%85%D9%86%D8%B5%D9%88%D8%B1%20%D8%A7%D9%84%D8%B3%D8%A7%D9%84%D9%85%D9%8A.jpg',
    // Islam Sobhi
    253:
        '$_tvQuran/%D8%A7%D8%B3%D9%84%D8%A7%D9%85%20%D8%B5%D8%A8%D8%AD%D9%8A.jpg',
    // Bader Alturki
    254:
        '$_tvQuran/%D8%A8%D8%AF%D8%B1%20%D8%A7%D9%84%D8%AA%D8%B1%D9%83%D9%8A.jpeg',
    // Ahmad Al Nufais
    259:
        '$_tvQuran/%D8%A3%D8%AD%D9%85%D8%AF%20%D8%A7%D9%84%D9%86%D9%81%D9%8A%D8%B3.jpg',
    // Younes Souilass
    264:
        '$_tvQuran/%D9%8A%D9%88%D9%86%D8%B3%20%D8%A7%D8%B3%D9%88%D9%8A%D9%84%D8%B5.jpg',
    // Abdullah Kamel
    267:
        '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%84%D9%87%20%D9%83%D8%A7%D9%85%D9%84.jpg',
    // Peshawa Qadr Al-Kurdi
    268:
        '$_tvQuran/%D8%A8%D9%8A%D8%B4%D9%87%20%D9%88%D8%A7%20%D9%82%D8%A7%D8%AF%D8%B1%20%D8%A7%D9%84%D9%83%D8%B1%D8%AF%D9%8A.jpg',
    // Okasha Kameny
    272:
        '$_tvQuran/%D8%B9%D9%83%D8%A7%D8%B4%D8%A9%20%D9%83%D9%85%D9%8A%D9%86%D9%8A.jpg',
    // Haitham Aldukhain
    273: '$_kalamalahProfile/haitham-al-dukhin',
    // Muhammad Abu Sneina
    274:
        '$_tvQuran/%D9%85%D8%AD%D9%85%D8%AF%20%D8%A3%D8%A8%D9%88%20%D8%B3%D9%86%D9%8A%D9%86%D8%A9.jpg',
    // Fouad Alkhamery
    281:
        '$_tvQuran/%D9%81%D8%A4%D8%A7%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D9%85%D8%B1%D9%8A.jpg',
    // Hasan Saleh
    286:
        '$_tvQuran/%D8%AD%D8%B3%D9%86%20%D9%85%D8%AD%D9%85%D8%AF%20%D8%B5%D8%A7%D9%84%D8%AD.jpg',
    // Hicham Lharraz
    305:
        '$_tvQuran/%D9%87%D8%B4%D8%A7%D9%85%20%D8%A7%D9%84%D9%87%D8%B1%D8%A7%D8%B2.jpg',
    // Abdelmoujib Benkirane
    21199:
        '$_tvQuran/%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D9%85%D8%AC%D9%8A%D8%A8%20%D8%A8%D9%86%D9%83%D9%8A%D8%B1%D8%A7%D9%86.jpg',
  };

  static String? photoUrlFor(int reciterId) => byId[reciterId];

  static String? photoUrlForIdString(String? reciterId) {
    if (reciterId == null) {
      return null;
    }
    final int? id = int.tryParse(reciterId.trim());
    if (id == null) {
      return null;
    }
    return photoUrlFor(id);
  }
}
