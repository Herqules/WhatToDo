import 'package:flutter/material.dart';

class LocationInput extends StatelessWidget {
  final Function(String) onChanged;

  const LocationInput({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Enter a city or location',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      onChanged: onChanged,
    );
  }
}
