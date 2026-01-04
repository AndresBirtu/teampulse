import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teampulse/features/auth/domain/entities/auth_role.dart';
import 'package:teampulse/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:teampulse/features/auth/presentation/state/login_state.dart';
import 'package:teampulse/features/auth/presentation/state/register_state.dart';
import 'package:teampulse/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:teampulse/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:teampulse/theme/app_colors.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  static final ThemeData _authTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 2,
      iconTheme: IconThemeData(color: AppColors.textOnPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textOnPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        elevation: 2,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _authTheme,
      child: const DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: _AuthAppBar(),
          body: TabBarView(
            children: [
              _LoginTab(),
              _RegisterTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AuthAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      centerTitle: true,
      title: const Text(
        'TeamPulse',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottom: const TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(text: 'Iniciar Sesión'),
          Tab(text: 'Registrarse'),
        ],
      ),
    );
  }
}

class _LoginTab extends ConsumerStatefulWidget {
  const _LoginTab();

  @override
  ConsumerState<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends ConsumerState<_LoginTab> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final success = await ref.read(loginViewModelProvider.notifier).signIn(email: email, password: password);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
      final newMessage = next.errorMessage;
      if (newMessage != null && newMessage.isNotEmpty && newMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newMessage)));
      }
    });

    final loginState = ref.watch(loginViewModelProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(75),
                        ),
                        child: Icon(
                          Icons.sports_soccer,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loginState.isLoading ? null : _login,
                    child: loginState.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Iniciar', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                  ),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterTab extends ConsumerStatefulWidget {
  const _RegisterTab();

  @override
  ConsumerState<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends ConsumerState<_RegisterTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _teamCodeController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();

  Future<void> _register() async {
    final registerNotifier = ref.read(registerViewModelProvider.notifier);
    final registerState = ref.read(registerViewModelProvider);
    final role = registerState.selectedRole;

    if (role == null) {
      _showError('Selecciona un rol para continuar');
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError('Por favor, completa nombre, correo y contraseña');
      return;
    }

    if (role == AuthRole.player && _teamCodeController.text.trim().isEmpty) {
      _showError('Ingresa el código del equipo');
      return;
    }

    if (role == AuthRole.coach && _teamNameController.text.trim().isEmpty) {
      _showError('Ingresa el nombre del equipo');
      return;
    }

    final success = role == AuthRole.coach
        ? await registerNotifier.registerCoach(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            teamName: _teamNameController.text.trim(),
          )
        : await registerNotifier.registerPlayer(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            teamCode: _teamCodeController.text.trim(),
          );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _teamCodeController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RegisterState>(registerViewModelProvider, (previous, next) {
      final newMessage = next.errorMessage;
      if (newMessage != null && newMessage.isNotEmpty && newMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newMessage), backgroundColor: Colors.red));
      }
    });

    final registerState = ref.watch(registerViewModelProvider);
    final selectedRole = registerState.selectedRole;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text('Crear una cuenta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedRole?.name,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'player', child: Text('Jugador')),
                    DropdownMenuItem(value: 'coach', child: Text('Entrenador')),
                  ],
                  onChanged: (value) {
                    final role = value == null ? null : AuthRole.values.byName(value);
                    ref.read(registerViewModelProvider.notifier).selectRole(role);
                  },
                ),
                if (selectedRole == AuthRole.player) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _teamCodeController,
                    decoration: InputDecoration(
                      labelText: 'Código de equipo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                if (selectedRole == AuthRole.coach) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _teamNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del equipo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: registerState.isLoading ? null : _register,
                    child: registerState.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Registrarse', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
