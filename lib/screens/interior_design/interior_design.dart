import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ar_furnish/config/theme.dart';
import 'package:ar_furnish/services/stable_diffusion_service.dart';
import 'package:ar_furnish/services/replicate_service.dart';
import 'package:ar_furnish/screens/interior_design/saved_designs_screen.dart';

class InteriorDesignScreen extends StatefulWidget {
  const InteriorDesignScreen({super.key});

  @override
  State<InteriorDesignScreen> createState() => _InteriorDesignScreenState();
}

class _InteriorDesignScreenState extends State<InteriorDesignScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  File? _selectedImage;
  final _promptController = TextEditingController();
  final _stableDiffusionUrlController = TextEditingController();
  String? _selectedTheme;
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  bool _showResults = false;
  String? _generatedImage;
  String? _errorMessage;

  late TabController _tabController;

  final List<String> _themes = [
    'Modern',
    'Contemporary',
    'Minimalist',
    'Traditional',
    'Industrial',
    'Scandinavian',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    await StableDiffusionService.loadSavedBaseUrl();
    _stableDiffusionUrlController.text = StableDiffusionService.baseUrl;
  }

  @override
  void dispose() {
    _promptController.dispose();
    _stableDiffusionUrlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showStableDiffusionServerUrlDialog() {
    _stableDiffusionUrlController.text = StableDiffusionService.baseUrl;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a new server URL for Stable Diffusion',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stableDiffusionUrlController,
              decoration: InputDecoration(
                hintText: 'https://your-ngrok-url.ngrok-free.app',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            Text(
              'Leave blank to use the default URL',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              StableDiffusionService.resetToDefaultUrl();
              setState(() {
                _stableDiffusionUrlController.text =
                    StableDiffusionService.baseUrl;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset to default server URL'),
                ),
              );
            },
            child: const Text('Reset to Default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              StableDiffusionService.updateBaseUrl(
                  _stableDiffusionUrlController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Server URL updated: ${StableDiffusionService.baseUrl}'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _showResults = false;
          _generatedImage = null;
          _errorMessage = null;
        });
      }
    } on PlatformException catch (e) {
      print('Platform Exception: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not access gallery. Please check app permissions.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('General Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _showResults = false;
      _generatedImage = null;
      _errorMessage = null;
    });
  }

  Future<void> _processImageWithStableDiffusion() async {
    if (_selectedImage == null ||
        _selectedTheme == null ||
        _promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
      _errorMessage = null;
      _generatedImage = null;
    });

    try {
      // Generate the design using Stable Diffusion
      final base64Image = await StableDiffusionService.generateDesign(
        imageFile: _selectedImage!,
        theme: _selectedTheme!,
        prompt: _promptController.text,
      );

      // Save the generated design to the database
      await StableDiffusionService.saveDesign(
        base64Image: base64Image,
        theme: _selectedTheme!,
        prompt: _promptController.text,
        originalImagePath: _selectedImage!.path,
      );

      setState(() {
        _isLoading = false;
        _showResults = true;
        _generatedImage = base64Image;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processImageWithReplicate() async {
    if (_selectedImage == null ||
        _selectedTheme == null ||
        _promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
      _errorMessage = null;
      _generatedImage = null;
    });

    try {
      // Generate the design using Replicate
      final base64Image = await ReplicateService.generateDesign(
        imageFile: _selectedImage!,
        theme: _selectedTheme!,
        prompt: _promptController.text,
      );

      // Save the generated design to the database
      await ReplicateService.saveDesign(
        base64Image: base64Image,
        theme: _selectedTheme!,
        prompt: _promptController.text,
        originalImagePath: _selectedImage!.path,
      );

      setState(() {
        _isLoading = false;
        _showResults = true;
        _generatedImage = base64Image;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToSavedDesigns() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavedDesignsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interior Design'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Saved Designs',
            onPressed: _navigateToSavedDesigns,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'Stable Diffusion'),
            Tab(text: 'Replicate API'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Stable Diffusion
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server URL indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_sync,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI Server: ${StableDiffusionService.baseUrl}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: _showStableDiffusionServerUrlDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Image Selection Area
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: _selectedImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: _removeImage,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to Add Room Image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Theme Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTheme,
                      decoration: const InputDecoration(
                        hintText: 'Select a theme',
                      ),
                      items: _themes.map((theme) {
                        return DropdownMenuItem(
                          value: theme,
                          child: Text(theme),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTheme = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Prompt Field
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    hintText: 'Describe your desired room style',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : _processImageWithStableDiffusion,
                  icon: const Icon(Icons.send),
                  label: const Text('Generate with Stable Diffusion'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                // Loading Progress
                if (_isLoading && _tabController.index == 0) ...[
                  const SizedBox(height: 24),
                  LinearProgressIndicator(value: _loadingProgress),
                  const SizedBox(height: 8),
                  Text(
                    '${(_loadingProgress * 100).toInt()}%',
                    textAlign: TextAlign.center,
                  ),
                ],

                // Error Message
                if (_errorMessage != null && _tabController.index == 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],

                // Results
                if (_showResults &&
                    _generatedImage != null &&
                    _tabController.index == 0) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generated Design',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _navigateToSavedDesigns,
                        icon: const Icon(Icons.collections),
                        label: const Text('View All Designs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_generatedImage!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tab 2: Replicate API
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Image Selection Area
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: _selectedImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: _removeImage,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to Add Room Image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Theme Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTheme,
                      decoration: const InputDecoration(
                        hintText: 'Select a theme',
                      ),
                      items: _themes.map((theme) {
                        return DropdownMenuItem(
                          value: theme,
                          child: Text(theme),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTheme = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Prompt Field
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    hintText: 'Describe your desired room style',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _processImageWithReplicate,
                  icon: const Icon(Icons.send),
                  label: const Text('Generate with Replicate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                // Loading Progress
                if (_isLoading && _tabController.index == 1) ...[
                  const SizedBox(height: 24),
                  LinearProgressIndicator(value: _loadingProgress),
                  const SizedBox(height: 8),
                  Text(
                    '${(_loadingProgress * 100).toInt()}%',
                    textAlign: TextAlign.center,
                  ),
                ],

                // Error Message
                if (_errorMessage != null && _tabController.index == 1) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],

                // Results
                if (_showResults &&
                    _generatedImage != null &&
                    _tabController.index == 1) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generated Design',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _navigateToSavedDesigns,
                        icon: const Icon(Icons.collections),
                        label: const Text('View All Designs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_generatedImage!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
