const List<String> roofTypesAll = [
  'Shingles',
  'Metal',
  'Tile roofing',
  'Wood Shake',
  'Slate Roof',
  'TPO',
  'Modified Bitumen',
  'EPDM',
  'Roll Roofing',
  'Other',
];

const Map<String, List<String>> roofSubtypesByType = {
  'Shingles': ['Laminated', '3 Tab'],
  'Metal': [
    'Standing seam',
    'Corrugated',
    'Ribbed',
    'Wall/Roof Panel corrugated',
    'Other',
  ],
  'Tile roofing': ['Concrete', 'Clay'],
  'Wood Shake': ['Medium (1/2”)', 'Heavy (3/4”)'],
  'Slate Roof': ['Slate roofing (12 to 18) in', 'Slate roofing (12 to 24) in'],
  'TPO': [
    'Fully adhered system > 45 mil',
    'Fully adhered system > 60 mil',
    'Mech Att > 45 mil',
    'Mech Att > 60 mil',
    'Perimeter Adhered system > 45 mil',
    'Perimeter Adhered system > 60 mil',
  ],
  'Modified Bitumen': ['Hot mopped', 'Self-adhering'],
  'EPDM': [
    'Fully adhered system > 45 mil',
    'Fully adhered system > 60 mil',
    'Fully adhered system > 75 mil',
    'Fully adhered system > 90 mil',
    'Mech Att > 45 mil',
    'Mech Att > 60 mil',
    'Mech Att > 75 mil',
    'Mech Att > 90 mil',
    'Perimeter Adhered system > 45 mil',
    'Perimeter Adhered system > 60 mil',
    'Perimeter Adhered system > 75 mil',
    'Perimeter Adhered system > 90 mil',
  ],
  'Roll Roofing': ['Hot mopped', 'Self-adhering'],
};

List<String> subtypesForRoofType(String? roofType) {
  if (roofType == null) return const [];
  return roofSubtypesByType[roofType] ?? const [];
}
