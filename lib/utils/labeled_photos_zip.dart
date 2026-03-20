import 'dart:io';

import 'package:archive/archive.dart';

import '../inspection_report_model.dart';
import 'photo_labels.dart';

String _sanitizePhotoBaseName(String label) {
  var s = label.trim();

  s = s.replaceAll(RegExp(r'\bextra photo\b', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'\badditional photo\b', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'\badditional\b', caseSensitive: false), '');

  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  s = s.replaceAll(RegExp(r'[^A-Za-z0-9\-\s_]'), '');
  s = s.replaceAll(' ', '_');

  if (s.isEmpty) return 'Image';
  return s;
}

/// Creates a ZIP with labeled photos.
///
/// - If a [PhotoItem.label] matches `Bldg=...|Roof=...|Label=...`, files are
///   placed under a folder named after the building.
/// - Otherwise, files are placed under the "General" folder.
Archive buildLabeledPhotosArchive(List<PhotoItem> items) {
  final counts = <String, int>{};
  final archive = Archive();

  for (final item in items) {
    final parsed = tryParseCommercialPhotoLabel(item.label);

    final folder = parsed == null
        ? 'General'
        : sanitizeZipPathPart(parsed.building);

    final displayLabel = parsed == null ? item.label : parsed.label;

    final base = _sanitizePhotoBaseName(displayLabel);
    final key = '$folder/$base';
    final n = (counts[key] ?? 0) + 1;
    counts[key] = n;

    final filename = '$folder/${base}_Image$n.jpg';
    final bytes = item.file.readAsBytesSync();

    archive.addFile(ArchiveFile(filename, bytes.length, bytes));
  }

  return archive;
}

List<int> encodeZipBytes(Archive archive) {
  final zipBytes = ZipEncoder().encode(archive);
  if (zipBytes == null) {
    throw Exception('Could not generate zip.');
  }
  return zipBytes;
}

Future<File> writeZipToFile({
  required List<int> zipBytes,
  required Directory outputDir,
  required String filename,
}) async {
  final safeName = sanitizeZipPathPart(filename);
  final out = File('${outputDir.path}/$safeName');
  await out.writeAsBytes(zipBytes, flush: true);
  return out;
}
