# TeamPulse - Guía de Implementación: Temas y Traducción

## 📱 Sistema de Temas Personalizables

### Descripción General
Se ha implementado un sistema completo de temas personalizables que permite a los usuarios elegir entre 8 estilos de colores diferentes. El tema seleccionado se persiste en `SharedPreferences` y se carga automáticamente en futuras sesiones.

### Temas Disponibles

```
1. AZUL (Por defecto)        - Color primario: #03A9F4
2. VERDE                     - Color primario: #4CAF50
3. PÚRPURA                   - Color primario: #9C27B0
4. NARANJA                   - Color primario: #FF9800
5. TEAL                      - Color primario: #009688
6. ROSA                      - Color primario: #E91E63
7. ÍNDIGO                    - Color primario: #3F51B5
8. MARRÓN                    - Color primario: #795548
```

### Estructura de Archivos

```
lib/
├── theme/
│   ├── app_colors.dart          (Paleta base - Mantener para compatibilidad)
│   └── app_themes.dart          (NEW - Temas personalizables)
│
├── services/
│   └── preferences_service.dart (NEW - Persistencia de preferencias)
│
├── widgets/
│   └── theme_selector.dart      (NEW - UI selector de temas)
│
└── main.dart                    (MODIFICADO - Soporte de temas dinámicos)
```

### Arquitectura del Sistema de Temas

#### 1. **PreferencesService** (`preferences_service.dart`)
Servicio singleton que maneja la persistencia de preferencias del usuario:

```dart
// Inicializar en main()
await PreferencesService.initialize();

// Obtener tema seleccionado
ThemeOption theme = PreferencesService.getSelectedTheme();

// Cambiar tema
await PreferencesService.setSelectedTheme(ThemeOption.green);

// Otros métodos
PreferencesService.getSelectedLanguage();
PreferencesService.setSelectedLanguage('en');
PreferencesService.getNotificationsEnabled();
```

#### 2. **AppThemes** (`app_themes.dart`)
Generador centralizado de `ThemeData` dinámicos:

```dart
// Obtener ThemeData para un tema específico
ThemeData theme = AppThemes.getTheme(ThemeOption.purple);

// Obtener gradiente principal
LinearGradient gradient = AppThemes.getPrimaryGradient(ThemeOption.purple);

// Obtener gradiente secundario
LinearGradient secondaryGradient = AppThemes.getSecondaryGradient(ThemeOption.pink);
```

**Características**:
- Material Design 3
- ColorScheme personalizado por tema
- AppBar themes dinámicos
- Input decoration personalizada
- Botones con estilos consistentes
- Bottom navigation bar personalizada
- Card themes
- Dialog themes
- Chip themes

#### 3. **ThemeSelector Widget** (`theme_selector.dart`)
UI para que usuarios seleccionen tema:

```dart
// Dialog modal con grid de 8 temas
showDialog(
  context: context,
  builder: (context) => ThemeSelector(
    currentTheme: currentTheme,
    onThemeChanged: (newTheme) {
      setState(() => _currentTheme = newTheme);
    },
  ),
);

// O usar en ProfilePage directamente
ThemeSettings(
  currentTheme: currentTheme,
  onThemeChanged: onThemeChanged,
)
```

### Uso en MyApp

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeOption _currentTheme;

  @override
  void initState() {
    super.initState();
    // Cargar tema guardado
    _currentTheme = PreferencesService.getSelectedTheme();
  }

  void _changeTheme(ThemeOption theme) {
    setState(() {
      _currentTheme = theme;
    });
    // Guardar cambio
    PreferencesService.setSelectedTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... localizaciones
      theme: AppThemes.getTheme(_currentTheme),  // ← Tema dinámico
      home: HomePage(
        onThemeChanged: _changeTheme,
        currentTheme: _currentTheme,
      ),
    );
  }
}
```

### Integración en HomePage

Necesitas actualizar `HomePage` para aceptar callbacks de tema:

```dart
class HomePage extends StatefulWidget {
  final Function(ThemeOption)? onThemeChanged;
  final ThemeOption? currentTheme;

  const HomePage({
    this.onThemeChanged,
    this.currentTheme,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Pasar al ProfilePage
  ProfilePage(
    onThemeChanged: widget.onThemeChanged,
    currentTheme: widget.currentTheme,
  )
}
```

---

## 🌍 Sistema de Traducción Multiidioma

### Descripción General
Se ha completado la traducción al inglés y se mantiene el soporte completo para español. El sistema usa `EasyLocalization` con archivos `.json` como fuentes.

### Idiomas Soportados

```
- Español (ES)  - Idioma por defecto
- English (EN)  - Idioma secundario
```

### Estructura de Traducciones

```
assets/
└── translations/
    ├── es.json  (170+ claves)
    └── en.json  (170+ claves - COMPLETADO)
```

### Nuevas Claves Agregadas

#### Tema/Apariencia
```json
"theme": "Theme / Tema"
"theme_blue": "Blue (Default) / Azul (Por defecto)"
"theme_green": "Green / Verde"
"theme_purple": "Purple / Púrpura"
"theme_orange": "Orange / Naranja"
"theme_teal": "Teal / Teal"
"theme_pink": "Pink / Rosa"
"theme_indigo": "Indigo / Índigo"
"theme_brown": "Brown / Marrón"
"theme_changed": "Theme changed / Tema cambiado"
"select_theme": "Select a theme / Selecciona un tema"
"appearance": "Appearance / Apariencia"
```

#### Notificaciones
```json
"notifications": "Notifications / Notificaciones"
"notifications_enabled": "Notifications enabled / Notificaciones habilitadas"
"notifications_disabled": "Notifications disabled / Notificaciones deshabilitadas"
"enable_notifications": "Enable notifications / Habilitar notificaciones"
"disable_notifications": "Disable notifications / Deshabilditar notificaciones"
"notification_settings": "Notification Settings / Configuración de notificaciones"
```

### Uso de Traducciones

#### En BuildContext
```dart
String title = context.tr('dashboard');     // "Inicio" / "Home"
String welcome = context.tr('hello');        // "Hola" / "Hello"
```

#### Con parámetros (si aplica)
```dart
String message = context.tr('key', args: ['value1', 'value2']);
```

#### Cambiar idioma dinámicamente
```dart
// Cambiar a Inglés
await context.setLocale(const Locale('en'));

// Cambiar a Español
await context.setLocale(const Locale('es'));

// Obtener idioma actual
String currentLang = context.locale.languageCode; // 'en' o 'es'
```

### Extensión de Traducciones

#### Agregar nueva clave
1. Agregar a `es.json`:
```json
"nueva_clave": "Valor en español"
```

2. Agregar a `en.json`:
```json
"nueva_clave": "Value in English"
```

3. Usar en código:
```dart
Text(context.tr('nueva_clave'))
```

#### Verificar completitud
Ambos archivos `.json` deben tener exactamente las mismas claves para evitar excepciones.

---

## 🎨 Implementación Completa: ProfilePage con Temas e Idioma

Ejemplo de cómo integrar en `ProfilePage`:

```dart
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
      ),
      body: ListView(
        children: [
          // Sección de Apariencia
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('appearance'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          
          // Selector de Tema
          if (widget.currentTheme != null && widget.onThemeChanged != null)
            ThemeSettings(
              currentTheme: widget.currentTheme!,
              onThemeChanged: widget.onThemeChanged!,
            ),
          
          // Selector de Idioma
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.tr('language')),
              subtitle: Text(
                context.locale.languageCode == 'en' 
                    ? 'English' 
                    : 'Español'
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(),
            ),
          ),
          
          // Sección de Notificaciones
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('notification_settings'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          
          // Toggle de Notificaciones
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
                            ? context.tr('notifications_enabled')
                            : context.tr('notifications_disabled')
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
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
              onTap: () async {
                await context.setLocale(const Locale('es'));
                PreferencesService.setSelectedLanguage('es');
                mounted && Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () async {
                await context.setLocale(const Locale('en'));
                PreferencesService.setSelectedLanguage('en');
                mounted && Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔧 Pasos de Integración

### 1. Actualizar main.dart ✅
Ya completado. Proporciona:
- Inicialización de `PreferencesService`
- `MyApp` como `StatefulWidget` con manejo de temas
- Callbacks de cambio de tema

### 2. Actualizar HomePage
```dart
class HomePage extends StatefulWidget {
  final Function(ThemeOption)? onThemeChanged;
  final ThemeOption? currentTheme;

  const HomePage({
    this.onThemeChanged,
    this.currentTheme,
    super.key,
  });
}
```

### 3. Actualizar/Crear ProfilePage
Integrar `ThemeSettings` y `_showLanguageDialog()` como se mostró arriba.

### 4. Usar traducciones
En todas las páginas:
```dart
Text(context.tr('clave'))
```

---

## 📊 Checklist de Implementación

- [x] Crear `AppThemes` con 8 temas diferentes
- [x] Crear `PreferencesService` para persistencia
- [x] Crear `ThemeSelector` widget
- [x] Actualizar `main.dart`
- [x] Completar traducciones al inglés
- [x] Agregar claves de tema/apariencia
- [ ] Actualizar `HomePage` (debes hacerlo)
- [ ] Integrar `ProfilePage` con tema/idioma
- [ ] Probar cambios de tema en tiempo real
- [ ] Probar persistencia de preferencias

---

## 🐛 Troubleshooting

### "El tema no persiste al cerrar la app"
→ Asegúrate que `PreferencesService.initialize()` se llama en `main()`

### "Las traducciones muestran 'en.key' en lugar del texto"
→ Verifica que la clave existe en AMBOS archivos `.json`

### "El cambio de tema no se aplica inmediatamente"
→ Llama `setState(() {})` o `notifyListeners()` en el widget padre

### "SharedPreferences falla en tests"
→ Mock `PreferencesService` en tus tests unitarios

---

## 📚 Referencias

- **AppThemes**: `lib/theme/app_themes.dart`
- **PreferencesService**: `lib/services/preferences_service.dart`
- **ThemeSelector**: `lib/widgets/theme_selector.dart`
- **Traducciones ES**: `assets/translations/es.json`
- **Traducciones EN**: `assets/translations/en.json`
- **Main.dart actualizado**: `lib/main.dart`

---

**Versión**: 1.0  
**Fecha**: Diciembre 2024  
**Estado**: Listo para integración en HomePage y ProfilePage
