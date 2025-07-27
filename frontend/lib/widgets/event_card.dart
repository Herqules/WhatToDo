// lib/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'widgets_helpers.dart';

class EventCard extends StatefulWidget {
  final Event event;
  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final _unescaper = HtmlUnescape();
  bool _showBack = false;

  Future<void> _launchUrl() async {
    final url = widget.event.ticketUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDateWithTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final dateStr = DateFormat('MM/dd/yy').format(dt);
      final timeStr = DateFormat('h:mm a').format(dt);
      return '$dateStr — $timeStr';
    } catch (_) {
      return iso;
    }
  }

  String _cleanDescription(String raw) {
  var s = HtmlUnescape().convert(raw.trim());
  // remove non‑breaking spaces plus stray C2
  s = s.replaceAll('\u00A0', ' ').replaceAll('\u00C2', '');
  // collapse runs of whitespace
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
  }

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showBack = !_showBack),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedCrossFade(
            firstChild: _buildFront(),
            secondChild: _buildBack(),
            crossFadeState: _showBack
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    final e = widget.event;
    String? dateTimeLabel;
    if (e.startDatetime.isNotEmpty) {
      dateTimeLabel = _formatDateWithTime(e.startDatetime);
    } else if (e.date.isNotEmpty) {
      try {
        dateTimeLabel = DateFormat('MM/dd/yy').format(DateTime.parse(e.date));
      } catch (_) {
        dateTimeLabel = e.date;
      }
    }
    final hasDescription = e.description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                e.title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (dateTimeLabel != null)
              Text(
                dateTimeLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.deepPurple.shade700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          e.location,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        if (e.venueName != null) ...[
          const SizedBox(height: 4),
          Text(
            e.venueName!,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
        if (e.venueFullAddress != null) ...[
          const SizedBox(height: 2),
          Text(
            e.venueFullAddress!,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
//        if (e.venueType != null) ...[
//          const SizedBox(height: 2),
//          Text(
//            'Type: ${e.venueType!}',
//            style: GoogleFonts.poppins(
//              fontSize: 12,
//              fontStyle: FontStyle.italic,
//              color: Colors.grey[500],
//            ),
//          ),
//        ],
//        const SizedBox(height: 8),
        Text(
          'Price: ${widget.event.price}',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        // Show cleaned description or fallback text
        if (hasDescription)
          Text(
            _cleanDescription(e.description),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          )
        else
          Text(
            'More details available on the ticket site.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: Chip(
            label: Text(
              e.source,
              style: GoogleFonts.poppins(fontSize: 12, color: _getSourceColor(e.source)),
            ),
            backgroundColor: _getSourceColor(e.source).withOpacity(0.15),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _launchUrl,
            child: Text(
              'View Tickets',
              style: GoogleFonts.poppins(color: Colors.deepPurple, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

    Widget _buildBack() {
  final e = widget.event;
  final tiles = <Widget>[];
  final seen = <String>{};

  // helper to add one tile, if not already added
  void add(String key, Widget tile) {
    if (tiles.length >= 4) return;      // never exceed 4
    if (!seen.add(key)) return;         // skip if key already seen
    tiles.add(tile);
  }

  // 1) Primary fields in priority order
  if (e.category?.isNotEmpty == true) {
    add('Event Genre', _infoTile(Icons.category, 'Event Genre', _clean(e.category!)));
  }
  if (e.venuePhone?.isNotEmpty == true) {
    add('Phone', _infoTile(Icons.phone, 'Phone', _clean(e.venuePhone!)));
  }
  if (e.acceptedPayment?.isNotEmpty == true) {
    add('Payment', _infoTile(Icons.payment, 'Payment', _clean(e.acceptedPayment!)));
  }
  if (e.parkingDetail?.isNotEmpty == true) {
    add('Parking', _infoTile(Icons.local_parking, 'Parking', e.parkingDetail!));
  }
  if (e.venueType?.isNotEmpty == true) {
    add('Venue Type', _infoTile(Icons.store, 'Venue Type', _clean(e.venueType!)));
  }

  // 2) Secondary fallback
  if (e.venueFullAddress?.isNotEmpty == true) {
    add('Address', _infoTile(Icons.location_on, 'Address', _clean(e.venueFullAddress!)));
  }

  // 3) Final “more info” fallback if we still haven’t filled 4
if (tiles.length < 4) {
  add(
    'More Info',
    _infoTile(
      Icons.info,
      'More Info',
      'Click “View tickets” on the front for full details',
    ),
  );
}


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        e.title,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const Divider(),
      const SizedBox(height: 4),
      ...tiles,
    ],
  );
}



  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getSourceColor(String source) {
  switch (source.toLowerCase()) {
    case 'seatgeek': return Colors.orange;
    case 'ticketmaster': return Colors.redAccent;
    case 'eventbrite': return Colors.blue;
    default: return Colors.black;
  }
}
