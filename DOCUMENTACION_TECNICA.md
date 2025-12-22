# TeamPulse - Documentación Técnica

## 📋 Tabla de Contenidos
1. [Arquitectura de Sistemas](#arquitectura-de-sistemas)
2. [Diagrama de Componentes](#diagrama-de-componentes)
3. [UX (Experiencia de Usuario)](#ux-experiencia-de-usuario)
4. [UI (Interfaz de Usuario)](#ui-interfaz-de-usuario)
5. [IxD (Interacción de Diseño)](#ixd-interacción-de-diseño)

---

## 🏗️ Arquitectura de Sistemas

### Visión General
TeamPulse sigue una arquitectura **feature-first** con capas limpias y ligeras. Cada funcionalidad (players, matches, trainings, dashboard, etc.) posee sus propias carpetas `presentation/domain/data`. La capa de presentación implementa **MVVM** apoyándose en **Riverpod** (`StateNotifier` y `AsyncNotifier`) para la gestión de estado y la inyección de dependencias. El dominio contiene entidades y casos de uso puros (sin Flutter), mientras que la capa de datos implementa los repositorios hablando con Firebase.

### Principios aplicados
- **Feature-first**: agrupa código por contexto funcional para aislar responsabilidades y facilitar la evolución del TFG.
- **MVVM con Riverpod**: Widgets (View) consumen ViewModels `StateNotifier`, que a su vez orquestan casos de uso.
- **Clean Architecture ligera**: solo tres capas claras (presentation, domain, data) con dependencias apuntando hacia el dominio.
- **Inyección declarativa**: Riverpod provee datasources → repositorios → casos de uso → viewmodels, lo que mejora testabilidad.
- **Enfoque práctico**: se evita la sobreingeniería; solo se añaden interfaces y casos de uso cuando aportan valor directo.

### Capas de Arquitectura

```
┌──────────────────────────────────────────────────────────────┐
│                  CAPA DE PRESENTACIÓN (Features)             │
│  - Widgets + ViewModels (MVVM con Riverpod)                  │
│  - Providers por feature: Dashboard, Players, Matches, etc.  │
└──────────────────────┬───────────────────────────────────────┘
                  │ consume casos de uso                 
                  ▼
┌──────────────────────────────────────────────────────────────┐
│                       CAPA DE DOMINIO                        │
│  - Entidades puras (Match, Player, Training)                 │
│  - Casos de uso (FetchMatches, UpdateAvailability, etc.)     │
│  - Interfaces de repositorio                                │
└──────────────────────┬───────────────────────────────────────┘
                  │ es implementado por                  
                  ▼
┌──────────────────────────────────────────────────────────────┐
│                    CAPA DE DATOS (Firebase)                  │
│  - Repositorios concretos (Firestore/Storage/Auth)           │
│  - DataSources remotos y DTOs                               │
│  - Adaptadores a APIs de Firebase                           │
└──────────────────────────────────────────────────────────────┘
```

Cada feature mantiene este mismo patrón interno `presentation/domain/data`, lo que permite trabajar modularmente y escalar la app sin afectar al resto de módulos.

### Flujo de Datos

```
Usuario ──▶ [Widget/Feature] ──▶ [Riverpod ViewModel]
   │                             │        │
   │                             │        ▼
   │                             │  [Caso de uso]
   │                             │        │
   │                             │        ▼
   │                             │  [Repositorio]
   │                             │        │
   │                             └────────▼
   │                           [Firestore / Storage]
   │                                      │
   └──────────────────────────────────────┘
           (Estados AsyncValue y listeners)
```

### Justificación para el TFG
- **Claridad académica**: se puede explicar con los principios de Clean Architecture e MVVM.
- **Compatibilidad con Flutter**: Riverpod elimina dependencias del `BuildContext`, simplificando la UI.
- **Testabilidad**: los casos de uso y ViewModels pueden probarse aislados gracias a la inversión de dependencias.
- **Escalabilidad modular**: agregar una nueva feature implica replicar el mismo esqueleto sin tocar las existentes.

### Tecnologías de Backend

| Componente | Tecnología | Propósito |
|-----------|-----------|----------|
| **Base de Datos** | Cloud Firestore | Almacenamiento NoSQL de usuarios, equipos, partidos, entrenamientos |
| **Autenticación** | Firebase Authentication | Gestión de usuarios (registro, login, verificación) |
| **Notificaciones** | Firebase Cloud Messaging (FCM) | Notificaciones push en tiempo real |
| **Almacenamiento** | Firebase Cloud Storage | Imágenes de perfil de jugadores |
| **Seguridad** | Firestore Security Rules | Control de acceso basado en roles (entrenador/jugador) |

### Estructura de Base de Datos (Firestore)

```
firestore/
├── users/
│   └── {userId}
│       ├── email: string
│       ├── name: string
│       ├── role: "entrenador" | "jugador"
│       ├── teamId: string
│       ├── teamName: string
│       └── createdAt: timestamp
│
├── teams/
│   └── {teamId}
│       ├── name: string
│       ├── ownerId: string (coach)
│       ├── coachId: string
│       ├── teamCode: string (código de invitación)
│       ├── createdAt: timestamp
│       ├── players/ (subcollection)
│       │   └── {playerId}
│       │       ├── name: string
│       │       ├── email: string
│       │       ├── position: "Portero" | "Cierre" | "Pivot" | "Ala"
│       │       ├── role: "entrenador" | "jugador"
│       │       ├── goles: number
│       │       ├── asistencias: number
│       │       ├── minutos: number
│       │       ├── injured: boolean
│       │       └── photoUrl: string
│       │
│       ├── matches/ (subcollection)
│       │   └── {matchId}
│       │       ├── rival: string
│       │       ├── date: timestamp
│       │       ├── location: string
│       │       ├── played: boolean
│       │       ├── golesTeamA: number
│       │       ├── golesTeamB: number
│       │       ├── convocados: array<userId>
│       │       ├── stats/ (subcollection)
│       │       │   └── {statId}
│       │       │       ├── playerId: string
│       │       │       ├── goles: number
│       │       │       ├── asistencias: number
│       │       │       └── minutos: number
│       │       │
│       │       └── availability/ (subcollection)
│       │           └── {playerId}
│       │               ├── available: boolean
│       │               └── date: timestamp
│       │
│       └── trainings/ (subcollection)
│           └── {trainingId}
│               ├── date: timestamp
│               ├── notes: string
│               └── playersState: map<playerId, attendance>
```

### Seguridad (Firestore Rules)

- **Autenticación requerida**: Todas las operaciones requieren `auth != null`
- **Control por Rol**:
  - **Entrenador**: Crear/editar partidos, entrenamientos, jugadores
  - **Jugador**: Ver equipo, marcar disponibilidad, actualizar perfil
- **Privacidad de datos**: Los usuarios solo ven datos de su equipo (`teamId` matching)

---

## 🔧 Diagrama de Componentes

### Componentes Principales

```
┌───────────────────────────────────────────────────────────────────┐
│                       MyApp (Widget Raíz)                         │
│  - MaterialApp con tema global                                    │
│  - EasyLocalization para i18n                                     │
└──────────────────────────┬──────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
    ┌────────────┐  ┌──────────────┐  ┌──────────────┐
    │  HomePage  │  │  DashboardPage  │  │  Theme Colors  │
    │ (Auth Flow)│  │  (Hub Central)  │  │  & Gradients   │
    └────────────┘  └──────────────┘  └──────────────┘
        │                  │
        │      ┌───────────┼───────────┐
        │      │           │           │
        ▼      ▼           ▼           ▼
    ┌─────────┐ ┌───────────────┐ ┌────────────┐ ┌─────────────┐
    │ PlayersPage │ │ MatchesPage   │ │ CalendarPage │ │ TrainingsPage │
    │ (Gestión)   │ │ (Partidos)    │ │ (Vista Gral) │ │ (Entrenamientos)
    └─────────┘ └───────────────┘ └────────────┘ └─────────────┘
        │           │               │               │
        └───────────┴───────────────┴───────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
    ┌────────────────┐   ┌─────────────────┐
    │ Firebase Auth  │   │ Firestore       │
    │ (Autenticación)│   │ (Base de Datos) │
    └────────────────┘   └─────────────────┘
```

### Componentes por Página

#### 1. **HomePage** (Autenticación)
- **Tabs**: Login / Registro
- **Widgets hijos**:
  - `_LoginTab`: Formulario de login
  - `_RegisterTab`: Formulario de registro (Entrenador/Jugador)

#### 2. **DashboardPage** (Hub Central)
- **Elementos principales**:
  - Tarjeta de saludo con avatar
  - **`_NextMatchCard`**: Widget animado del próximo partido
  - Stats del equipo (Jugados, Ganados, Perdidos)
  - Contador días hasta próximo partido
  - Racha de victorias
  - Jugador destacado del mes
  - Secciones personalizadas (Entrenador vs Jugador)

#### 3. **PlayersPage** (Gestión de Jugadores)
- **Componentes**:
  - Filtrado por posición (Portero, Cierre, Pivot, Ala)
  - Ordenamiento (Nombre A-Z, Z-A, Posición)
  - Cards de jugadores con:
    - Avatar
    - Nombre, Posición
    - Stats (Goles, Asistencias)
    - Estado lesión
    - Botones: Editar, Lesión, Eliminar

#### 4. **MatchesPage** (Partidos)
- **Componentes**:
  - Lista de partidos por fecha
  - Botón FAB "+" para crear partido
  - Cards por partido:
    - Rival vs Nuestro equipo
    - Fecha/Hora
    - Ubicación
    - Resultado (si jugado)
    - Botones: Editar, Estadísticas, Disponibilidad
    - Botón Eliminar (solo entrenador)

#### 5. **CalendarPage** (Calendario)
- **Componentes**:
  - Calendario interactivo
  - Visualización de partidos y entrenamientos
  - Indicadores de eventos

#### 6. **TrainingsPage** (Entrenamientos)
- **Componentes**:
  - Lista de entrenamientos
  - Formulario para crear/editar
  - Selector de asistencia de jugadores

### Diagrama de Flujo de Componentes

```
[Usuario Inicia App]
        ↓
[HomePage - Autenticación]
        ↓
[DashboardPage - Hub Central]
        ├─────────────────────────────────────────┐
        │                                         │
        ▼                                         ▼
[Vista Entrenador]                      [Vista Jugador]
├─ PlayersPage                          ├─ PlayersPage (readonly)
├─ MatchesPage (CRUD)                   ├─ MatchesPage (view)
├─ TrainingsPage (CRUD)                 ├─ TrainingsPage (view)
├─ CalendarPage                         ├─ CalendarPage
└─ Team Management                      └─ Player Profile
```

---

## 👥 UX (Experiencia de Usuario)

### Principios de Diseño UX
1. **Intuitividad**: Navegación clara y predecible
2. **Eficiencia**: Minimizar clics para tareas comunes
3. **Accesibilidad**: Texto legible, contraste adecuado
4. **Coherencia**: Diseño consistente en toda la app
5. **Feedback**: Respuestas inmediatas a acciones del usuario

### Journey Map: Entrenador

```
┌─────────────────────────────────────────────────────────────────┐
│ JOURNEY: Entrenador creando equipo y gestionando primer partido │
└─────────────────────────────────────────────────────────────────┘

1. DESCUBRIMIENTO (Pain point: "¿Cómo inicio?")
   └─ Abre app → Ve tabs Login/Registro
   
2. REGISTRO (Pain point: "¿Qué datos necesito?")
   └─ Selecciona "Entrenador"
   └─ Ingresa: Nombre, Email, Contraseña
   └─ Ingresa: Nombre del equipo
   └─ Sistema genera código de equipo automáticamente
   └─ ✓ Cuenta creada

3. DASHBOARD (Pain point: "¿Qué hago ahora?")
   └─ Ve saludo personalizado
   └─ Ve stats vacías (0 partidos, 0 goles)
   └─ Ve botones principales claros

4. CREAR EQUIPO (Pain point: "¿Cómo agrego jugadores?")
   └─ Click en "Ver Jugadores"
   └─ Ve botón "Invitar" prominent
   └─ Comparte código de equipo (AAA123)
   └─ ✓ Jugadores pueden unirse

5. CREAR PARTIDO (Pain point: "¿Dónde registro partidos?")
   └─ Click en "Partidos"
   └─ Click en "+" FAB
   └─ Ingresa: Rival, Fecha, Hora, Ubicación
   └─ ✓ Partido creado

6. CONFIRMAR DISPONIBILIDAD (Pain point: "¿Quién juega?")
   └─ Click en partido
   └─ Ve lista de jugadores
   └─ Marca disponibilidad
   └─ ✓ Disponibilidades confirmadas

7. REGISTRAR RESULTADO (Pain point: "¿Cómo registro goles?")
   └─ Después del partido: Editar → Marcar "Jugado"
   └─ Ingresa goles del equipo A/B
   └─ Click en "Estadísticas del Partido"
   └─ Ingresa: Goles, Asistencias, Minutos por jugador
   └─ ✓ Stats registradas
```

### Journey Map: Jugador

```
┌─────────────────────────────────────────────────────────────────┐
│ JOURNEY: Jugador uniéndose a equipo y siguiendo partidos        │
└─────────────────────────────────────────────────────────────────┘

1. REGISTRO (Pain point: "¿Cómo me uno?")
   └─ Abre app
   └─ Selecciona "Jugador"
   └─ Ingresa: Nombre, Email, Contraseña
   └─ Ingresa: Código del equipo (AAA123)
   └─ ✓ Se une al equipo

2. DASHBOARD (Pain point: "¿Qué puedo ver?")
   └─ Ve saludo personalizado
   └─ Ve mis stats personales
   └─ Ve próximo partido destacado (TU EQUIPO vs RIVAL)
   └─ Ve fecha y ubicación del próximo partido

3. PRÓXIMO PARTIDO (Pain point: "¿Debo ir?")
   └─ Click en partido
   └─ Confirma su disponibilidad (Disponible/No disponible)
   └─ Ve lista de convocados
   └─ ✓ Disponibilidad confirmada

4. VER RESULTADO (Pain point: "¿Cómo fue?")
   └─ Después del partido: Click en partido
   └─ Ve resultado final
   └─ Ve sus stats personales (goles, asistencias, minutos)
   └─ Ve stats de equipo

5. PERFIL (Pain point: "¿Cómo veo mi desempeño?")
   └─ Click en perfil
   └─ Ve sus stats totales de temporada
   └─ Puede actualizar foto de perfil
   └─ Puede editar posición
```

### User Personas

#### Persona 1: Carlos (Entrenador)
- **Edad**: 45 años
- **Experiencia**: Entrenador con 15 años de experiencia
- **Objetivo**: Organizar entrenamientos y partidos de forma sencilla
- **Pain Points**: 
  - Difícil seguimiento manual de asistencia
  - No puede acceder a estadísticas en tiempo real
  - Coordinar equipos es tedioso
- **Solución**: Dashboard centralizado, gestión de jugadores, registro de stats

#### Persona 2: Miguel (Jugador)
- **Edad**: 22 años
- **Experiencia**: Jugador amateur
- **Objetivo**: Estar informado sobre partidos y seguir su desempeño
- **Pain Points**:
  - Olvida fechas de partidos
  - No ve su progreso personal
  - Debe preguntar si está convocado
- **Solución**: Notificaciones, stats personales, vista de próximo partido destacada

### Escenarios de Uso Críticos

| Escenario | Actor | Acción | Resultado Esperado |
|-----------|-------|--------|-------------------|
| Crear partido urgente | Entrenador | Click MatchesPage → FAB | Partido creado en < 30s |
| Ver próximo partido | Jugador | Abrir DashboardPage | Tarjeta destacada visible |
| Confirmar disponibilidad | Jugador | Click en partido → Toggle | Disponibilidad guardada al instante |
| Registrar stats | Entrenador | MatchPage → Estadísticas | Datos guardados con validación |
| Invitar jugador | Entrenador | Click Invitar → Copiar código | Código en portapapeles |

---

## 🎨 UI (Interfaz de Usuario)

### Paleta de Colores

```
├─ PRIMARY (Azul)
│  ├─ Primary: #1976D2
│  ├─ Dark: #1565C0
│  └─ Gradient: Linear(#1976D2 → #1565C0)
│
├─ SECONDARY (Verde)
│  ├─ Secondary: #4CAF50
│  ├─ Light: #66BB6A
│  └─ Gradient: Linear(#4CAF50 → #388E3C)
│
├─ ACCENT (Naranja)
│  ├─ Accent: #FF9800
│  └─ Light: #FFB74D
│
├─ BACKGROUNDS
│  ├─ Background: #F5F5F5
│  ├─ Surface: #FFFFFF
│  └─ Card: #FFFFFF
│
├─ TEXT
│  ├─ Primary: #212121
│  ├─ Secondary: #757575
│  └─ On Primary: #FFFFFF
│
└─ STATUS
   ├─ Success: #4CAF50
   ├─ Error: #F44336
   ├─ Warning: #FFC107
   └─ Info: #2196F3
```

### Tipografía

```
ESTILOS DE FUENTE (Flutter Theme):

display-large: 57sp, bold           (Títulos principales)
headline-large: 32sp, bold          (Títulos de sección)
headline-medium: 28sp, bold         (Subtítulos)
title-large: 22sp, w500             (Títulos de cards)
body-large: 16sp, regular           (Texto principal)
body-medium: 14sp, regular          (Texto secundario)
label-large: 14sp, w500             (Labels, botones)
label-small: 12sp, regular          (Hints, helper text)

APLICACIÓN EN APP:
- Saludo: headline-large (#1976D2)
- Títulos página: title-large (#212121)
- Valores stats: display-medium, bold
- Textos cards: body-medium
```

### Componentes UI Principales

#### 1. **AppBar (Header)**
```
┌─────────────────────────────────────┐
│ [≡] Título Página [⚙] [🌐]          │  ← Gradient Blue
└─────────────────────────────────────┘
  Altura: 56dp
  Gradient: PRIMARY → PRIMARY_DARK
  Elevation: 4dp
  Elementos:
  - Menu hamburguesa (izq)
  - Título centrado
  - Icono idioma (🌐)
  - Icono configuración (⚙)
```

#### 2. **StatCard** (Cards de Estadísticas)
```
┌──────────────────┐
│ [ICON] LABEL     │  ← Fondo Gradiente
│      VALOR       │     (Color por tipo)
└──────────────────┘
  Dimensiones: Full width / 3 (en row)
  Padding: 12dp
  BorderRadius: 12dp
  Elevation: 2dp
  Estilos:
  - Orange (Jugados)
  - Green (Ganados)  
  - Red (Perdidos)
```

#### 3. **_NextMatchCard** (Tarjeta de Próximo Partido) ⭐
```
┌────────────────────────────────────┐
│ PRÓXIMO PARTIDO                  [✕] │
│ Tu Equipo vs Rival                  │
├────────────────────────────────────┤
│ [📅] FECHA        [⏰] HORA        │
│  25/12/2024        19:30            │
├────────────────────────────────────┤
│ [📍] UBICACIÓN                      │
│ Estadio Municipal, Cancha 2        │
└────────────────────────────────────┘
  Gradient: PRIMARY → PRIMARY_DARK
  BorderRadius: 16dp
  Padding: 16dp
  Box shadow: elevation 8dp
  Elementos interactivos:
  - Botón X cerrar (top-right)
  - Texto nombre rival destacado (32sp, bold)
```

#### 4. **PlayerCard** (Card de Jugador)
```
┌──────────────────────────────┐
│ [AVATAR] Nombre Jugador  [▼] │
│ Posición: Delantero          │
│ Goles: 5 | Asistencias: 2   │
│ [Editar] [Lesión] [Eliminar] │
└──────────────────────────────┘
  Padding: 12dp
  BorderRadius: 12dp
  Elevation: 1dp
  ColorBorder: Si está lesionado (rojo)
```

#### 5. **MatchCard** (Card de Partido)
```
┌──────────────────────────────────────┐
│ Rival: Barcelona                     │
│ 25 Dic 2024 | 19:30 | Estadio Unidad│
│ [Ver Stats] [Disponibilidad] [Editar]│
│                                 [🗑️] │
└──────────────────────────────────────┘
  Color: Azul si no jugado, Gris si jugado
  Si jugado: Muestra resultado (3-1)
```

#### 6. **FAB (Floating Action Button)**
```
       ┌─────┐
       │  +  │  ← Fondo PRIMARY
       └─────┘
       
  Posición: Bottom-Right corner
  Tamaño: 56dp
  Color: PRIMARY (#1976D2)
  Icono: Icons.add (blanco)
  Elevation: 8dp
  onPressed: Navega a formulario crear
```

#### 7. **BottomNavigation**
```
┌──────────────────────────────────────┐
│ [🏠] [📅] [⚽] [📊] [👤]            │
│ Inicio | Cal | Part | Stats | Perfil │
└──────────────────────────────────────┘
  Altura: 64dp
  Items: 5 (variable por rol)
  Active color: PRIMARY
  Inactive color: GREY
  Etiquetas: Visibles en mobile
```

### Espaciado (8dp Grid System)

```
Espacios base: 4dp, 8dp, 12dp, 16dp, 24dp, 32dp, 48dp

Aplicación:
- Padding exterior: 16dp
- Padding interno cards: 12dp
- Spacing entre elementos: 8-12dp
- Spacing entre secciones: 24-32dp
- Gap en listas: 8dp
```

### Breakpoints (Responsive Design)

```
Mobile (< 600dp):     - Single column layouts
Tablet (600-1200dp):  - 2 column layouts
Desktop (> 1200dp):   - 3+ column layouts

La app TEAMPLATE está optimizada para MOBILE primary
```

---

## 🎯 IxD (Interacción de Diseño)

### Patrones de Interacción

#### 1. **Navegación Primaria**
```
TIPO: Bottom Tab Navigation
TRIGGER: Click en icono
COMPORTAMIENTO:
- Transición suave (300ms)
- Mantiene scroll position en pages
- Active tab resaltado en PRIMARY color

ESTRUCTURA:
Home → Calendario → Partidos → Stats → Perfil
```

#### 2. **Creación de Contenido (FAB)**
```
TIPO: Floating Action Button
TRIGGER: Click en + flotante
COMPORTAMIENTO:
- Navega a formulario nueva página
- Al regresar: Recarga lista con nuevo item
- Muestra confirmación (SnackBar)

UBICACIONES:
- MatchesPage: Crear partido
- TrainingsPage: Crear entrenamiento
- PlayersPage: Agregar jugador
```

#### 3. **Edición Inline**
```
TIPO: Card con opciones contextuales
TRIGGER: Tap en card → Botón "Editar"
COMPORTAMIENTO:
- Abre modal/página de edición
- Al guardar: Actualiza en tiempo real
- Muestra loading indicator durante save

CAMPOS EDITABLES:
- Nombre jugador
- Posición
- Goles/Asistencias
- Foto perfil
- Disponibilidad
```

#### 4. **Confirmación de Acciones Destructivas**
```
TIPO: AlertDialog con 2 botones
TRIGGER: Click en icono 🗑️ (eliminar)
COMPORTAMIENTO:
- Muestra diálogo con advertencia
- Botones: "Cancelar" y "Eliminar"
- Si confirma: Borra registro y actualiza UI
- Muestra snackbar: "Eliminado con éxito"

EJEMPLO:
┌──────────────────────────────────┐
│ ¿Eliminar este jugador?          │
│ Esta acción no se puede deshacer  │
│                                  │
│ [Cancelar]      [Eliminar]       │
└──────────────────────────────────┘
```

#### 5. **Feedback en Tiempo Real (StreamBuilder)**
```
TIPO: Reactive updates
TRIGGER: Cambios en Firestore
COMPORTAMIENTO:
- Listener activo en background
- UI actualiza sin refresh manual
- Transiciones suaves entre estados

EJEMPLO - Lista de Jugadores:
[Cargando...]
   ↓ (datos llegan)
[Mostrar 8 jugadores]
   ↓ (entrenador agrega jugador desde otra pestaña)
[Mostrar 9 jugadores] ← Aparece nuevo automáticamente
```

#### 6. **Manejo de Errores**
```
TIPO: SnackBar + Retry Logic
COMPORTAMIENTO:
- Error de red: "Error de conexión. ¿Reintentar?"
- Error autenticación: "Sesión expirada. Inicia sesión"
- Error validación: "Debes llenar todos los campos"
- Error base datos: "Error guardando. Reintentando..."

DURACIÓN:
- Errores críticos: 5 segundos
- Mensajes normales: 3 segundos
- Confirmaciones: 2 segundos
```

#### 7. **Animaciones**

##### **_NextMatchCard** (Aparición)
```
TIPO: Scale + Fade In
DURACIÓN: 600ms
CURVA: elasticOut (rebote)
EFECTO:
  Escala: 0.8 → 1.0 (elasticOut)
  Opacidad: 0.0 → 1.0 (easeIn)
  
RESULTADO: Tarjeta "salta" al aparecer con efecto de rebote
```

##### **Card Hover/Tap**
```
TIPO: Elevation change
DURACIÓN: 200ms
COMPORTAMIENTO:
  - Normal: elevation 1dp
  - Hover: elevation 4dp
  - Pressed: elevation 8dp, slight scale down (0.98)
```

##### **Lista Transition**
```
TIPO: Fade + Slide para items nuevos
COMPORTAMIENTO:
  - Items nuevos aparecen con slide-in desde abajo
  - Items eliminados fade-out
  - Duración: 300ms
```

### Gesturas y Controles

| Gesto | Elemento | Acción |
|-------|----------|--------|
| **Tap** | Botón | Navega o ejecuta acción |
| **Tap** | Card jugador | Abre detalles/edición |
| **Tap** | Card partido | Muestra opciones (Stats, Editar) |
| **Long Press** | Card | Muestra menú contextual (Editar, Eliminar) |
| **Swipe Down** | Page | Pull-to-Refresh (recargar datos) |
| **Swipe Left** | Lista | Revelar botón eliminar (optional) |
| **Double Tap** | Icono ❤️ | Like/Marcar favorito |

### Estados de Componentes

#### **Button States**
```
┌─ ENABLED
│  ├─ Normal: Background PRIMARY, texto BLANCO
│  └─ Hover: Slight elevation increase
│
├─ DISABLED
│  ├─ Background: GREY_LIGHT
│  └─ Texto: GREY_DARK (50% opacity)
│
├─ LOADING
│  ├─ Muestra circular progress
│  └─ Texto: "Guardando..."
│
└─ SUCCESS
   ├─ Background: GREEN
   └─ Icono: ✓ check
```

#### **Input Field States**
```
┌─ EMPTY
│  ├─ Border: GREY_LIGHT
│  └─ Label: Floating hint
│
├─ FOCUSED
│  ├─ Border: PRIMARY (3dp)
│  ├─ Fondo: PRIMARY (5% opacity)
│  └─ Label: PRIMARY color
│
├─ FILLED
│  ├─ Border: GREY
│  └─ Texto: PRIMARY_TEXT color
│
├─ ERROR
│  ├─ Border: RED (3dp)
│  ├─ Fondo: RED (5% opacity)
│  └─ Helper text: RED con icono ⚠️
│
└─ DISABLED
   ├─ Fondo: GREY (10% opacity)
   └─ Texto: GREY_DARK
```

#### **List Item States**
```
┌─ DEFAULT
│  └─ Elevation: 1dp
│
├─ HOVER (Desktop)
│  ├─ Elevation: 4dp
│  └─ Background: PRIMARY (5% opacity)
│
├─ SELECTED
│  ├─ Checkmark visible
│  ├─ Background: PRIMARY (10% opacity)
│  └─ Border left: PRIMARY (4dp)
│
└─ DISABLED
   ├─ Opacity: 50%
   └─ No interactable
```

### Flujos de Interacción Complejos

#### **Flujo: Crear y Registrar Partido**

```
Dashboard
   ↓ (Click "Partidos")
MatchesPage
   ↓ (Click FAB "+")
CreateMatchPage (Formulario)
   ├─ Input: Rival
   ├─ Input: Fecha [Calendario]
   ├─ Input: Hora [TimePicker]
   ├─ Input: Ubicación
   └─ Button: Crear
      ↓
   [Loading...]
      ↓
   Firestore.save()
      ↓
   ✓ Éxito → SnackBar "Partido creado"
      ↓
   Vuelve a MatchesPage
      ↓
   StreamBuilder recibe nuevo partido
      ↓
   UI actualiza automáticamente
```

#### **Flujo: Confirmar Disponibilidad**

```
DashboardPage
   ↓ (Click tarjeta "Próximo Partido")
MatchesPage Detail
   ├─ Ver rival, fecha, ubicación
   ├─ Ver lista de jugadores
   └─ Click en nombre → Disponible/No Disponible
      ↓
   [Guardando...]
      ↓
   Firestore.availability.update()
      ↓
   ✓ Disponibilidad guardada
      ↓
   Lista se actualiza (checkmark o X)
```

#### **Flujo: Registrar Estadísticas de Partido**

```
MatchesPage
   ├─ Click en partido (después de jugado)
   └─ Click "Estadísticas del Partido"
      ↓
   MatchStatsEditor
   ├─ Para cada jugador:
   │  ├─ Goles (spinner)
   │  ├─ Asistencias (spinner)
   │  ├─ Minutos (spinner)
   │  └─ Tarjetas (yellow/red)
   │
   └─ Button: Guardar
      ↓
   [Validar datos...]
      ↓
   Firestore.batch.update() [múltiples writes]
      ↓
   ✓ Stats guardadas
      ↓
   Vuelve a MatchesPage
      ↓
   Lista se actualiza con resultado
```

### Accesibilidad (A11y)

#### **Contraste y Legibilidad**
- Texto pequeño (< 12sp): Contraste mínimo 7:1
- Texto grande (≥ 18sp): Contraste mínimo 4.5:1
- Botones: Mínimo 48dp x 48dp (tappable area)

#### **Navegación**
- Labels claros en todos los botones
- Orden de tabulación lógico
- Navegación por teclado completa (web)
- Focus visible en todos elementos interactivos

#### **Semántica**
- `Semantics` labels en widgets importantes
- `Tooltip` en iconos sin texto
- `alt text` implícito en imágenes
- Estructura jerárquica clara (h1, h2, h3)

### Responsive Design

#### **Puntos de Quiebre**

```
Mobile (< 600dp):
├─ Single column layouts
├─ Full width cards
├─ Bottom navigation (BottomAppBar)
├─ Modals/Drawers para opciones
└─ FAB visible

Tablet (600-1200dp):
├─ 2 column layouts (opcional)
├─ Drawer sidebar para nav
├─ Dialogs para forms
└─ Adjusted padding

Desktop (> 1200dp):
├─ 3 column layouts
├─ Horizontal navigation
├─ Split view for details
└─ Hover states
```

#### **Ejemplo: PlayersPage Responsive**

```
Mobile (< 600dp):
┌───────────┐
│ Jugador 1 │
├───────────┤
│ Jugador 2 │
├───────────┤
│ Jugador 3 │
└───────────┘

Tablet (600-1200dp):
┌──────────────────┐
│ Jug 1  │  Jug 2  │
├────────┼─────────┤
│ Jug 3  │  Jug 4  │
└────────┴─────────┘

Desktop (> 1200dp):
┌──────────────────────────────┐
│ Jug 1 │ Jug 2 │ Jug 3 │ Jug 4│
├───────┼───────┼───────┼──────┤
│ Jug 5 │ Jug 6 │ Jug 7 │ Jug 8│
└───────┴───────┴───────┴──────┘
```

---

## 📊 Matriz de Componentes y Responsabilidades

| Componente | Responsabilidad | Estado | Props | Eventos |
|-----------|----------------|--------|-------|---------|
| **HomePage** | Autenticación, Login/Registro | Stateful | - | Auth flow |
| **DashboardPage** | Hub central, stats equipo | Stateful | teamId, role | Navigation |
| **_NextMatchCard** | Mostrar próximo partido | Stateful | teamId | Hide action |
| **PlayersPage** | CRUD jugadores, filtrado | Stateful | teamId | Edit, Delete |
| **MatchesPage** | CRUD partidos, lista | Stateless | teamId | Create, Edit |
| **CreateMatchPage** | Formulario nuevo partido | Stateful | teamId | Save |
| **TrainingsPage** | CRUD entrenamientos | Stateless | teamId | Create, Edit |
| **CalendarPage** | Vista calendario eventos | Stateless | teamId | - |
| **TeamStatsPage** | Stats equipo por posición | Stateless | teamId | - |
| **PlayerProfilePage** | Perfil jugador, edición | Stateful | playerId | Save |

---

## 🎓 Conclusión

TeamPulse implementa una arquitectura moderna con:
- **Backend flexible**: Firebase para scalabilidad
- **UI intuitiva**: Material Design 3 con gradientes
- **Interacciones fluidas**: Animaciones y feedback realtime
- **Diseño accesible**: Accesibilidad integrada
- **Responsive**: Adaptable a móvil, tablet y desktop

---

**Versión**: 1.0  
**Fecha**: Diciembre 2024  
**Autores**: Equipo de Desarrollo TeamPulse
