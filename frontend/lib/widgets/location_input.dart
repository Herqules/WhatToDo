import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationInput extends StatefulWidget {
  final Function(String) onChanged;

  const LocationInput({required this.onChanged, Key? key}) : super(key: key);

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  final _controller = TextEditingController();
  List<String> _suggestions = [];

  void _onChanged(String value) async {
    widget.onChanged(value);
    if (value.length > 2) {
      final results = await LocationService.searchCities(value);
      setState(() {
        _suggestions = results;
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: InputDecoration(labelText: 'City or Location'),
        ),
        if (_suggestions.isNotEmpty)
          ..._suggestions.map((s) => ListTile(
                title: Text(s),
                onTap: () {
                  _controller.text = s;
                  widget.onChanged(s);
                  setState(() => _suggestions = []);
                },
              ))
      ],
    );
  }
}
