import 'package:flutter/material.dart';
import 'package:ar_furnish/config/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Acceptance of Terms',
                'By accessing or using AR Furnish, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use our app.\n\nWe reserve the right to modify these terms at any time. Your continued use of AR Furnish after such modifications constitutes your acceptance of the updated terms.',
              ),
              _buildSection(
                context,
                'User Accounts',
                'You are responsible for maintaining the confidentiality of your account information, including your password. You are fully responsible for all activities that occur under your account.\n\nYou agree to notify us immediately of any unauthorized use of your account or any other breach of security. We cannot be held liable for any loss or damage arising from your failure to comply with this provision.',
              ),
              _buildSection(
                context,
                'AR Technology Use',
                'Our Augmented Reality features are provided "as is" and may not function perfectly on all devices. AR Furnish requires a compatible device with functioning camera and adequate processing capabilities.\n\nYou understand that the AR visualization is an approximation and actual products may differ in appearance, size, or color from the AR representation. The AR feature is intended as a visualization aid only.',
              ),
              _buildSection(
                context,
                'Product Information',
                'We strive to provide accurate product information, including dimensions, colors, and materials. However, we do not warrant that product descriptions or other content on our app is accurate, complete, reliable, current, or error-free.\n\nThe colors you see will depend on your device display, and we cannot guarantee that your device\'s display of any color will be accurate.',
              ),
              _buildSection(
                context,
                'Purchases and Payments',
                'By making a purchase through AR Furnish, you warrant that you are legally capable of entering into binding contracts.\n\nPrices for products are subject to change without notice. We reserve the right to refuse or cancel any order at any time for reasons including but not limited to product availability, errors in product description or pricing, or problems identified by our fraud protection services.\n\nPayment for all orders must be made through the approved methods offered within the app. All payment information is securely processed and stored according to industry standards.',
              ),
              _buildSection(
                context,
                'Shipping and Delivery',
                'Delivery times are estimates only and commence from the date of shipping, not the date of order.\n\nWe are not responsible for delays outside our control, such as customs delays or natural disasters. Risk of loss and title for items purchased pass to you upon delivery of the items to the carrier.',
              ),
              _buildSection(
                context,
                'Returns and Refunds',
                'You may return most new, unopened items within 30 days of delivery for a full refund. We\'ll also pay the return shipping costs if the return is a result of our error.\n\nFor items that are defective, damaged, or incorrect, please contact our customer service team immediately. Some items, such as custom orders or personalized products, may not be eligible for return.',
              ),
              _buildSection(
                context,
                'Intellectual Property',
                'The app and all of its content, features, and functionality, including but not limited to all information, software, text, displays, images, video, and audio, are owned by AR Furnish or its licensors and are protected by copyright, trademark, patent, and other intellectual property laws.\n\nAny use of the app or its content not expressly permitted by these Terms of Service is a breach of these terms and may violate copyright, trademark, and other laws.',
              ),
              _buildSection(
                context,
                'Limitation of Liability',
                'To the fullest extent permitted by law, AR Furnish shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of profits, data, use, or goodwill, resulting from your access to or use of or inability to access or use the app.\n\nIn no event shall our total liability to you for all claims exceed the amount paid by you, if any, for accessing our app over the past 12 months.',
              ),
              _buildSection(
                context,
                'Governing Law',
                'These Terms of Service and any dispute or claim arising out of or related to them shall be governed by and construed in accordance with the laws of Pakistan, without giving effect to any choice or conflict of law provision or rule.',
              ),
              _buildSection(
                context,
                'Contact Information',
                'If you have any questions about these Terms of Service, please contact us at:\n\nEmail: legal@arfurnish.com\nPhone: +92 123 456 7890\nAddress: 123 Commerce Street, Lahore, Pakistan',
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Last Updated: January 1, 2023',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Terms of Service',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please read these Terms of Service carefully before using the AR Furnish mobile application. These terms govern your use of our app and services.',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
