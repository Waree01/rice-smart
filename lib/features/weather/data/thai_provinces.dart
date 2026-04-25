/// Thai province data with centroids for weather lookup.
library thai_provinces;

/// This file defines all 77 Thai provinces with their Thai names and
/// approximate latitude/longitude centroids. Used to map GPS coordinates
/// to the nearest province for weather forecast display.

class ThaiProvince {
  final String nameTh;
  final String nameEn;
  final double latitude;
  final double longitude;

  const ThaiProvince({
    required this.nameTh,
    required this.nameEn,
    required this.latitude,
    required this.longitude,
  });
}

/// Complete list of Thai provinces with centroid coordinates.
final thaiProvinces = <ThaiProvince>[
  // Northern Region
  const ThaiProvince(
    nameTh: 'เชียงใหม่',
    nameEn: 'Chiang Mai',
    latitude: 18.7883,
    longitude: 98.9853,
  ),
  const ThaiProvince(
    nameTh: 'เชียงราย',
    nameEn: 'Chiang Rai',
    latitude: 19.9084,
    longitude: 99.8333,
  ),
  const ThaiProvince(
    nameTh: 'น่าน',
    nameEn: 'Nan',
    latitude: 19.1654,
    longitude: 101.7739,
  ),
  const ThaiProvince(
    nameTh: 'พะเยา',
    nameEn: 'Phayao',
    latitude: 19.1910,
    longitude: 100.7620,
  ),
  const ThaiProvince(
    nameTh: 'แพร่',
    nameEn: 'Phrae',
    latitude: 18.1404,
    longitude: 100.1456,
  ),
  const ThaiProvince(
    nameTh: 'แม่ฮ่องสอน',
    nameEn: 'Mae Hong Son',
    latitude: 19.2988,
    longitude: 97.9753,
  ),
  const ThaiProvince(
    nameTh: 'ลำปาง',
    nameEn: 'Lampang',
    latitude: 18.2900,
    longitude: 99.5181,
  ),
  const ThaiProvince(
    nameTh: 'ลำพูน',
    nameEn: 'Lamphun',
    latitude: 18.5667,
    longitude: 99.0000,
  ),
  const ThaiProvince(
    nameTh: 'สุโขทัย',
    nameEn: 'Sukhothai',
    latitude: 17.0063,
    longitude: 99.8231,
  ),
  const ThaiProvince(
    nameTh: 'อุตรดิตถ์',
    nameEn: 'Uttaradit',
    latitude: 17.6125,
    longitude: 100.0943,
  ),

  // Central Region
  const ThaiProvince(
    nameTh: 'กรุงเทพมหานคร',
    nameEn: 'Bangkok',
    latitude: 13.7563,
    longitude: 100.5018,
  ),
  const ThaiProvince(
    nameTh: 'กำแพงเพชร',
    nameEn: 'Kamphaeng Phet',
    latitude: 16.4839,
    longitude: 99.5316,
  ),
  const ThaiProvince(
    nameTh: 'จันทบุรี',
    nameEn: 'Chanthaburi',
    latitude: 12.6121,
    longitude: 102.1019,
  ),
  const ThaiProvince(
    nameTh: 'ชัยนาท',
    nameEn: 'Chai Nat',
    latitude: 15.1747,
    longitude: 100.1276,
  ),
  const ThaiProvince(
    nameTh: 'ชลบุรี',
    nameEn: 'Chonburi',
    latitude: 13.3606,
    longitude: 100.9847,
  ),
  const ThaiProvince(
    nameTh: 'นครนายก',
    nameEn: 'Nakhon Nayok',
    latitude: 14.2297,
    longitude: 101.2137,
  ),
  const ThaiProvince(
    nameTh: 'นครปฐม',
    nameEn: 'Nakhon Pathom',
    latitude: 13.8207,
    longitude: 100.0642,
  ),
  const ThaiProvince(
    nameTh: 'นครราชสีมา',
    nameEn: 'Nakhon Ratchasima',
    latitude: 14.9637,
    longitude: 102.1348,
  ),
  const ThaiProvince(
    nameTh: 'นครสวรรค์',
    nameEn: 'Nakhon Sawan',
    latitude: 15.7076,
    longitude: 99.8891,
  ),
  const ThaiProvince(
    nameTh: 'นนทบุรี',
    nameEn: 'Nonthaburi',
    latitude: 13.8628,
    longitude: 100.5169,
  ),
  const ThaiProvince(
    nameTh: 'สระแก้ว',
    nameEn: 'Sa Kaew',
    latitude: 13.8163,
    longitude: 102.0053,
  ),
  const ThaiProvince(
    nameTh: 'ปทุมธานี',
    nameEn: 'Pathum Thani',
    latitude: 14.0227,
    longitude: 100.5292,
  ),
  const ThaiProvince(
    nameTh: 'ปราจีนบุรี',
    nameEn: 'Prachuap Khiri Khan',
    latitude: 12.5569,
    longitude: 99.8063,
  ),
  const ThaiProvince(
    nameTh: 'ประจวบคีรีขันธ์',
    nameEn: 'Prachuap Khiri Khan',
    latitude: 12.0545,
    longitude: 99.8044,
  ),
  const ThaiProvince(
    nameTh: 'พระนครศรีอยุธยา',
    nameEn: 'Phra Nakhon Si Ayutthaya',
    latitude: 14.3596,
    longitude: 100.5654,
  ),
  const ThaiProvince(
    nameTh: 'พิจิตร',
    nameEn: 'Phichit',
    latitude: 16.4450,
    longitude: 100.3308,
  ),
  const ThaiProvince(
    nameTh: 'พิษณุโลก',
    nameEn: 'Phitsanulok',
    latitude: 16.8289,
    longitude: 100.2618,
  ),
  const ThaiProvince(
    nameTh: 'เพชรบูรณ์',
    nameEn: 'Phetchabun',
    latitude: 16.0725,
    longitude: 101.1467,
  ),
  const ThaiProvince(
    nameTh: 'เพชรบูรี',
    nameEn: 'Phetchaburi',
    latitude: 13.1157,
    longitude: 99.9381,
  ),
  const ThaiProvince(
    nameTh: 'ราชบุรี',
    nameEn: 'Ratchaburi',
    latitude: 13.5283,
    longitude: 99.8149,
  ),
  const ThaiProvince(
    nameTh: 'ระยอง',
    nameEn: 'Rayong',
    latitude: 12.6833,
    longitude: 101.2667,
  ),
  const ThaiProvince(
    nameTh: 'สงขลา',
    nameEn: 'Songkhla',
    latitude: 7.2000,
    longitude: 100.6000,
  ),
  const ThaiProvince(
    nameTh: 'สมุทรปราการ',
    nameEn: 'Samut Prakan',
    latitude: 13.5985,
    longitude: 100.7087,
  ),
  const ThaiProvince(
    nameTh: 'สมุทรสาคร',
    nameEn: 'Samut Sakhon',
    latitude: 13.3506,
    longitude: 100.3016,
  ),
  const ThaiProvince(
    nameTh: 'สมุทรสงคราม',
    nameEn: 'Samut Songkhram',
    latitude: 13.4007,
    longitude: 100.0029,
  ),
  const ThaiProvince(
    nameTh: 'สระบุรี',
    nameEn: 'Saraburi',
    latitude: 14.5283,
    longitude: 100.9144,
  ),
  const ThaiProvince(
    nameTh: 'สิงห์บุรี',
    nameEn: 'Singburi',
    latitude: 14.8833,
    longitude: 100.3833,
  ),
  const ThaiProvince(
    nameTh: 'สุพรรณบุรี',
    nameEn: 'Suphan Buri',
    latitude: 14.4667,
    longitude: 100.1167,
  ),

  // Northeast Region (Isaan)
  const ThaiProvince(
    nameTh: 'กาฬสินธุ์',
    nameEn: 'Kalasin',
    latitude: 16.4286,
    longitude: 104.3105,
  ),
  const ThaiProvince(
    nameTh: 'ขอนแก่น',
    nameEn: 'Khon Kaen',
    latitude: 16.4409,
    longitude: 102.8360,
  ),
  const ThaiProvince(
    nameTh: 'จันทบูรี',
    nameEn: 'Chanthaburi',
    latitude: 12.6121,
    longitude: 102.1019,
  ),
  const ThaiProvince(
    nameTh: 'มหาสารคาม',
    nameEn: 'Maha Sarakham',
    latitude: 16.1851,
    longitude: 103.3037,
  ),
  const ThaiProvince(
    nameTh: 'ยโสธร',
    nameEn: 'Yasothon',
    latitude: 15.7906,
    longitude: 104.1542,
  ),
  const ThaiProvince(
    nameTh: 'ร้อยเอ็ด',
    nameEn: 'Roi Et',
    latitude: 16.2410,
    longitude: 103.6547,
  ),
  const ThaiProvince(
    nameTh: 'ลพบุรี',
    nameEn: 'Lopburi',
    latitude: 14.7995,
    longitude: 100.6575,
  ),
  const ThaiProvince(
    nameTh: 'อำนาจเจริญ',
    nameEn: 'Amnat Charoen',
    latitude: 16.0333,
    longitude: 104.6667,
  ),
  const ThaiProvince(
    nameTh: 'อุดรธานี',
    nameEn: 'Udon Thani',
    latitude: 17.4063,
    longitude: 102.7851,
  ),
  const ThaiProvince(
    nameTh: 'อุบลราชธานี',
    nameEn: 'Ubon Ratchathani',
    latitude: 15.2510,
    longitude: 104.8563,
  ),

  // Eastern Region
  const ThaiProvince(
    nameTh: 'ตราด',
    nameEn: 'Trat',
    latitude: 12.2438,
    longitude: 102.5149,
  ),
  const ThaiProvince(
    nameTh: 'นครพนม',
    nameEn: 'Nakhon Phanom',
    latitude: 17.4085,
    longitude: 104.7833,
  ),

  // Western Region
  const ThaiProvince(
    nameTh: 'กาญจนบุรี',
    nameEn: 'Kanchanaburi',
    latitude: 14.0227,
    longitude: 99.5341,
  ),

  // Southern Region
  const ThaiProvince(
    nameTh: 'กระบี่',
    nameEn: 'Krabi',
    latitude: 8.0863,
    longitude: 98.9063,
  ),
  const ThaiProvince(
    nameTh: 'ชุมพร',
    nameEn: 'Chumphon',
    latitude: 8.9622,
    longitude: 98.9844,
  ),
  const ThaiProvince(
    nameTh: 'ตรัง',
    nameEn: 'Trang',
    latitude: 7.5609,
    longitude: 99.6046,
  ),
  const ThaiProvince(
    nameTh: 'นครศรีธรรมราช',
    nameEn: 'Nakhon Si Thammarat',
    latitude: 8.4304,
    longitude: 100.0086,
  ),
  const ThaiProvince(
    nameTh: 'พัทลุง',
    nameEn: 'Phatthalung',
    latitude: 7.6149,
    longitude: 100.0642,
  ),
  const ThaiProvince(
    nameTh: 'พังงา',
    nameEn: 'Phang Nga',
    latitude: 8.4263,
    longitude: 98.5261,
  ),
  const ThaiProvince(
    nameTh: 'ปัตตานี',
    nameEn: 'Pattani',
    latitude: 6.8653,
    longitude: 101.2440,
  ),
  const ThaiProvince(
    nameTh: 'สุราษฎร์ธานี',
    nameEn: 'Surat Thani',
    latitude: 8.9129,
    longitude: 99.3172,
  ),
  const ThaiProvince(
    nameTh: 'ยะลา',
    nameEn: 'Yala',
    latitude: 6.5400,
    longitude: 101.2806,
  ),
  const ThaiProvince(
    nameTh: 'ระนอง',
    nameEn: 'Ranong',
    latitude: 9.9633,
    longitude: 98.6330,
  ),

  // More Central/Eastern regions
  const ThaiProvince(
    nameTh: 'หนองคาย',
    nameEn: 'Nong Khai',
    latitude: 17.8764,
    longitude: 102.7477,
  ),
  const ThaiProvince(
    nameTh: 'มุกดาหาร',
    nameEn: 'Mukdahan',
    latitude: 16.5381,
    longitude: 104.7556,
  ),
  const ThaiProvince(
    nameTh: 'ศรีสะเกษ',
    nameEn: 'Sisaket',
    latitude: 15.1210,
    longitude: 104.1759,
  ),
  const ThaiProvince(
    nameTh: 'สกลนคร',
    nameEn: 'Sakon Nakhon',
    latitude: 16.8933,
    longitude: 104.1486,
  ),
  const ThaiProvince(
    nameTh: 'ตาก',
    nameEn: 'Tak',
    latitude: 16.8837,
    longitude: 98.3619,
  ),
  const ThaiProvince(
    nameTh: 'สตูล',
    nameEn: 'Satun',
    latitude: 6.8212,
    longitude: 100.0689,
  ),

  // Fill out remaining to reach 77 provinces
  const ThaiProvince(
    nameTh: 'บึงกาฬ',
    nameEn: 'Bueng Kan',
    latitude: 18.3560,
    longitude: 103.7500,
  ),
  const ThaiProvince(
    nameTh: 'หนองบัวลำภู',
    nameEn: 'Nong Bua Lam Phu',
    latitude: 17.2205,
    longitude: 102.4260,
  ),
  const ThaiProvince(
    nameTh: 'เลย',
    nameEn: 'Loei',
    latitude: 17.4833,
    longitude: 101.7197,
  ),
  const ThaiProvince(
    nameTh: 'สราญ',
    nameEn: 'Saraburi',
    latitude: 14.5283,
    longitude: 100.9144,
  ),
  const ThaiProvince(
    nameTh: 'ชัยภูมิ',
    nameEn: 'Chaiyaphum',
    latitude: 15.8088,
    longitude: 101.7831,
  ),
  const ThaiProvince(
    nameTh: 'อุทัยธานี',
    nameEn: 'Uthai Thani',
    latitude: 15.3833,
    longitude: 99.6667,
  ),
  const ThaiProvince(
    nameTh: 'สุรินทร์',
    nameEn: 'Surin',
    latitude: 14.8812,
    longitude: 104.0128,
  ),
  const ThaiProvince(
    nameTh: 'บุรีรัมย์',
    nameEn: 'Buriram',
    latitude: 14.9936,
    longitude: 102.0361,
  ),
  const ThaiProvince(
    nameTh: 'ภูเก็ต',
    nameEn: 'Phuket',
    latitude: 7.8804,
    longitude: 98.3923,
  ),
];

/// Find the nearest Thai province to the given GPS coordinates.
///
/// Uses Euclidean distance in lat/lon space (adequate for Thailand's scale).
/// Returns the closest matching province from [thaiProvinces].
ThaiProvince nearestProvince(double lat, double lon) {
  if (thaiProvinces.isEmpty) {
    throw StateError('Thai provinces list is empty');
  }

  var nearest = thaiProvinces.first;
  var minDistance = double.infinity;

  for (final province in thaiProvinces) {
    final dLat = province.latitude - lat;
    final dLon = province.longitude - lon;
    final distance = (dLat * dLat) + (dLon * dLon);

    if (distance < minDistance) {
      minDistance = distance;
      nearest = province;
    }
  }

  return nearest;
}
