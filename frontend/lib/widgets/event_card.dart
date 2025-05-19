import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({required this.event});

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(event.location, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text("Price: ${event.price}"),
            const SizedBox(height: 6),
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text("Source: ", style: TextStyle(fontSize: 12)),
                    Text(
                      event.source,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getSourceColor(event.source),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _launchURL(event.ticketUrl),
                  child: const Text("View Tickets"),
                ),
              ],
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

