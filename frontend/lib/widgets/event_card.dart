// lib/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class EventCard extends StatefulWidget {
  final Event event;
  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _showBack = false;

  Future<void> _launchUrl() async {
    if (widget.event.ticketUrl.isEmpty) return;
    final uri = Uri.tryParse(widget.event.ticketUrl);
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

  Widget _buildFront() {
    final e = widget.event;
    String? dateTimeLabel;
    if (e.startDatetime.isNotEmpty) {
      dateTimeLabel = _formatDateWithTime(e.startDatetime);
    } else if (e.date.isNotEmpty) {
      try {
        final d = DateTime.parse(e.date);
        dateTimeLabel = DateFormat('MM/dd/yy').format(d);
      } catch (_) {
        dateTimeLabel = e.date;
      }
    }
    final hasDescription = e.description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + datetime
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
        // City
        Text(
          e.location,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        // Venue name / address / type
        if (e.venueName != null) ...[
          const SizedBox(height: 4),
          Text(
            e.venueName!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (e.venueFullAddress != null) ...[
          const SizedBox(height: 2),
          Text(
            e.venueFullAddress!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
        if (e.venueType != null) ...[
          const SizedBox(height: 2),
          Text(
            'Venue type: ${e.venueType!}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Price
        Text(
          'Price: ${e.price}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Description or hint
        if (hasDescription)
          Text(
            e.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 14),
          )
        else
          Text(
            'More details on the ticket site →',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        const SizedBox(height: 8),
        // Source badge
        Align(
          alignment: Alignment.centerRight,
          child: Chip(
            label: Text(
              e.source,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _getSourceColor(e.source),
              ),
            ),
            backgroundColor: _getSourceColor(e.source).withOpacity(0.15),
          ),
        ),
        const SizedBox(height: 4),
        // View Tickets
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _launchUrl,
            child: Text(
              'View Tickets',
              style: GoogleFonts.poppins(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBack() {
    final e = widget.event;
    final infoRows = <Widget>[];

    if (e.category != null) {
      infoRows.add(_infoLine('Category', e.category!));
    }
    if (e.venuePhone != null) {
      infoRows.add(_infoLine('Phone', e.venuePhone!));
    }
    if (e.acceptedPayment != null) {
      infoRows.add(_infoLine('Payment', e.acceptedPayment!));
    }
    if (e.parkingDetail != null) {
      infoRows.add(_infoLine('Parking', e.parkingDetail!));
    }
    // fallback
    if (infoRows.isEmpty) {
      infoRows.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'No additional info available.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Info',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Divider(),
        ...infoRows,
      ],
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showBack = !_showBack),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedCrossFade(
            firstChild: _buildFront(),
            secondChild: _buildBack(),
            crossFadeState: _showBack
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            layoutBuilder:
                (f, fKey, s, sKey) => Stack(
              alignment: Alignment.center,
              children: [
                Positioned(key: fKey, child: f),
                Positioned(key: sKey, child: s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _getSourceColor(String source) {
  switch (source.toLowerCase()) {
    case 'seatgeek':
      return Colors.orange;
    case 'ticketmaster':
      return Colors.redAccent;
    case 'eventbrite':
      return Colors.blue;
    default:
      return Colors.black;
  }
}
