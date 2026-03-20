String buildCommercialPhotoLabel({
  required String building,
  required String roof,
  required String label,
}) {
  return 'Bldg=$building|Roof=$roof|Label=$label';
}

({String building, String roof, String label})? tryParseCommercialPhotoLabel(
  String input,
) {
  final raw = input.trim();
  if (!raw.startsWith('Bldg=')) return null;

  final parts = raw.split('|');
  String? b;
  String? r;
  String? l;

  for (final p in parts) {
    final idx = p.indexOf('=');
    if (idx <= 0) continue;
    final key = p.substring(0, idx);
    final val = p.substring(idx + 1);

    if (key == 'Bldg') b = val;
    if (key == 'Roof') r = val;
    if (key == 'Label') l = val;
  }

  if (b == null || r == null || l == null) return null;
  return (building: b, roof: r, label: l);
}

String sanitizeZipPathPart(String input) {
  var s = input.trim();
  if (s.isEmpty) return 'UNKNOWN';

  // Avoid path traversal + platform-invalid characters.
  s = s.replaceAll(RegExp(r'[\\/\:\*\?"<>\|]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s.isEmpty ? 'UNKNOWN' : s;
}
