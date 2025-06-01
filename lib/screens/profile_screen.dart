import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  app_user.User? _user;
  bool _isLoading = true;
  DateTime? _selectedDate;

  // Контроллеры для текстовых полей
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    // _loadUserData() будет вызван после build, когда context доступен
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final userId = authService.currentUser?.id;
      if (userId != null) {
        final user = await dbService.getUser(userId);
        if (!mounted) return;
        
        setState(() {
          _user = user;
          if (user != null) {
            _firstNameController.text = user.firstName;
            _lastNameController.text = user.lastName;
            _phoneController.text = user.phoneNumber ?? '';
            _selectedDate = user.birthDate;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при загрузке данных'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final user = authService.currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      final updatedUser = app_user.User(
        id: user.id,
        email: user.email,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        birthDate: _selectedDate,
      );

      // Используем dbService для обновления пользователя в базе данных
      await dbService.updateUser(updatedUser);
      
      // Обновляем данные текущего пользователя в AuthService
      // Возможно, AuthService должен иметь метод для этого или мы обновляем напрямую
      // await authService.updateCurrentUser(updatedUser); // Пример

      if (!mounted) return;

      // Обновляем локальное состояние пользователя
      setState(() {
         _user = updatedUser;
         _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль успешно обновлен'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при обновлении профиля'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удаление аккаунта'),
          content: const Text(
            'Вы уверены, что хотите удалить свой аккаунт? Это действие нельзя отменить.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Удалить',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final user = authService.currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      await dbService.deleteUser(user.id);
      await authService.signOut();

      if (!mounted) return;

      // Сохраняем context после проверки mounted
      final currentContext = context;
      if (!currentContext.mounted) return; // Дополнительная проверка для анализатора
      Navigator.of(currentContext).pushReplacementNamed('/auth');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при удалении аккаунта'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
     // Загружаем данные пользователя при первом построении виджета
    if (_user == null && !_isLoading) {
      _loadUserData();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Пользователь не найден'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Личные данные',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Имя',
                                  hintText: 'Введите ваше имя',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Фамилия',
                                  hintText: 'Введите вашу фамилию',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Ваш email адрес',
                                ),
                                enabled: false,
                                controller: TextEditingController(text: _user!.email),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Телефон',
                                  hintText: 'Введите номер телефона',
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                title: const Text('Дата рождения'),
                                subtitle: Text(
                                  _selectedDate != null
                                      ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                                      : 'Не указана',
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: _selectDate,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _updateProfile,
                                  child: const Text('Сохранить изменения'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Управление аккаунтом',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.delete_forever),
                                title: const Text('Удалить аккаунт'),
                                subtitle: const Text(
                                  'Удаление аккаунта нельзя отменить. Все ваши данные будут удалены.',
                                ),
                                onTap: _isLoading ? null : _deleteAccount,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 