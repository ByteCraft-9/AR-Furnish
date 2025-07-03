import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF854836);

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // Current selected language
  String _selectedLanguage = 'English';

  // Available languages
  final List<String> _languages = [
    'English',
    'Urdu',
    'Arabic',
    'Chinese',
    'French',
    'German',
    'Hindi',
    'Italian',
    'Japanese',
    'Spanish',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                return RadioListTile<String>(
                  title: Text(
                    language,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: language,
                  groupValue: _selectedLanguage,
                  activeColor: primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    // Show a message that this is just a demo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Language changed to English only (Demo)'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
