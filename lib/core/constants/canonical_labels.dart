/// Canonical disease/pest classes used across the admin labeling loop
/// and the community/outbreak clustering. Keeping these in one place
/// means the on-device classifier, the active-learning labeller, and the
/// outbreak detector all agree on the same `id` for a given condition.
class CanonicalLabel {
  final String id;
  final String nameTh;
  final String nameEn;
  const CanonicalLabel(this.id, this.nameTh, this.nameEn);
}

class CanonicalLabels {
  CanonicalLabels._();

  /// Rice-leaf disease classes (matches the disease classifier head).
  static const List<CanonicalLabel> diseases = [
    CanonicalLabel('rice_blast', 'โรคไหม้ข้าว', 'Rice Blast'),
    CanonicalLabel('brown_spot', 'ใบจุดสีน้ำตาล', 'Brown Spot'),
    CanonicalLabel(
      'bacterial_leaf_blight',
      'ขอบใบแห้ง',
      'Bacterial Leaf Blight',
    ),
    CanonicalLabel('sheath_blight', 'กาบใบแห้ง', 'Sheath Blight'),
    CanonicalLabel('healthy', 'ปกติ', 'Healthy'),
  ];

  /// Pest classes (matches the pest detector head).
  static const List<CanonicalLabel> pests = [
    CanonicalLabel(
      'brown_planthopper',
      'เพลี้ยกระโดดสีน้ำตาล',
      'Brown planthopper',
    ),
    CanonicalLabel('rice_stem_borer', 'หนอนกอข้าว', 'Yellow stem borer'),
    CanonicalLabel('rice_leaffolder', 'หนอนม้วนใบ', 'Rice leaffolder'),
    CanonicalLabel('rice_bug', 'มวนข้าว', 'Rice bug'),
    CanonicalLabel('golden_apple_snail', 'หอยเชอรี่', 'Golden apple snail'),
  ];

  static List<CanonicalLabel> forKind({required bool isPest}) =>
      isPest ? pests : diseases;

  static String nameThFor(String id) {
    for (final l in [...diseases, ...pests]) {
      if (l.id == id) return l.nameTh;
    }
    return id;
  }
}
