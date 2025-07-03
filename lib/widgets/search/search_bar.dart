import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSearch;
  final String hintText;

  const SearchBar({
    super.key,
    required this.initialValue,
    required this.onSearch,
    this.hintText = 'Search available furniture...',
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onSubmitted: widget.onSearch,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
