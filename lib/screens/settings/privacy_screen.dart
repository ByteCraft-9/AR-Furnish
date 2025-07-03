import 'package:flutter/material.dart';
import 'package:ar_furnish/config/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                'Information We Collect',
                'We collect several types of information from and about users of our App, including:\n\n'
                    '• Personal information: name, email address, phone number, and shipping address when you create an account or make a purchase.\n'
                    '• Camera data: When using the AR features, we temporarily access your camera feed to provide the augmented reality experience. This data is not stored or transmitted to our servers.\n'
                    '• Device information: including your device type, operating system, IP address, and mobile network information.\n'
                    '• Usage data: information about how you interact with our app, such as features accessed, products viewed, and time spent in the app.',
              ),
              _buildSection(
                context,
                'How We Use Your Information',
                'We use the information we collect to:\n\n'
                    '• Process and fulfill your orders and manage your account\n'
                    '• Provide the AR furniture preview functionality\n'
                    '• Improve and optimize our app and your experience\n'
                    '• Send you order confirmations, updates, and support messages\n'
                    '• Send marketing communications (if you\'ve opted in)\n'
                    '• Detect and prevent fraudulent transactions and activities\n'
                    '• Comply with legal obligations',
              ),
              _buildSection(
                context,
                'Information Sharing',
                'We may share your information with:\n\n'
                    '• Service providers: companies that perform services on our behalf, such as payment processing, shipping, and customer service\n'
                    '• Business partners: furniture manufacturers and retailers whose products are available through our app\n'
                    '• Legal entities: when required by law, or to protect our rights, property, or safety\n\n'
                    'We do not sell or rent your personal information to third parties for their marketing purposes without your explicit consent.',
              ),
              _buildSection(
                context,
                'Data Security',
                'We implement appropriate technical and organizational measures to protect the security of your personal information. However, please be aware that no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.\n\n'
                    'Your account information is protected by a password. Please use a strong password and limit access to your device and browser.',
              ),
              _buildSection(
                context,
                'Data Retention',
                'We will retain your personal information for as long as your account is active or as needed to provide you with services. We will also retain and use your information as necessary to comply with legal obligations, resolve disputes, and enforce our agreements.\n\n'
                    'You can request deletion of your account and personal information by contacting our support team.',
              ),
              _buildSection(
                context,
                'AR Camera Usage',
                'Our AR feature requires access to your device\'s camera to function. The camera feed is used only within your device to display AR furniture in your space. We do not record, store, or transmit any images or video from your camera.\n\n'
                    'Camera access is only active when you explicitly choose to use the AR feature, and you can revoke camera permissions at any time through your device settings.',
              ),
              _buildSection(
                context,
                'Your Privacy Rights',
                'Depending on your location, you may have certain rights regarding your personal information, including:\n\n'
                    '• Access: You can request a copy of the personal information we hold about you.\n'
                    '• Correction: You can request that we correct inaccurate information about you.\n'
                    '• Deletion: You can request that we delete your personal information.\n'
                    '• Restriction: You can request that we restrict the processing of your data.\n'
                    '• Data portability: You can request a copy of your data in a structured, commonly used format.\n\n'
                    'To exercise these rights, please contact us at privacy@arfurnish.com.',
              ),
              _buildSection(
                context,
                'Children\'s Privacy',
                'Our App is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we learn we have collected or received personal information from a child under 13 without verification of parental consent, we will delete that information. If you believe we might have any information from or about a child under 13, please contact us.',
              ),
              _buildSection(
                context,
                'Changes to Our Privacy Policy',
                'We may update our Privacy Policy from time to time. If we make material changes, we will notify you by email or through a notice on our App prior to the change becoming effective. We encourage you to review our Privacy Policy periodically for any changes.',
              ),
              _buildSection(
                context,
                'Contact Information',
                'If you have any questions or concerns about our Privacy Policy or our privacy practices, please contact us at:\n\n'
                    'Email: privacy@arfurnish.com\n'
                    'Phone: +92 123 456 7890\n'
                    'Address: 123 Commerce Street, Lahore, Pakistan',
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
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'At AR Furnish, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our app.',
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
                  Icons.privacy_tip_outlined,
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
