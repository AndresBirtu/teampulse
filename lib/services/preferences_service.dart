import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../theme/app_themes.dart';

/// Servicio para manejar preferencias de usuario (Idioma, Tema, etc.)
class PreferencesService {
  static const String _themeKey = 'selected_theme';
  static const String _languageKey = 'selected_language';
  static const String _notificationsKey = 'notifications_enabled';
  
  static late SharedPreferences _prefs;
  static bool _initialized = false;
  
  // StreamController para notificar cambios de tema
  static final _themeController = StreamController<ThemeOption>.broadcast();
  static Stream<ThemeOption> get themeStream => _themeController.stream;

  /// Inicializar el servicio
  static Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Obtener el tema seleccionado
  static ThemeOption getSelectedTheme() {
    _ensureInitialized();
    final themeName = _prefs.getString(_themeKey) ?? ThemeOption.blue.name;
    try {
      return ThemeOption.values.byName(themeName);
    } catch (e) {
      return ThemeOption.blue; // Default
    }
  }

  /// Guardar el tema seleccionado
  static Future<void> setSelectedTheme(ThemeOption theme) async {
    _ensureInitialized();
    await _prefs.setString(_themeKey, theme.name);
    // Emitir el cambio en el stream
    _themeController.add(theme);
  }

  /// Obtener idioma seleccionado
  static String getSelectedLanguage() {
    _ensureInitialized();
    return _prefs.getString(_languageKey) ?? 'es';
  }

  /// Guardar idioma seleccionado
  static Future<void> setSelectedLanguage(String languageCode) async {
    _ensureInitialized();
    await _prefs.setString(_languageKey, languageCode);
  }

  /// Obtener estado de notificaciones
  static bool getNotificationsEnabled() {
    _ensureInitialized();
    return _prefs.getBool(_notificationsKey) ?? true;
  }

  /// Guardar estado de notificaciones
  static Future<void> setNotificationsEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs.setBool(_notificationsKey, enabled);
  }

  /// Validar que el servicio esté inicializado
  static void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'PreferencesService no inicializado. '
        'Llama a PreferencesService.initialize() en main.dart'
      );
    }
  }

  /// Limpiar todas las preferencias (para logout)
  static Future<void> clearAll() async {
    _ensureInitialized();
    await _prefs.clear();
  }
}
