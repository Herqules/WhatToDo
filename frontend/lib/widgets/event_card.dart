// lib/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../widgets/widgets_helpers.dart';

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
      return '$dateStr · $timeStr';
    } catch (_) {
      return iso;
    }
  }

  String _cleanDescription(String raw) {
    var s = HtmlUnescape().convert(raw.trim());
    s = s.replaceAll('\u00A0', ' ').replaceAll('\u00C2', '');
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
    return InkWell(
      onTap: () => setState(() => _showBack = !_showBack),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedCrossFade(
            firstChild: _buildFront(),
            secondChild: _buildBack(),
            crossFadeState: _showBack
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 350),
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
        // Title & Price Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                e.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Price: ${e.price}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date & Location
        if (dateTimeLabel != null)
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple.shade400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dateTimeLabel,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.place, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                e.location,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Description
        if (hasDescription) ...[
          const SizedBox(height: 12),
          Text(
            _cleanDescription(e.description),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: 16),

        // Source Chip & View Tickets
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Chip(
              label: Text(
                e.source,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getSourceColor(e.source),
                ),
              ),
              backgroundColor: _getSourceColor(e.source).withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            ElevatedButton(
              onPressed: _launchUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: Text(
                'View Tickets',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBack() {
    final e = widget.event;
    final tiles = <Widget>[];
    final seen = <String>{};

    void add(String key, Widget tile) {
      if (tiles.length >= 4) return;
      if (!seen.add(key)) return;
      tiles.add(tile);
    }

    if (e.category?.isNotEmpty == true) {
      add('Genre', _infoTile(Icons.category, 'Genre', _clean(e.category!)));
    }
    if (e.venuePhone?.isNotEmpty == true) {
      add('Phone', _infoTile(Icons.phone, 'Phone', e.venuePhone!));
    }
    if (e.acceptedPayment?.isNotEmpty == true) {
      add('Payment', _infoTile(Icons.payment, 'Payment', e.acceptedPayment!));
    }
    if (e.parkingDetail?.isNotEmpty == true) {
      add('Parking', _infoTile(Icons.local_parking, 'Parking', e.parkingDetail!));
    }
    if (e.venueType?.isNotEmpty == true) {
      add('Venue', _infoTile(Icons.store, 'Venue Type', _clean(e.venueType!)));
    }
    if (e.venueFullAddress?.isNotEmpty == true) {
      add('Address', _infoTile(Icons.location_on, 'Address', e.venueFullAddress!));
    }
    if (tiles.length < 4) {
      add(
        'More Info',
        _infoTile(Icons.info, 'More Info', 'Tap “View Tickets” for full details'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                e.title,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[600]),
              onPressed: () => setState(() => _showBack = false),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: tiles,
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple.shade400),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}

Color _getSourceColor(String source) {
  switch (source.toLowerCase()) {
    case 'seatgeek': return Colors.orange;
    case 'ticketmaster': return Colors.redAccent;
    case 'eventbrite': return Colors.blue;
    default: return Colors.grey.shade800;
  }
}
