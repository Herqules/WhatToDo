import 'package:flutter/material.dart';
import '../widgets/location_input.dart';
import '../widgets/interest_picker.dart';
import '../widgets/event_card.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String city = '';
  List<String> selectedInterests = [];
  List<Event> events = [];
  bool isLoading = false;
  String? error;

void _onSearch() async {
  if (city.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a city or location.')),
    );
    return;
  }

  setState(() {
    isLoading = true;
    error = null;
    events = [];
  });

  try {
    final result = await ApiService.fetchEvents(
      city: city,
      interests: selectedInterests,
      minPrice: 0,
      maxPrice: 1500,
      radius: 100,
    );
    setState(() {
      events = result;
    });
  } catch (e) {
    setState(() {
      error = 'Failed to load events: ${e.toString()}';
    });
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("WTD", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("WhatToDo", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LocationInput(onChanged: (value) => city = value),
            const SizedBox(height: 12),
            InterestPicker(
              onSelectionChanged: (interests) => selectedInterests = interests,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onSearch,
              child: const Text("Find Events"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text(error!))
                      : events.isEmpty
                          ? const Center(child: Text("No events found"))
                          : ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (context, index) =>
                                  EventCard(event: events[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
