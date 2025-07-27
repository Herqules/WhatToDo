// lib/widgets/widgets_helpers.dart

import 'package:intl/intl.dart';
import 'package:html_unescape/html_unescape.dart';

/// Formats an ISO datetime string into "MM/dd/yy — h:mm a".
String formatDateWithTime(String iso) {
  try {
    final dt = DateTime.parse(iso);
    final dateStr = DateFormat('MM/dd/yy').format(dt);
    final timeStr = DateFormat('h:mm a').format(dt);
    return '$dateStr — $timeStr';
  } catch (_) {
    return iso;
  }
}

/// Cleans up raw HTML descriptions by unescaping entities,
/// removing non‑breaking spaces, collapsing whitespace, and trimming.
String cleanDescription(String raw) {
  var s = HtmlUnescape().convert(raw.trim());
  s = s.replaceAll('\u00A0', ' ').replaceAll('\u00C2', '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// Cleans and normalizes arbitrary strings:
/// - Unescape HTML entities
/// - Remove non‑ASCII garbage
/// - Collapse whitespace and trim
String _clean(String? input) {
  if (input == null || input.trim().isEmpty) return '';

  // 1) replace underscores/hyphens with spaces
  var s = input.replaceAll(RegExp(r'[_\-]+'), ' ');

  // 2) unescape HTML entities
  s = HtmlUnescape().convert(s);

  // 3) remove non-ASCII garbage
  s = s.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

  // 4) collapse multiple spaces
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  // 5) title-case every word
  s = s
      .split(' ')
      .map((word) =>
          word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase()
      )
      .join(' ');

  return s;
}
