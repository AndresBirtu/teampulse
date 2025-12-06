# 💡 TeamPulse - Ejemplos de Código (Copy-Paste Ready)

## 🔧 Ejemplos Rápidos de Uso

### 1. Cambiar tema desde cualquier widget

```dart
// Opción A: Acceder al tema de MyApp
final _myAppState = context.findAncestorStateOfType<_MyAppState>();
_myAppState?._changeTheme(ThemeOption.green);

// Opción B: Desde ProfilePage (recomendado)
widget.onThemeChanged?.call(ThemeOption.purple);
```

### 2. Traducir un texto

```dart
// En cualquier widget con BuildContext
Text(context.tr('dashboard'))      // "Inicio" o "Home"
Text(context.tr('hello'))           // "Hola" o "Hello"
Text(context.tr('logout'))          // "Cerrar sesión" o "Logout"

// Concatenación de traducciones
Text('${context.tr('played')}: 5')  // "Jugados: 5" o "Played: 5"
```

### 3. Obtener preferencias guardadas

```dart
import 'services/preferences_service.dart';

// Obtener tema actual
ThemeOption currentTheme = PreferencesService.getSelectedTheme();

// Obtener idioma actual
String lang = PreferencesService.getSelectedLanguage(); // 'es' o 'en'

// Obtener estado de notificaciones
bool notifs = PreferencesService.getNotificationsEnabled();
```

### 4. Guardar preferencias

```dart
// Guardar nuevo tema
await PreferencesService.setSelectedTheme(ThemeOption.orange);

// Guardar idioma
await PreferencesService.setSelectedLanguage('en');

// Guardar notificaciones
await PreferencesService.setNotificationsEnabled(false);
```

### 5. Cambiar idioma dinámicamente

```dart
// En un diálogo o ListTile
ListTile(
  title: const Text('English'),
  onTap: () async {
    await context.setLocale(const Locale('en'));
    await PreferencesService.setSelectedLanguage('en');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('language_changed'))),
    );
  },
)
```

---

## 📱 Fragmentos de UI Listos para Copiar

### 1. Selector de Tema Simple (ProfilePage)

```dart
// Importar en ProfilePage
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_themes.dart';
import '../widgets/theme_selector.dart';

// En el body del ListView:
// Opción 1: Usar ThemeSettings widget directo
if (widget.currentTheme != null && widget.onThemeChanged != null)
  ThemeSettings(
    currentTheme: widget.currentTheme!,
    onThemeChanged: widget.onThemeChanged!,
  ),

// Opción 2: Usar custom ListTile
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: ListTile(
    leading: Icon(Icons.palette),
    title: Text(context.tr('theme')),
    subtitle: Text(
      context.locale.languageCode == 'en'
          ? widget.currentTheme?.displayNameEn ?? 'Blue'
          : widget.currentTheme?.displayName ?? 'Azul',
    ),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      showDialog(
        context: context,
        builder: (context) => ThemeSelector(
          currentTheme: widget.currentTheme ?? ThemeOption.blue,
          onThemeChanged: widget.onThemeChanged ?? (_) {},
        ),
      );
    },
  ),
)
```

### 2. Selector de Idioma (ProfilePage)

```dart
// Importar
import 'package:easy_localization/easy_localization.dart';
import '../services/preferences_service.dart';

// En el body del ListView:
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: ListTile(
    leading: Icon(Icons.language),
    title: Text(context.tr('language')),
    subtitle: Text(
      context.locale.languageCode == 'en' ? 'English' : 'Español',
    ),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () => _showLanguageDialog(context),
  ),
)

// Helper function:
void _showLanguageDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('change_language')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Español'),
            trailing: context.locale.languageCode == 'es'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () async {
              await context.setLocale(const Locale('es'));
              await PreferencesService.setSelectedLanguage('es');
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('language_changed')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: const Text('English'),
            trailing: context.locale.languageCode == 'en'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () async {
              await context.setLocale(const Locale('en'));
              await PreferencesService.setSelectedLanguage('en');
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('language_changed')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('close')),
        ),
      ],
    ),
  );
}
```

### 3. Toggle de Notificaciones (ProfilePage)

```dart
// Importar
import '../services/preferences_service.dart';

// En initState:
@override
void initState() {
  super.initState();
  _notificationsEnabled = PreferencesService.getNotificationsEnabled();
}

// En el body:
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: ListTile(
    leading: Icon(Icons.notifications),
    title: Text(context.tr('notifications')),
    subtitle: Text(
      _notificationsEnabled
          ? context.tr('notifications_enabled')
          : context.tr('notifications_disabled'),
    ),
    trailing: Switch(
      value: _notificationsEnabled,
      onChanged: (value) async {
        setState(() => _notificationsEnabled = value);
        await PreferencesService.setNotificationsEnabled(value);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? context.tr('enable_notifications')
                  : context.tr('disable_notifications'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    ),
  ),
)
```

### 4. Sección Completa de Apariencia (ProfilePage)

```dart
// Importar todo lo necesario
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_themes.dart';
import '../services/preferences_service.dart';
import '../widgets/theme_selector.dart';

// En el body:
// Encabezado de sección
Padding(
  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
  child: Text(
    context.tr('appearance'),
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
),

// Selector de tema
ThemeSettings(
  currentTheme: widget.currentTheme ?? ThemeOption.blue,
  onThemeChanged: widget.onThemeChanged ?? (_) {},
),

// Selector de idioma
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: ListTile(
    leading: Icon(Icons.language),
    title: Text(context.tr('language')),
    subtitle: Text(
      context.locale.languageCode == 'en' ? 'English' : 'Español',
    ),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () => _showLanguageDialog(context),
  ),
),

const SizedBox(height: 16),

// Encabezado de notificaciones
Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  child: Text(
    context.tr('notification_settings'),
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
),

// Toggle de notificaciones
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: ListTile(
    leading: Icon(Icons.notifications),
    title: Text(context.tr('notifications')),
    trailing: Switch(
      value: _notificationsEnabled,
      onChanged: (value) async {
        setState(() => _notificationsEnabled = value);
        await PreferencesService.setNotificationsEnabled(value);
      },
    ),
  ),
),
```

### 5. ProfilePage Completo (Template)

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_themes.dart';
import '../services/preferences_service.dart';
import '../widgets/theme_selector.dart';

class ProfilePage extends StatefulWidget {
  final ThemeOption? currentTheme;
  final Function(ThemeOption)? onThemeChanged;

  const ProfilePage({
    this.currentTheme,
    this.onThemeChanged,
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = PreferencesService.getNotificationsEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
        elevation: 2,
      ),
      body: ListView(
        children: [
          // SECCIÓN: APARIENCIA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              context.tr('appearance'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          // Tema
          if (widget.currentTheme != null && widget.onThemeChanged != null)
            ThemeSettings(
              currentTheme: widget.currentTheme!,
              onThemeChanged: widget.onThemeChanged!,
            ),
          
          // Idioma
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.tr('language')),
              subtitle: Text(
                context.locale.languageCode == 'en'
                    ? 'English'
                    : 'Español',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // SECCIÓN: NOTIFICACIONES
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.tr('notification_settings'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          // Notificaciones Toggle
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(context.tr('notifications')),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  await PreferencesService.setNotificationsEnabled(value);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? context.tr('enable_notifications')
                            : context.tr('disable_notifications'),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('change_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Español'),
              trailing: context.locale.languageCode == 'es'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await context.setLocale(const Locale('es'));
                await PreferencesService.setSelectedLanguage('es');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('language_changed')),
                    ),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: context.locale.languageCode == 'en'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await context.setLocale(const Locale('en'));
                await PreferencesService.setSelectedLanguage('en');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('language_changed')),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }
}
```

### 6. Actualizar HomePage

```dart
// ANTES: HomePage era StatelessWidget
class HomePage extends StatelessWidget {
  const HomePage({super.key});
}

// AHORA: HomePage es StatefulWidget y acepta parámetros
class HomePage extends StatefulWidget {
  final ThemeOption? currentTheme;
  final Function(ThemeOption)? onThemeChanged;

  const HomePage({
    this.currentTheme,
    this.onThemeChanged,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard')),
      ),
      body: Center(
        child: Text(context.tr('hello')),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Al navegar a ProfilePage:
        onTap: (index) {
          if (index == 4) { // Perfil
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  currentTheme: widget.currentTheme,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.sports), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

---

## 🎯 Checklist de Implementación

```
[ ] Copiar y pegar HomePageTemplate
[ ] Copiar y pegar ProfilePageTemplate
[ ] Actualizar imports en HomePage
[ ] Actualizar imports en ProfilePage
[ ] Probar cambio de tema
[ ] Probar cambio de idioma
[ ] Probar toggle de notificaciones
[ ] Verificar persistencia (cerrar/abrir app)
[ ] Revisar que no haya errores de compilación
```

---

**Versión**: 1.0  
**Fecha**: Diciembre 2024  
**Estado**: Ready to Copy-Paste
