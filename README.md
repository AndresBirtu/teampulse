# TeamPulse

Aplicación móvil para la gestión de equipos deportivos desarrollada con Flutter y Firebase.

## Requisitos Previos

- **Flutter SDK**: 3.32.5 o superior
- **Dart**: 3.8.1 o superior
- **Android Studio** con:
  - Android SDK API 34 o superior
  - JDK 17
- **Cuenta de Firebase** con proyecto configurado

## Instalación

### 1. Clonar/Extraer el proyecto

```bash
cd teampulse
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configuración de Firebase

El proyecto ya incluye `google-services.json` en `android/app/`. Si necesitas usar tu propia configuración:

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Habilitar Authentication, Cloud Firestore y Storage
3. Descargar `google-services.json` y reemplazar en `android/app/`

> ⚠️ Costes: evita usar Firebase Storage para pruebas si no es imprescindible. Cargar archivos al bucket puede generar cargos; trabaja en local o con mocks si solo necesitas validar flujos.

### 4. Configurar reglas de Firestore

Las reglas están en `firestore.rules`. Aplicarlas desde Firebase Console o con:

```bash
firebase deploy --only firestore:rules
```

## Ejecución

### En Emulador Android

```bash
flutter run
```

### Generar APK para dispositivo físico

```bash
flutter build apk --release
```

La APK se genera en: `build/app/outputs/flutter-apk/app-release.apk`

Para APK de debug (más rápida):

```bash
flutter build apk --debug
```

### Instalar APK en dispositivo

1. Activar "Fuentes desconocidas" en el dispositivo Android
2. Transferir la APK y abrirla para instalar

O por ADB:

```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## Estructura del Proyecto

```
lib/
├── core/              # Utilidades y widgets compartidos
├── features/          # Módulos por funcionalidad
│   ├── auth/         # Autenticación y registro
│   ├── dashboard/    # Panel principal
│   ├── calendar/     # Calendario de eventos
│   ├── players/      # Gestión de jugadores
│   ├── profile/      # Perfiles de usuario
│   ├── settings/     # Configuración
│   └── stats/        # Estadísticas
├── services/         # Servicios (Firebase, preferencias)
├── theme/            # Temas y estilos
├── widgets/          # Widgets reutilizables
└── main.dart         # Punto de entrada

assets/
└── translations/     # Archivos de internacionalización (es, en)
```

## Características Principales

- ✅ Sistema de autenticación (entrenadores y jugadores)
- ✅ Gestión de equipos y convocatorias
- ✅ Calendario de partidos y entrenamientos
- ✅ Estadísticas individuales y de equipo
- ✅ Sistema de notificaciones
- ✅ Multiidioma (Español/English)
- ✅ Temas personalizables
- ✅ Gestión de lesiones

## Dependencias Principales

- `firebase_core`: ^3.8.0
- `firebase_auth`: ^5.3.3
- `cloud_firestore`: ^5.4.4
- `firebase_storage`: ^12.3.4
- `flutter_riverpod`: ^2.5.1 (gestión de estado)
- `easy_localization`: ^3.0.7 (internacionalización)
- `table_calendar`: ^3.0.9
- `fl_chart`: ^0.69.0

## Usuarios de Prueba

### Entrenador
- Email: marcos01@gmail.com
- Password: marcos01

### Jugador
- Email: jorgeCasado@gmail.com
- Password: jorgec

## Solución de Problemas

### Error al compilar

```bash
flutter clean
flutter pub get
flutter build apk
```

### Problemas con el emulador

Si el emulador se congela o da errores GL, crear uno nuevo:
- Dispositivo: Pixel 5
- API Level: 35
- Graphics: Software - GLES 2.0

## Autor

Proyecto desarrollado como Trabajo de Fin de Grado

## Licencia

Este proyecto es de uso académico.
