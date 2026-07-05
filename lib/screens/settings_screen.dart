import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = themeNotifier.value == ThemeMode.dark;
  bool _isHapticOn = hapticNotifier.value;

  Future<void> _toggleTheme(bool value) async {
    setState(() => _isDarkMode = value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> _toggleHaptic(bool value) async {
    setState(() => _isHapticOn = value);
    hapticNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticFeedback', value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme Section
          Text(
            'TAMPILAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SwitchListTile(
              value: _isDarkMode,
              onChanged: _toggleTheme,
              activeTrackColor: color.withValues(alpha: 0.5),
              activeThumbColor: color,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Gunakan tema gelap untuk aplikasi', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SwitchListTile(
              value: _isHapticOn,
              onChanged: _toggleHaptic,
              activeTrackColor: color.withValues(alpha: 0.5),
              activeThumbColor: color,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              title: const Text('Getaran (Haptic)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Getaran saat menyalin kode atau interaksi', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isHapticOn ? Icons.vibration_rounded : Icons.mobile_off_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // General Section
          Text(
            'UMUM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline_rounded, color: color, size: 20),
                  ),
                  title: const Text('Tentang MIDA', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Support Section
          Text(
            'BANTUAN & DUKUNGAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                  ),
                  title: const Text('Hubungi via WhatsApp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('085933648537', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.open_in_new_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () async {
                    final uri = Uri.parse('https://wa.me/6285933648537?text=Halo%20Admin%20MIDA,%20saya%20butuh%20bantuan');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                Divider(height: 1, indent: 60, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.email_rounded, color: Color(0xFFEA4335), size: 20),
                  ),
                  title: const Text('Lapor Bug / Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('ardhikayanuar58@gmail.com', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.open_in_new_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () async {
                    final uri = Uri.parse('mailto:ardhikayanuar58@gmail.com?subject=Bantuan%20/ %20Lapor%20Bug%20Aplikasi%20MIDA');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
