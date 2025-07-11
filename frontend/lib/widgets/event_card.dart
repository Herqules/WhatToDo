// lib/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final Event event;
  const EventCard({Key? key, required this.event}) : super(key: key);

  Future<void> _launchUrl() async {
    final uri = Uri.parse(event.ticketUrl);
    if (await canLaunchUrl(uri)) {
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

  @override
  Widget build(BuildContext context) {
    final dateTimeLabel = event.date.isNotEmpty
        ? _formatDateWithTime(event.date)
        : null;

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

            // Description
            if (event.description.isNotEmpty)
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 14),
              ),

            const SizedBox(height: 8),

            // Event source badge ABOVE the View Tickets button, aligned right
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
