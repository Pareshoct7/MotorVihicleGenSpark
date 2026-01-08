import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Developer'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Developer profile
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF0B6BB8),
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Developer name
            Text(
              'Paresh Patil',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Mobile App Developer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // App info card
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About This App',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Domino\'s Fleet Inspector is a professional vehicle inspection application designed specifically for Domino\'s Pizza fleet management. Built with Flutter for optimal performance across Android devices.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.verified, size: 20, color: Color(0xFF0B6BB8)),
                        const SizedBox(width: 8),
                        Text(
                          'Version 2.0.0',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contact information card
            Card(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Developer',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'For support, feedback, or custom development',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Email contact
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE31837),
                      child: Icon(Icons.email, color: Colors.white),
                    ),
                    title: Text('Email'),
                    subtitle: Text('paresh.oct7@gmail.com'),
                    trailing: IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'paresh.oct7@gmail.com'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied to clipboard')),
                        );
                      },
                    ),
                    onTap: () => _launchEmail(),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Phone contact
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF0B6BB8),
                      child: Icon(Icons.phone, color: Colors.white),
                    ),
                    title: Text('Phone'),
                    subtitle: Text('+64 220949069'),
                    trailing: IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: '+64 220949069'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Phone number copied')),
                        );
                      },
                    ),
                    onTap: () => _launchPhone(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Credits
            Text(
              '© 2025 Paresh Patil',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Developed with ❤️ using Flutter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'paresh.oct7@gmail.com',
      query: 'subject=Dominos Fleet Inspector - Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+64220949069',
    );
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}
