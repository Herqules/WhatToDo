import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  /// Placeholder text from the backend for missing descriptions
  static const String _noDescriptionPlaceholder = 'No description available.';

  final Event event;
  const EventCard({Key? key, required this.event}) : super(key: key);

  /// Safely launch the ticket URL if it's non-empty and valid.
  Future<void> _launchUrl() async {
    if (event.ticketUrl.isEmpty) return;
    final uri = Uri.tryParse(event.ticketUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Format an ISO datetime string into "MM/dd/yy — h:mm a".
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

  @override
  Widget build(BuildContext context) {
    // Compute a single date/time label if available.
    String? _getDateTimeLabel() {
      // If backend provided a full ISO datetime with a real time
      if (event.startDatetime.isNotEmpty) {
        return _formatDateWithTime(event.startDatetime);
      }
      // Otherwise, fall back to just the date (MM/dd/yy)
      if (event.date.isNotEmpty) {
        try {
          final d = DateTime.parse(event.date);
          return DateFormat('MM/dd/yy').format(d);
        } catch (_) {
          return event.date;
        }
      }
      return null;
    }

    final dateTimeLabel = _getDateTimeLabel();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + date/time
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
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

            // Location
            Text(
              event.location,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 8),

            // Price
            Text(
              'Price: ${event.price}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            // Description (hide the generic placeholder entirely)
            if (event.description.isNotEmpty &&
                event.description != _noDescriptionPlaceholder)
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 14),
              ),

            const SizedBox(height: 8),

            // Source badge
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                label: Text(
                  event.source,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _getSourceColor(event.source),
                  ),
                ),
                backgroundColor:
                    _getSourceColor(event.source).withOpacity(0.15),
              ),
            ),

            const SizedBox(height: 4),

            // View Tickets button
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
        ),
      ),
    );
  }
}

/// Map source names to brand colors
Color _getSourceColor(String source) {
  switch (source.toLowerCase()) {
    case 'seatgeek':
      return Colors.orange;
    case 'eventbrite':
      return Colors.blue;
    case 'ticketmaster':
      return Colors.redAccent;
    default:
      return Colors.black;
  }
}
