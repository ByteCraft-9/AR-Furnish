import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSearch;
  final String hintText;

  const CustomSearchBar({
    super.key,
    required this.initialValue,
    required this.onSearch,
    this.hintText = 'Search furniture...',
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
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