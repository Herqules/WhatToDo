import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';

class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({Key? key}) : super(key: key);

  @override
  State<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends State<EventSearchScreen> {
  final TextEditingController _locationCtrl = TextEditingController();
  DateTime? _pickedDate;
  bool _loading = false;
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _locationCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  /// Fetches location suggestions from OpenStreetMap Nominatim
  Future<List<String>> _getLocationSuggestions(String pattern) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(pattern)}&format=json&limit=5&countrycodes=us',
    );
    final res = await http.get(uri, headers: {'User-Agent': 'WTD-App'});
    if (res.statusCode != 200) return [];
    final List data = json.decode(res.body);
    return data.map<String>((e) => e['display_name'] as String).toList();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dt != null) setState(() => _pickedDate = dt);
  }

  Future<void> _search() async {
    if (_locationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a location.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_pickedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

setState(() => _loading = true);
  try {
    final city = _locationCtrl.text.trim();

     final isoDate = DateFormat('yyyy-MM-dd').format(_pickedDate!);


    // fetch everything (backend may do a coarse filter)…
    final all = await EventService.fetchAllEvents(
      city: city,
      date: isoDate,
    );

    // …but then enforce exact same-day filtering on the client:
    _events = all.where((evt) {
      // evt.date might be "2025-07-08T19:30:00" or just "2025-07-08"
      final dayOnly = evt.date.split('T').first;
      return dayOnly == isoDate;
    }).toList();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
    );
  } finally {
    setState(() => _loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    final dateLabel = _pickedDate == null
        ? 'Pick a date'
        : DateFormat.yMMMd().format(_pickedDate!);

    final canSearch = !_loading &&
        _locationCtrl.text.isNotEmpty &&
        _pickedDate != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF5FF), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      'WTD',
                      style: GoogleFonts.poppins(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WhatToDo',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Autocomplete location field
                        TypeAheadFormField<String>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: _locationCtrl,
                            decoration: InputDecoration(
                              labelText: 'City or location',
                              labelStyle: GoogleFonts.poppins(),
                              prefixIcon: const Icon(Icons.location_on),
                              suffixIcon: _locationCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _locationCtrl.clear(),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          suggestionsCallback: _getLocationSuggestions,
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(
                                suggestion,
                                style: GoogleFonts.poppins(),
                              ),
                            );
                          },
                          onSuggestionSelected: (suggestion) {
                            _locationCtrl.text = suggestion;
                          },
                          noItemsFoundBuilder: (context) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'No locations found',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(dateLabel,
                                    style: GoogleFonts.poppins()),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                      color: Colors.deepPurple.shade200),
                                ),
                                onPressed: _loading ? null : _pickDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: canSearch ? _search : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.deepPurple,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(
                                      'Search',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Results / Placeholder / Cards
              Expanded(
                child: _loading
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (_, __) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.grey[300],
                          child: const SizedBox(height: 80),
                        ),
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemCount: 5,
                      )
                    : _events.isEmpty
                        ? Center(
                            child: Text(
                              'No events found',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 16),
                            itemCount: _events.length,
                            itemBuilder: (ctx, i) => EventCard(event: _events[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
