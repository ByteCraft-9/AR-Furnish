// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:ar_furnish/config/theme.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: ListView(
        children: [
          _buildFAQHeader(context),
          _buildFAQCategory(
            context,
            'General Questions',
            [
              {
                'question': 'What is AR Furnish?',
                'answer':
                    'AR Furnish is an augmented reality furniture app that lets you visualize furniture and home decor in your space before purchasing. Using your phone\'s camera, you can place virtual furniture in your home to see how it looks and fits.'
              },
              {
                'question': 'Is AR Furnish available for iOS and Android?',
                'answer':
                    'Yes, AR Furnish is available for both iOS and Android devices. For the best AR experience, we recommend using a device that supports ARKit (iOS) or ARCore (Android).'
              },
              {
                'question': 'Do I need to create an account?',
                'answer':
                    'Yes, you need to create an account to make purchases, save your favorite items, and track orders. However, you can browse products without an account.'
              },
            ],
          ),
          _buildFAQCategory(
            context,
            'AR Features',
            [
              {
                'question': 'How does the AR feature work?',
                'answer':
                    'Our AR feature uses your device\'s camera to detect flat surfaces in your environment. You can then place virtual 3D models of furniture on these surfaces to see how they would look in your space.'
              },
              {
                'question': 'Can I customize furniture in AR mode?',
                'answer':
                    'Yes, you can change colors, materials, and sometimes dimensions of furniture while in AR mode. Look for the customize button when viewing a product in AR.'
              },
              {
                'question': 'Why isn\'t AR working on my device?',
                'answer':
                    'AR requires a compatible device with ARKit (iOS) or ARCore (Android) support. Make sure your device meets these requirements and you\'ve granted camera permissions to the app. Good lighting and a textured surface also help with AR detection.'
              },
            ],
          ),
          _buildFAQCategory(
            context,
            'Orders & Payments',
            [
              {
                'question': 'What payment methods do you accept?',
                'answer':
                    'We accept credit/debit cards (Visa, Mastercard, American Express), PayPal, and Apple Pay/Google Pay depending on your device.'
              },
              {
                'question': 'How do I track my order?',
                'answer':
                    'You can track your order in the "Orders" section of your account. You\'ll also receive email updates about your order status.'
              },
              {
                'question': 'What is your return policy?',
                'answer':
                    'We offer a 30-day return policy for most items. Please check the product details page for any exceptions. Return shipping costs may apply depending on the reason for return.'
              },
              {
                'question': 'Can I cancel my order?',
                'answer':
                    'You can cancel your order if it hasn\'t been shipped yet. Go to the "Orders" section and look for the cancel option. If the order has already shipped, you\'ll need to initiate a return.'
              },
            ],
          ),
          _buildFAQCategory(
            context,
            'Technical Support',
            [
              {
                'question': 'The app is crashing, what should I do?',
                'answer':
                    'First, try closing and reopening the app. If that doesn\'t work, restart your device. Make sure your app is updated to the latest version. If problems persist, contact our support team with details about your device and the issue.'
              },
              {
                'question': 'How do I update the app?',
                'answer':
                    'You can update the app through the App Store (iOS) or Google Play Store (Android). We recommend enabling automatic updates for the best experience.'
              },
              {
                'question': 'How do I contact customer support?',
                'answer':
                    'You can contact our customer support team through the "Contact Support" section in the app, or by emailing support@arfurnish.com. Our support hours are Monday to Friday, 9am to 6pm EST.'
              },
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFAQHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Find answers to common questions about using AR Furnish.',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Can\'t find an answer? Contact our support team for assistance.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCategory(
    BuildContext context,
    String categoryTitle,
    List<Map<String, String>> faqs,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              categoryTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: faqs.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: theme.dividerColor),
            itemBuilder: (context, index) {
              return ExpansionTile(
                title: Text(
                  faqs[index]['question']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                iconColor: AppTheme.accentColor,
                collapsedIconColor: theme.unselectedWidgetColor,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      faqs[index]['answer']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
