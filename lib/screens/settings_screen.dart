import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'Русский';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'Русский';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('notifications_enabled', _isNotificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Темная тема'),
            subtitle: const Text('Использовать темную тему приложения'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                _saveSettings();
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Уведомления'),
            subtitle: const Text('Получать уведомления о маршрутах'),
            trailing: Switch(
              value: _isNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _isNotificationsEnabled = value;
                });
                _saveSettings();
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Язык'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Выберите язык'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Русский'),
                        onTap: () {
                          setState(() {
                            _selectedLanguage = 'Русский';
                          });
                          _saveSettings();
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('English'),
                        onTap: () {
                          setState(() {
                            _selectedLanguage = 'English';
                          });
                          _saveSettings();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('О приложении'),
            subtitle: const Text('Версия 1.0.0'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Автобусное приложение',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.directions_bus,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
                children: const [
                  Text(
                    'Приложение для отслеживания автобусных маршрутов и расписания.',
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