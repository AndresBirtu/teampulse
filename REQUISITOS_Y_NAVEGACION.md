# TeamPulse - Diagrama de Navegación y Requisitos

## 📍 Tabla de Contenidos
1. [Diagrama de Navegación General](#diagrama-de-navegación-general)
2. [Flujos de Navegación por Rol](#flujos-de-navegación-por-rol)
3. [Requisitos Funcionales](#requisitos-funcionales)
4. [Requisitos No Funcionales](#requisitos-no-funcionales)

---

## 📱 Diagrama de Navegación General

### Estructura de Navegación Global

```
┌────────────────────────────────────────────────────────────┐
│                    TEAMPULSE APP                           │
└────────────────────────────────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
        ┌──────────────┐         ┌──────────────┐
        │   HomePage   │         │  Splash/Auth │
        │  (No autent) │         │ Loading State│
        └──────────────┘         └──────────────┘
              │                         │
              ├─ Login ────────┐        │
              │                │        │
              └─ Register ─────┤        │
                               │        │
                               └────┬───┘
                                    │
                                    ▼
                        ┌─────────────────────┐
                        │  DashboardPage      │
                        │  (Authenticated)    │
                        └─────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
              ┌─────▼────┐  ┌──────▼──────┐  ┌────▼─────┐
              │  HOME    │  │  CALENDAR   │  │ MATCHES  │
              │Dashboard │  │  Calendar   │  │Partidos  │
              └──────────┘  └─────────────┘  └──────────┘
                    │               │               │
                    │               │               ▼
                    │               │       ┌──────────────────┐
                    │               │       │ MatchDetailsPage │
                    │               │       │ (View/Edit Stats)│
                    │               │       └──────────────────┘
                    │               │
              ┌─────▼──────────────▼────────┐
              │   PLAYERS | STATS | PROFILE │
              │ (BottomNavigation Tabs)     │
              └─────────────────────────────┘
```

### Bottom Navigation - Estructura Principal

```
┌─────────────────────────────────────────────────────────────┐
│                     TEAMPULSE MAIN                          │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Content Page (dinámico)                   │  │
│  │  Cambia según tab seleccionado                       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ [🏠]     [📅]        [⚽]        [📊]      [👤]           │
│HOME   CALENDAR    MATCHES    STATS    PROFILE           │
│ TAB      TAB       TAB        TAB       TAB              │
└─────────────────────────────────────────────────────────────┘
```

### Mapa Detallado de Navegación por Páginas

```
NIVEL 0: AUTENTICACIÓN
├── HomePage
│   ├── LoginTab
│   │   └─ Campos: Email, Contraseña
│   │   └─ Botones: Login, Olvidé Contraseña
│   │   └─ Navega a: DashboardPage (si autenticación exitosa)
│   │   └─ Navega a: ForgotPasswordPage (si olvida contraseña)
│   │
│   └── RegisterTab
│       ├─ Tipo Usuario: Entrenador / Jugador
│       ├─ Campos comunes: Nombre, Email, Contraseña
│       │
│       ├─ Si Entrenador:
│       │  └─ Campo: Nombre del Equipo
│       │  └─ Sistema genera: Código equipo (AAA123)
│       │  └─ Navega a: DashboardPage
│       │
│       └─ Si Jugador:
│           └─ Campo: Código del Equipo
│           └─ Sistema valida: Equipo existe
│           └─ Navega a: DashboardPage
│
├── ForgotPasswordPage
│   ├─ Input: Email
│   └─ Acción: Enviar email de recuperación
│   └─ Navega a: HomePage (después de enviar)


NIVEL 1: PÁGINAS PRINCIPALES (BottomNavigation)
├── DashboardPage (HOME) ⭐ Default
│   ├─ Saludo personalizado + Avatar
│   ├─ _NextMatchCard (Tarjeta próximo partido)
│   │  └─ Click: Navega a MatchesPage → Detalle partido
│   ├─ Stats generales: Jugados, Ganados, Perdidos
│   ├─ Racha de victorias
│   ├─ Buttons: Ver Jugadores, Próximo Partido, Entrenamientos
│   │  └─ Ver Jugadores → PlayersPage
│   │  └─ Entrenamientos → TrainingsPage
│   └─ Elemento solo Entrenador: Invitar jugadores (QR/Código)
│
├── CalendarPage (CALENDAR)
│   ├─ Calendar widget interactivo
│   ├─ Eventos: Partidos (🟢 próximos, 🔵 pasados)
│   ├─ Eventos: Entrenamientos (⚪ amarillos)
│   ├─ Click evento: Navega a detalle (MatchesPage o TrainingsPage)
│   └─ Filter: Mostrar/Ocultar partidos/entrenamientos
│
├── MatchesPage (MATCHES)
│   ├─ Lista de partidos
│   ├─ FAB (+): Crear Partido (Solo Entrenador)
│   │  └─ Navega a: CreateMatchPage
│   │
│   ├─ Cada Match Card:
│   │  ├─ Rival vs Nuestro Equipo
│   │  ├─ Fecha/Hora/Ubicación
│   │  ├─ Botón "Disponibilidad": Marcar/Desmarcar (Jugador)
│   │  ├─ Botón "Estadísticas": Navega a MatchStatsEditorPage
│   │  ├─ Botón "Editar": Navega a EditMatchPage (Solo Entrenador)
│   │  └─ Botón "Eliminar": (Solo Entrenador)
│   │
│   ├─ CreateMatchPage (Modal/New Page)
│   │  ├─ Campos: Rival, Fecha, Hora, Ubicación, Alineación
│   │  ├─ Button: Crear
│   │  └─ Vuelve a: MatchesPage (con nuevo partido agregado)
│   │
│   ├─ EditMatchPage (Modal/New Page)
│   │  ├─ Edita campos del partido
│   │  ├─ Marca resultado si ya jugó
│   │  ├─ Button: Guardar
│   │  └─ Vuelve a: MatchesPage (actualizado)
│   │
│   └─ MatchStatsEditorPage
│       ├─ Para cada jugador convocado:
│       │  ├─ Nombre, Posición
│       │  ├─ Spinner: Goles, Asistencias, Minutos
│       │  ├─ Tarjetas: Amarilla, Roja
│       │  └─ Lesión: Toggle
│       ├─ Button: Guardar
│       └─ Vuelve a: MatchesPage
│
├── FullStatsPage (STATS)
│   ├─ Tab 1: Team Stats (estadísticas equipo)
│   │  ├─ Stats generales: Jugados, Ganados, Perdidos, Empates
│   │  ├─ Goles a favor, en contra, diferencia
│   │  ├─ Tabla de posiciones (si hay liga)
│   │  └─ Racha actual
│   │
│   ├─ Tab 2: Player Rankings
│   │  ├─ Top 5 Goleadores
│   │  ├─ Top 5 Asistentes
│   │  ├─ Jugadores con más minutos
│   │  ├─ Jugadores más consistentes
│   │  └─ Click en jugador: Navega a PlayerProfilePage
│   │
│   └─ Tab 3: Full Season Stats (si aplica)
│       └─ Detalles por mes, posición, etc.
│
└── PlayerProfilePage (PROFILE)
    ├─ Avatar + Nombre
    ├─ Si es entrenador: Ve su perfil
    │  └─ Email, Equipo, Código equipo
    │  └─ Button: Invitar jugadores
    │  └─ Button: Ver Equipo
    │
    ├─ Si es jugador: Ve su perfil
    │  ├─ Email, Posición, Número
    │  ├─ Avatar editble (camera/gallery picker)
    │  ├─ Stats personales (Goles, Asistencias, Minutos total)
    │  ├─ Button: Editar Perfil
    │  │  └─ Navega a: EditPlayerPage
    │  └─ Button: Entrenamientos Perdidos
    │     └─ Muestra lista de entrenamientos sin asistencia
    │
    ├─ Ajustes
    │  ├─ Idioma (ES, EN)
    │  ├─ Tema (Light/Dark)
    │  ├─ Notificaciones: Toggle
    │  └─ Privacidad: Ver datos personales
    │
    ├─ Sección Legal
    │  ├─ Términos de Servicio
    │  ├─ Política de Privacidad
    │  └─ Acerca de
    │
    ├─ EditPlayerPage (Modal/New Page)
    │  ├─ Editar: Nombre, Email, Posición
    │  ├─ Button: Guardar
    │  └─ Button: Eliminar Cuenta
    │  └─ Vuelve a: PlayerProfilePage
    │
    └─ Button: Cerrar Sesión
        └─ Navega a: HomePage (logout)


NIVEL 2: PÁGINAS SECUNDARIAS (Desde BottomNav o Modals)
├── PlayersPage
│   ├─ Entrada: Desde DashboardPage o BottomNav Tab
│   ├─ Lista de jugadores del equipo
│   ├─ FAB (+): Agregar Jugador (Solo Entrenador)
│   │  └─ Navega a: CreatePlayerPage
│   │
│   ├─ Filtros: Por posición, por disponibilidad
│   ├─ Ordenamiento: A-Z, Posición, Goles, Asistencias
│   │
│   ├─ Cada Player Card:
│   │  ├─ Avatar, Nombre, Posición
│   │  ├─ Stats: Goles, Asistencias, Minutos
│   │  ├─ Estado: Activo/Lesionado/Suspendido
│   │  ├─ Button: Editar (Solo Entrenador)
│   │  │  └─ Navega a: EditPlayerPage
│   │  ├─ Button: Marcar Lesión (Solo Entrenador)
│   │  │  └─ Toggle lesión + Modal: Días estimados de baja
│   │  ├─ Button: Ver Perfil (Click en card)
│   │  │  └─ Navega a: PlayerProfilePage (detalles jugador)
│   │  └─ Button: Eliminar (Solo Entrenador, swipe o menú)
│   │     └─ Confirmación: ¿Eliminar jugador?
│   │
│   ├── CreatePlayerPage
│   │   ├─ Campos: Nombre, Email, Posición, Número dorsal
│   │   ├─ Si Entrenador: Crea y envía invitación por email
│   │   ├─ Button: Crear
│   │   └─ Vuelve a: PlayersPage
│   │
│   └── EditPlayerPage
│       ├─ Edita datos del jugador
│       ├─ Button: Guardar
│       └─ Vuelve a: PlayersPage
│
├── TrainingsPage
│   ├─ Lista de entrenamientos
│   ├─ FAB (+): Crear Entrenamiento (Solo Entrenador)
│   │  └─ Navega a: CreateTrainingPage
│   │
│   ├─ Cada Training Card:
│   │  ├─ Fecha, Hora, Ubicación (si existe)
│   │  ├─ Notas/Descripción
│   │  ├─ Asistencia: x/y jugadores
│   │  ├─ Button: Editar (Solo Entrenador)
│   │  │  └─ Navega a: EditTrainingPage
│   │  ├─ Button: Ver Asistencia
│   │  │  └─ Navega a: TrainingAttendancePage
│   │  └─ Button: Eliminar (Solo Entrenador)
│   │     └─ Confirmación
│   │
│   ├── CreateTrainingPage
│   │   ├─ Campos: Fecha, Hora, Ubicación, Notas
│   │   ├─ Button: Crear
│   │   └─ Vuelve a: TrainingsPage
│   │
│   ├── EditTrainingPage
│   │   ├─ Edita entrenamiento
│   │   ├─ Button: Guardar
│   │   └─ Vuelve a: TrainingsPage
│   │
│   └── TrainingAttendancePage
│       ├─ Lista de jugadores
│       ├─ Toggle: Presente/Ausente
│       ├─ Button: Guardar (si es entrenador)
│       └─ Solo visualización (si es jugador)
│
├── LanguageSettingsPage
│   ├─ Entrada: Desde ProfilePage (icono 🌐)
│   ├─ Opciones: Español (ES), English (EN)
│   ├─ Actual: Resaltado con checkmark
│   ├─ Click idioma: Cambia idioma global
│   │  └─ Recarga UI automáticamente
│   └─ Vuelve a: ProfilePage (atrás automático)
│
└── EditPlayerPage (From PlayerCard)
    ├─ Entrada: Desde PlayersPage (Card click)
    ├─ Edita jugador
    ├─ Button: Guardar
    ├─ Button: Eliminar (con confirmación)
    └─ Vuelve a: PlayersPage


RUTAS CON PARÁMETROS:
├── /player/{playerId}
│   └─ Abre PlayerProfilePage con datos del jugador específico
│
├── /match/{matchId}
│   └─ Abre MatchDetailsPage o EditMatchPage
│
├── /team/{teamId}
│   └─ Abre DashboardPage con equipo específico
│
├── /training/{trainingId}
│   └─ Abre EditTrainingPage o TrainingAttendancePage
│
└── /inviteCode/{teamCode}
    └─ Permite jugador unirse a equipo con código
```

---

## 🔄 Flujos de Navegación por Rol

### Flujo Entrenador

```
LOGIN
  │
  ▼
DASHBOARD ────┬─────────────────┬───────────────┐
  │           │                 │               │
  ▼           ▼                 ▼               ▼
JUGADORES  PARTIDOS         ENTRENAMIENTOS  CALENDAR
  │ (CRUD)   │ (CRUD)           │ (CRUD)       │
  │          │                  │              │
  ├─Create  ├─Create           ├─Create       │
  │ Player  │ Match            │ Training     │
  │         │                  │              │
  ├─Edit    ├─Edit Match       ├─Edit         │
  │ Player  │ (Resultado)      │ Training     │
  │         │                  │              │
  ├─Delete  ├─Stats Editor     ├─Attendance   │
  │ Player  │ (Goals, Assist)  │ Tracking     │
  │         │                  │              │
  └─Marcar  ├─Convocatoria     └─Eliminar     │
    Lesión  │                                 │
           └─Eliminar                        │
                                             │
                                  ┌──────────┘
                                  │
                                  ▼
                        PROFILE (Entrenador)
                          │
                          ├─Invitar Jugadores (QR)
                          ├─Ver Estadísticas Equipo
                          ├─Configuración Idioma
                          ├─Cerrar Sesión
                          └─Ver Términos/Privacidad
```

### Flujo Jugador

```
LOGIN/REGISTRO (Código Equipo)
  │
  ▼
DASHBOARD ────┬─────────────────┬───────────────┐
  │           │                 │               │
  ▼           ▼                 ▼               ▼
JUGADORES  PARTIDOS         ENTRENAMIENTOS  CALENDAR
  │ (READ)   │ (READ + toggle)  │ (READ)       │
  │          │                  │              │
  │          ├─Ver Próximo      │              │
  │          │ Partido          │              │
  │          │                  │              │
  │          ├─Confirmar        ├─Ver Fecha    │
  │          │ Disponibilidad   │ Entrenamientos
  │          │ (Toggle)         │              │
  │          │                  │              │
  │          ├─Ver Resultado    └─Marcar       │
  │          │ Partido          Asistencia    │
  │          │                  (si entrenador│
  │          ├─Ver Stats        genera)       │
  │          │ Personales       │              │
  │          │                  │              │
  │          └─Ver Estadísticas └──────────────┤
  │            del Partido              │
  │                                      │
  └──────────────┬───────────────────────┘
                 │
                 ▼
         PROFILE (Jugador)
           │
           ├─Ver Mi Perfil
           ├─Editar Avatar/Posición
           ├─Ver Mis Stats (Goles, Asistencias, Min)
           ├─Entrenamientos Perdidos
           ├─Configuración Idioma
           ├─Cerrar Sesión
           └─Ver Términos/Privacidad
```

---

## ✅ Requisitos Funcionales

### RF1: AUTENTICACIÓN Y AUTORIZACIÓN

#### RF1.1 - Registro de Usuario
- **Descripción**: El sistema debe permitir a nuevos usuarios registrarse
- **Actor**: Usuario no autenticado
- **Precondición**: Usuario tiene email válido
- **Flujo Principal**:
  1. Usuario selecciona tipo de cuenta (Entrenador/Jugador)
  2. Si Entrenador:
     - Ingresa Nombre, Email, Contraseña, Nombre Equipo
     - Sistema valida email único
     - Sistema genera código de equipo (6 caracteres: ABC123)
     - Crea usuario en Firebase Auth
     - Crea documento en Firestore: users/{userId}
     - Crea documento en Firestore: teams/{teamId}
  3. Si Jugador:
     - Ingresa Nombre, Email, Contraseña
     - Ingresa código de equipo (6 caracteres)
     - Sistema valida que código existe
     - Crea usuario en Firebase Auth
     - Crea documento en Firestore: users/{userId}
     - Agrega a teams/{teamId}/players/{playerId}
- **Postcondición**: Usuario autenticado y redirigido a DashboardPage
- **Excepciones**:
  - Email ya existe → Muestra "Email ya registrado"
  - Código equipo inválido → Muestra "Código de equipo no válido"
  - Contraseña < 6 caracteres → Muestra error validación

#### RF1.2 - Login de Usuario
- **Descripción**: Permite a usuarios autenticados iniciar sesión
- **Actor**: Usuario no autenticado
- **Flujo Principal**:
  1. Usuario ingresa Email y Contraseña
  2. Sistema autentica con Firebase Auth
  3. Sistema carga datos de usuario desde Firestore
  4. Redirige a DashboardPage con datos precargados
- **Postcondición**: Usuario autenticado, sesión iniciada
- **Excepciones**:
  - Credenciales incorrectas → "Email o contraseña incorrectos"
  - Usuario no existe → "Usuario no existe"
  - Error conexión → "Error de conexión. Reintentando..."

#### RF1.3 - Cerrar Sesión
- **Descripción**: Permite a usuario cerrar sesión
- **Actor**: Usuario autenticado
- **Flujo Principal**:
  1. Click en botón "Cerrar Sesión" (ProfilePage)
  2. Sistema elimina token de sesión
  3. Redirige a HomePage (Login)
- **Postcondición**: Usuario desautenticado, sesión cerrada

#### RF1.4 - Recuperar Contraseña
- **Descripción**: Permite recuperar contraseña olvidada
- **Actor**: Usuario no autenticado
- **Flujo Principal**:
  1. Click en "¿Olvidaste tu contraseña?" (LoginPage)
  2. Ingresa email
  3. Sistema envía email de recuperación con Firebase
  4. Usuario recibe email con link de recuperación
  5. Usuario cambia contraseña y vuelve a login
- **Postcondición**: Contraseña cambiada, usuario puede iniciar sesión

---

### RF2: GESTIÓN DE JUGADORES

#### RF2.1 - Ver Lista de Jugadores
- **Descripción**: Muestra lista de jugadores del equipo
- **Actor**: Entrenador, Jugador
- **Precondición**: Usuario autenticado, pertenece a un equipo
- **Flujo Principal**:
  1. Abre PlayersPage desde DashboardPage
  2. Sistema carga datos de teams/{teamId}/players
  3. Muestra lista con: Avatar, Nombre, Posición, Goles, Asistencias
  4. Permite filtrar por posición y ordenar
- **Postcondición**: Lista de jugadores visible y actualizada en tiempo real (StreamBuilder)

#### RF2.2 - Agregar Jugador (Entrenador)
- **Descripción**: Permite entrenador crear/invitar jugador
- **Actor**: Entrenador
- **Flujo Principal**:
  1. Click FAB "+" en PlayersPage
  2. Abre CreatePlayerPage
  3. Ingresa: Nombre, Email, Posición, Número dorsal (opcional)
  4. Sistema valida email único en equipo
  5. Click "Crear"
  6. Sistema crea documento en teams/{teamId}/players/{playerId}
  7. Envía email de invitación al jugador (Opcional: link para unirse)
- **Postcondición**: Jugador agregado a equipo, lista actualizada

#### RF2.3 - Editar Jugador (Entrenador)
- **Descripción**: Permite editar datos de jugador
- **Actor**: Entrenador
- **Flujo Principal**:
  1. Abre PlayersPage → Click en jugador → Botón "Editar"
  2. Abre EditPlayerPage con datos precargados
  3. Edita: Nombre, Posición, Número dorsal, Avatar
  4. Click "Guardar"
  5. Sistema actualiza documento en Firestore
- **Postcondición**: Datos actualizados, lista se recarga automáticamente

#### RF2.4 - Eliminar Jugador (Entrenador)
- **Descripción**: Permite eliminar jugador del equipo
- **Actor**: Entrenador
- **Flujo Principal**:
  1. PlayersPage → Click en jugador → Botón "Eliminar"
  2. Muestra diálogo de confirmación
  3. Click "Confirmar Eliminar"
  4. Sistema elimina documento de Firestore
  5. Recarga lista automáticamente
- **Postcondición**: Jugador eliminado, lista actualizada

#### RF2.5 - Marcar Lesión (Entrenador)
- **Descripción**: Permite marcar jugador como lesionado
- **Actor**: Entrenador
- **Flujo Principal**:
  1. PlayersPage → Click en jugador → Botón "Lesión"
  2. Muestra modal para seleccionar:
     - Toggle: Lesionado (Sí/No)
     - Días estimados de baja (spinner: 1-90)
     - Notas (textfield)
  3. Click "Guardar"
  4. Sistema actualiza campo `injured: true` en Firestore
  5. Marca fecha de retorno estimada
- **Postcondición**: Jugador marcado como lesionado, no aparece en alineaciones sugeridas

#### RF2.6 - Ver Perfil de Jugador
- **Descripción**: Ver detalles completos de un jugador
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. PlayersPage → Click en jugador
  2. Abre PlayerProfilePage con:
     - Avatar, Nombre, Posición, Número
     - Stats: Goles, Asistencias, Minutos totales
     - Historial de partidos jugados
     - Porcentaje asistencia entrenamientos
  3. Si es entrenador: Botón "Editar" disponible
- **Postcondición**: Perfil visible con stats completas

---

### RF3: GESTIÓN DE PARTIDOS

#### RF3.1 - Ver Lista de Partidos
- **Descripción**: Muestra lista de partidos del equipo
- **Actor**: Entrenador, Jugador
- **Precondición**: Usuario autenticado
- **Flujo Principal**:
  1. Abre MatchesPage desde BottomNavigation
  2. Sistema carga datos de teams/{teamId}/matches
  3. Ordena por fecha (próximos primero)
  4. Muestra: Rival, Fecha, Hora, Ubicación, Resultado (si jugado)
  5. Actualiza automáticamente con listeners (StreamBuilder)
- **Postcondición**: Lista de partidos visible, actualizada en tiempo real

#### RF3.2 - Crear Partido (Entrenador)
- **Descripción**: Permite crear partido nuevo
- **Actor**: Entrenador
- **Flujo Principal**:
  1. MatchesPage → Click FAB "+"
  2. Abre CreateMatchPage
  3. Ingresa: Rival (string), Fecha (date picker), Hora (time picker), Ubicación
  4. Sistema valida que fecha sea futura
  5. Click "Crear"
  6. Sistema crea documento en teams/{teamId}/matches/{matchId}
  7. Inicializa: played=false, status="NO JUGADO"
- **Postcondición**: Partido creado, aparece en lista, notificación a jugadores

#### RF3.3 - Editar Partido (Entrenador)
- **Descripción**: Permite editar datos del partido
- **Actor**: Entrenador
- **Flujo Principal**:
  1. MatchesPage → Click en partido → Botón "Editar"
  2. Abre EditMatchPage con datos precargados
  3. Edita: Rival, Fecha, Hora, Ubicación
  4. Si ya jugó: 
     - Ingresa resultado (Goles TuEquipo vs Goles Rival)
     - Marca toggle "Jugado"
  5. Click "Guardar"
  6. Sistema actualiza documento en Firestore
- **Postcondición**: Datos actualizados, lista se recarga

#### RF3.4 - Eliminar Partido (Entrenador)
- **Descripción**: Permite eliminar partido
- **Actor**: Entrenador
- **Flujo Principal**:
  1. MatchesPage → Click en partido → Botón "Eliminar"
  2. Muestra confirmación
  3. Click "Confirmar"
  4. Sistema elimina documento de Firestore
- **Postcondición**: Partido eliminado, lista actualizada

#### RF3.5 - Confirmar Disponibilidad (Jugador)
- **Descripción**: Jugador confirma si puede jugar
- **Actor**: Jugador
- **Flujo Principal**:
  1. MatchesPage → Click en partido
  2. Muestra lista de jugadores del equipo
  3. Toggle: Disponible / No Disponible
  4. Sistema guarda en teams/{teamId}/matches/{matchId}/availability/{playerId}
  5. Muestra confirmación visual (checkmark o X)
- **Postcondición**: Disponibilidad guardada, entrenador ve qué jugadores pueden jugar

#### RF3.6 - Registrar Estadísticas de Partido (Entrenador)
- **Descripción**: Registra goles, asistencias, minutos por jugador
- **Actor**: Entrenador
- **Flujo Principal**:
  1. Después del partido: MatchesPage → Click en partido
  2. Botón "Estadísticas del Partido"
  3. Abre MatchStatsEditorPage
  4. Para cada jugador:
     - Spinner: Goles (0+)
     - Spinner: Asistencias (0+)
     - Spinner: Minutos (0-90)
     - Toggle: Tarjeta amarilla/roja
  5. Click "Guardar"
  6. Sistema crea docs en teams/{teamId}/matches/{matchId}/stats/{playerId}
  7. Actualiza stats personales del jugador
- **Postcondición**: Stats registradas, actualizan perfil y rankings

#### RF3.7 - Ver Detalles del Partido
- **Descripción**: Ver información completa y estadísticas del partido
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. MatchesPage → Click en partido
  2. Muestra:
     - Rival, Fecha, Hora, Ubicación
     - Resultado (si jugado)
     - Goleadores (si jugado)
     - Disponibilidad de jugadores
     - Stats individuales
  3. Opciones según rol:
     - Entrenador: Editar, Eliminar, Ver Stats
     - Jugador: Confirmar disponibilidad, Ver Stats
- **Postcondición**: Detalles visibles

---

### RF4: GESTIÓN DE ENTRENAMIENTOS

#### RF4.1 - Ver Lista de Entrenamientos
- **Descripción**: Muestra lista de entrenamientos
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. Abre TrainingsPage desde DashboardPage o BottomNav
  2. Sistema carga datos de teams/{teamId}/trainings
  3. Ordena por fecha
  4. Muestra: Fecha, Hora, Ubicación, Asistencia (x/y)
- **Postcondición**: Lista visible, actualizada en tiempo real

#### RF4.2 - Crear Entrenamiento (Entrenador)
- **Descripción**: Permite crear nuevo entrenamiento
- **Actor**: Entrenador
- **Flujo Principal**:
  1. TrainingsPage → Click FAB "+"
  2. Abre CreateTrainingPage
  3. Ingresa: Fecha, Hora, Ubicación, Notas/Descripción
  4. Click "Crear"
  5. Sistema crea documento en teams/{teamId}/trainings/{trainingId}
  6. Inicializa subcollection playersState/{playerId} con attendance=false para todos
- **Postcondición**: Entrenamiento creado, jugadores notificados

#### RF4.3 - Editar Entrenamiento (Entrenador)
- **Descripción**: Editar datos del entrenamiento
- **Actor**: Entrenador
- **Flujo Principal**:
  1. TrainingsPage → Click en entrenamiento → "Editar"
  2. Abre EditTrainingPage
  3. Edita: Fecha, Hora, Ubicación, Notas
  4. Click "Guardar"
- **Postcondición**: Datos actualizados

#### RF4.4 - Registrar Asistencia (Entrenador)
- **Descripción**: Registrar quién asistió al entrenamiento
- **Actor**: Entrenador
- **Flujo Principal**:
  1. TrainingsPage → Click en entrenamiento → "Ver Asistencia"
  2. Abre TrainingAttendancePage
  3. Lista de jugadores con toggle: Presente/Ausente
  4. Click "Guardar"
  5. Sistema actualiza campos en trainings/{trainingId}/playersState/{playerId}
- **Postcondición**: Asistencia registrada

#### RF4.5 - Eliminar Entrenamiento (Entrenador)
- **Descripción**: Eliminar entrenamiento
- **Actor**: Entrenador
- **Flujo Principal**:
  1. TrainingsPage → Click en entrenamiento → "Eliminar"
  2. Confirmación
  3. Sistema elimina documento
- **Postcondición**: Entrenamiento eliminado

---

### RF5: ESTADÍSTICAS Y VISUALIZACIÓN

#### RF5.1 - Ver Estadísticas del Equipo
- **Descripción**: Muestra stats del equipo actual
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. Abre FullStatsPage desde BottomNav
  2. Tab 1 - Team Stats:
     - Partidos jugados, ganados, perdidos, empates
     - Goles a favor, en contra, diferencia
     - Porcentaje de victorias
     - Racha actual
- **Postcondición**: Stats visibles

#### RF5.2 - Ver Rankings de Jugadores
- **Descripción**: Muestra top goleadores, asistentes, etc.
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. FullStatsPage → Tab 2 - Rankings
  2. Muestra:
     - Top 5 Goleadores (goals)
     - Top 5 Asistentes (assists)
     - Más minutos jugados
     - Más consistentes
  3. Click en jugador: Abre ProfilePage del jugador
- **Postcondición**: Rankings visible

#### RF5.3 - Ver Estadísticas Personales (Jugador)
- **Descripción**: Ver stats personales del jugador
- **Actor**: Jugador
- **Flujo Principal**:
  1. ProfilePage (si es jugador)
  2. Muestra:
     - Goles totales, Asistencias totales, Minutos totales
     - Promedio goles por partido
     - Historial de últimos 5 partidos
- **Postcondición**: Stats personales visibles

---

### RF6: CALENDARIO

#### RF6.1 - Ver Calendario
- **Descripción**: Visualización de eventos en calendario
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. Abre CalendarPage desde BottomNav
  2. Muestra calendario interactivo
  3. Eventos: Partidos (🟢 próximos, 🔵 pasados), Entrenamientos (⚪)
  4. Click en evento: Navega a detalles
- **Postcondición**: Calendario visible, eventos clickeables

#### RF6.2 - Filtrar Eventos
- **Descripción**: Filtrar eventos en calendario
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. CalendarPage → Botones filter
  2. Opciones: Mostrar/Ocultar Partidos, Entrenamientos
  3. Calendario se actualiza según filtros
- **Postcondición**: Eventos filtrados según selección

---

### RF7: GESTIÓN DE CUENTA

#### RF7.1 - Ver/Editar Perfil
- **Descripción**: Editar información personal
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. ProfilePage → Click "Editar Perfil"
  2. Abre EditPlayerPage/EditCoachPage
  3. Edita: Nombre, Email, Posición (jugador), Avatar
  4. Click "Guardar"
- **Postcondición**: Perfil actualizado

#### RF7.2 - Cambiar Idioma
- **Descripción**: Cambiar idioma de la aplicación
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. ProfilePage → Click icono 🌐
  2. Abre LanguageSettingsPage
  3. Opciones: Español, English
  4. Click en idioma
  5. UI recarga en nuevo idioma (EasyLocalization)
- **Postcondición**: Idioma cambiado

#### RF7.3 - Configurar Notificaciones
- **Descripción**: Activar/Desactivar notificaciones
- **Actor**: Entrenador, Jugador
- **Flujo Principal**:
  1. ProfilePage → Ajustes
  2. Toggle: Notificaciones (ON/OFF)
  3. Si ON: Recibe notificaciones de:
     - Nuevo partido (entrenador)
     - Confirmación disponibilidad (entrenador)
     - Nuevo entrenamiento (entrenador)
     - Recordatorio partido/entrenamiento (jugador)
- **Postcondición**: Preferencias guardadas en Firestore

---

### RF8: SISTEMA DE INVITACIÓN

#### RF8.1 - Generar Código de Equipo
- **Descripción**: Sistema genera código único para invitar jugadores
- **Actor**: Entrenador
- **Flujo Principal**:
  1. Registro: Sistema genera automáticamente
  2. ProfilePage: Muestra código actual
  3. Button: "Copiar código" (al portapapeles)
  4. Button: "Generar nuevo código" (invalida anterior)
- **Postcondición**: Código disponible para compartir

#### RF8.2 - Invitar Jugador con Código
- **Descripción**: Jugador se une a equipo con código
- **Actor**: Jugador
- **Flujo Principal**:
  1. Registro → Campo "Código de Equipo"
  2. Ingresa código (AAA123)
  3. Sistema valida en Firestore: teams/?/teamCode == AAA123
  4. Si válido: Se agrega a ese equipo
- **Postcondición**: Jugador en equipo, redirige a DashboardPage

#### RF8.3 - Invitar por QR (Opcional)
- **Descripción**: Compartir código como QR
- **Actor**: Entrenador
- **Flujo Principal**:
  1. ProfilePage → Button "Compartir QR"
  2. Genera QR con código de equipo
  3. Permite compartir/capturar imagen
  4. Jugador escanea QR → Abre app con código prerellenado
- **Postcondición**: QR compartible

---

### RF9: NOTIFICACIONES

#### RF9.1 - Notificación de Nuevo Partido (Entrenador)
- **Descripción**: Notificar cuando entrenador crea nuevo partido
- **Actor**: Sistema (FCM)
- **Flujo Principal**:
  1. Entrenador crea partido
  2. Sistema envía FCM a todos jugadores del equipo
  3. Contenido: "Nuevo partido: TU_EQUIPO vs RIVAL, Fecha XX/XX"
- **Postcondición**: Jugadores notificados

#### RF9.2 - Recordatorio Disponibilidad
- **Descripción**: Recordar jugador confirmar disponibilidad
- **Actor**: Sistema (FCM)
- **Flujo Principal**:
  1. 24h antes del partido
  2. Sistema envía FCM: "Confirma tu disponibilidad para el partido"
  3. Click → Abre MatchesPage con partido
- **Postcondición**: Jugador recordado

#### RF9.3 - Confirmación de Disponibilidad (Entrenador)
- **Descripción**: Notificar entrenador cuando jugador confirma disponibilidad
- **Actor**: Sistema (FCM, opcional)
- **Flujo Principal**:
  1. Jugador marca disponible/no disponible
  2. Sistema envía notificación a entrenador: "JUGADOR confirmó disponibilidad"
- **Postcondición**: Entrenador notificado en tiempo real

---

## ⚡ Requisitos No Funcionales

### RNF1: RENDIMIENTO

#### RNF1.1 - Tiempo de Respuesta
- **Descripción**: La aplicación debe responder rápidamente a acciones del usuario
- **Criterios**:
  - Carga de DashboardPage: < 2 segundos
  - Carga de lista de jugadores: < 1.5 segundos
  - Cambio de tab BottomNav: < 500ms
  - Guardar datos: < 1 segundo
  - Actualizaciones StreamBuilder: < 500ms
- **Medida**: Usar Firebase Performance Monitoring

#### RNF1.2 - Eficiencia de Memoria
- **Descripción**: Uso eficiente de memoria RAM
- **Criterios**:
  - Uso máximo: 150MB en dispositivos con 2GB RAM
  - No memory leaks en listeners StreamBuilder
  - Caché local optimizado
- **Medida**: Profiler de Flutter/Android Studio

#### RNF1.3 - Consumo de Datos
- **Descripción**: Minimizar uso de datos móviles
- **Criterios**:
  - Sincronización incremental (solo cambios)
  - Caché offline-first
  - Imágenes optimizadas (max 100KB per image)
  - Compresión de datos JSON
- **Medida**: Monitoreo de bytes transferidos

---

### RNF2: SEGURIDAD

#### RNF2.1 - Autenticación
- **Descripción**: Autenticación segura de usuarios
- **Criterios**:
  - Usar Firebase Authentication (OAuth 2.0)
  - Contraseñas mínimo 8 caracteres
  - Validar email (OTP o confirmación)
  - Sessions con timeout 30 días
  - Tokens JWT con expiración
- **Estándar**: OWASP Top 10

#### RNF2.2 - Encriptación de Datos
- **Descripción**: Proteger datos sensibles
- **Criterios**:
  - Transmisión: HTTPS/TLS 1.2+
  - Almacenamiento: Firestore con HTTPS
  - Datos locales: Preferencias encriptadas (Shared Preferences con Cipher)
  - PII: Datos personales no en logs
- **Estándar**: NIST SP 800-52 Rev. 2

#### RNF2.3 - Control de Acceso (Authorization)
- **Descripción**: Validar permisos por rol
- **Criterios**:
  - Entrenador: CRUD jugadores, partidos, entrenamientos
  - Jugador: READ-only jugadores, READ-CONFIRM partidos/entrenamientos
  - Firestore Security Rules implementadas
  - Validación server-side en cada operación
- **Medida**: Auditoría de Security Rules

#### RNF2.4 - Protección Contra Ataques
- **Descripción**: Implementar defensas comunes
- **Criterios**:
  - Rate limiting en autenticación (5 intentos por IP, 15min)
  - CSRF tokens si aplica
  - SQL Injection protection: No usar SQL (usar Firestore NoSQL)
  - XSS prevention: Sanitizar inputs
  - Validación de entrada en cliente y servidor
- **Medida**: Pruebas de seguridad regulares

---

### RNF3: DISPONIBILIDAD Y CONFIABILIDAD

#### RNF3.1 - Uptime
- **Descripción**: Disponibilidad del servicio
- **Criterios**:
  - Firebase: 99.95% SLA
  - App debe funcionar con conexión intermitente
  - Caché local para datos críticos
  - Sincronización automática cuando hay conexión
- **Medida**: Monitoreo Firebase

#### RNF3.2 - Manejo de Errores
- **Descripción**: Recuperación elegante de errores
- **Criterios**:
  - Todos los errores manejados con try-catch
  - Mensajes de error claros en español/inglés
  - Retry automático con exponential backoff
  - Logging de errores en Firebase Crashlytics
  - No mostrar stack traces al usuario
- **Medida**: Crashlytics reports

#### RNF3.3 - Backup y Recuperación
- **Descripción**: Protección contra pérdida de datos
- **Criterios**:
  - Firestore automáticamente replicado
  - Backups diarios en Cloud Storage
  - Capacidad de exportar datos personales (GDPR)
  - Recovery RTO < 24h
- **Medida**: Firestore backups configurados

---

### RNF4: ESCALABILIDAD

#### RNF4.1 - Escalabilidad Horizontal
- **Descripción**: Capacidad de soportar múltiples usuarios
- **Criterios**:
  - Soportar 10,000 usuarios simultáneos
  - Database sharding automático (Firestore)
  - Realtime updates sin degradación
  - Load balancing en Firebase
- **Medida**: Load testing con Locust/JMeter

#### RNF4.2 - Escalabilidad Vertical
- **Descripción**: Crecer en complejidad de datos
- **Criterios**:
  - Manejar equipos con 100+ jugadores
  - Histórico de 5 años de partidos/entrenamientos
  - Índices Firestore optimizados
  - Queries eficientes (evitar full scans)
- **Medida**: Firebase Usage Dashboard

---

### RNF5: USABILIDAD

#### RNF5.1 - Interfaz Intuitiva
- **Descripción**: Fácil de usar para usuarios sin experiencia técnica
- **Criterios**:
  - Máximo 3 clics para acciones comunes
  - Iconos reconocibles (Material Design)
  - Feedback visual para todas acciones
  - Confirmaciones para acciones destructivas
  - Undo para operaciones reversibles (si aplica)
- **Medida**: User testing con 10+ usuarios

#### RNF5.2 - Consistencia de Diseño
- **Descripción**: Interfaz uniforme en toda la app
- **Criterios**:
  - Paleta de colores consistente
  - Tipografía estándar (Material Design 3)
  - Espaciado uniforme (8dp grid)
  - Componentes reutilizables
  - Navegación predecible
- **Estándar**: Material Design 3 guidelines

#### RNF5.3 - Tiempo de Aprendizaje
- **Descripción**: Usuarios nuevos aprenden rápido
- **Criterios**:
  - Primera sesión guiada (onboarding)
  - Tooltips en funciones complejas
  - Ayuda contextual
  - Documentación en-app
  - Máximo 15 minutos para usuario promedio
- **Medida**: A/B testing onboarding

#### RNF5.4 - Accesibilidad (A11y)
- **Descripción**: Usable para personas con discapacidades
- **Criterios**:
  - WCAG 2.1 nivel AA
  - Contraste mínimo 4.5:1
  - Textos ampliables (up to 200%)
  - Screen reader compatible
  - Navegación por teclado completa
  - Colores no únicos indicadores de estado
- **Herramientas**: Flutter Semantics, axe DevTools

---

### RNF6: COMPATIBILIDAD

#### RNF6.1 - Compatibilidad de Plataformas
- **Descripción**: Funcionar en múltiples plataformas
- **Criterios**:
  - Android 7.0+ (API 24)
  - iOS 12.0+
  - Dispositivos con 2GB+ RAM
  - Pantallas: 4.5" a 6.7" (mobile), 8"+ (tablet)
  - Orientación: Portrait (primaria), Landscape (soporte)
- **Testing**: Firebase Test Lab

#### RNF6.2 - Compatibilidad de Navegadores (Web, si aplica)
- **Criterios**:
  - Chrome 90+
  - Firefox 88+
  - Safari 14+
  - Edge 90+
  - Mobile browsers (Chrome mobile, Safari mobile)

#### RNF6.3 - Compatibilidad Backwards
- **Descripción**: Mantener compatibilidad con versiones anteriores
- **Criterios**:
  - Datos guardados en v1.0 abren en v1.1
  - No breaking changes en API
  - Migraciones de datos automáticas
  - Versionado semántico (MAJOR.MINOR.PATCH)

---

### RNF7: MANTENIBILIDAD

#### RNF7.1 - Código Limpio
- **Descripción**: Código fácil de mantener y entender
- **Criterios**:
  - Naming conventions claras
  - Funciones/métodos < 50 líneas
  - Máximo 3 niveles de anidación
  - Comments en lógica compleja
  - Evitar código muerto
- **Herramientas**: Dart Analyzer, Flutter Lints

#### RNF7.2 - Documentación
- **Descripción**: Código y funcionalidad documentados
- **Criterios**:
  - Docstrings en todas las funciones/clases
  - README.md con setup instructions
  - API documentation auto-generada (dartdoc)
  - Architecture Decision Records (ADR)
  - Arquitectura documentada (ya hecho)
- **Generador**: dartdoc, Mermaid diagrams

#### RNF7.3 - Testing
- **Descripción**: Cobertura de pruebas adecuada
- **Criterios**:
  - Unit tests: 80%+ de functions
  - Widget tests: 60%+ de widgets
  - Integration tests: Flujos críticos
  - UI tests: Happy path de cada página
  - Pruebas de regresión antes de release
- **Framework**: Flutter Testing + mockito

#### RNF7.4 - Versionamiento
- **Descripción**: Control de versiones adecuado
- **Criterios**:
  - Versionado semántico (1.0.0)
  - Changelog actualizado
  - Release notes por versión
  - Tags en Git por versión
  - CI/CD pipeline automatizado

---

### RNF8: LOCALIZACIÓN (I18n)

#### RNF8.1 - Soporte de Idiomas
- **Descripción**: Interfaz en múltiples idiomas
- **Criterios**:
  - Español (ES) como idioma primario
  - Inglés (EN) como idioma secundario
  - Números, fechas, monedas localizados
  - Direcciones de texto (RTL support si aplica)
  - Fuentes que soporten caracteres especiales
- **Framework**: EasyLocalization + arb files

#### RNF8.2 - Localización de Formatos
- **Descripción**: Fechas, horas, números según región
- **Criterios**:
  - Fechas: dd/MM/yyyy (ES), MM/dd/yyyy (EN)
  - Hora: 24h (ES), 12h (EN)
  - Números: 1.000,5 (ES), 1,000.5 (EN)
  - Moneda: € (ES), $ (EN) si aplica

---

### RNF9: PERFORMANCE MOBILE

#### RNF9.1 - Tamaño de APK
- **Descripción**: APK optimizado
- **Criterios**:
  - APK < 100MB (con assets)
  - IOS App < 150MB
  - Usar code splitting si es web
- **Medida**: Flutter APK analyzer

#### RNF9.2 - Consumo de Batería
- **Descripción**: Aplicación eficiente energéticamente
- **Criterios**:
  - Listeners Firebase sin polling activo
  - Uso mínimo de GPS (si aplica)
  - Notificaciones push vs polling
  - Workers limitados en background
- **Medida**: Android Profiler - Battery

#### RNF9.3 - Uso de Ancho de Banda
- **Descripción**: Optimizar uso de datos
- **Criterios**:
  - Imágenes comprimidas (WebP format)
  - Caché HTTP 24h
  - Requests agrupados
  - Compresión GZIP
  - Máximo 5MB/mes usuario promedio
- **Medida**: Network profiler

---

### RNF10: COMPLIANCE Y REGULACIONES

#### RNF10.1 - GDPR (EU)
- **Descripción**: Cumplir GDPR si aplica
- **Criterios**:
  - Consentimiento explícito para datos personales
  - Derecho a ser olvidado (delete account)
  - Data portability (export datos)
  - Privacy policy accesible
  - Data Protection Impact Assessment (DPIA)
- **Referencia**: GDPR Art. 4, 6, 7, etc.

#### RNF10.2 - LGPD (Brasil)
- **Descripción**: Cumplir LGPD si aplica
- **Criterios**:
  - Consentimiento informado
  - Derecho a acceso de datos
  - Derecho a rectificación
  - Derecho a exclusión
  - Datos de menores con consentimiento parental

#### RNF10.3 - App Store Guidelines
- **Descripción**: Cumplir con políticas de tiendas
- **Criterios**:
  - Apple App Store Review Guidelines
  - Google Play Store Policies
  - Términos de servicio claros
  - Política de privacidad actualizada
  - No violaciones de copyright/IP
- **Referencia**: appstoreconnect.apple.com, play.google.com/console

#### RNF10.4 - Política de Privacidad
- **Descripción**: Documento legal claro
- **Contenido**:
  - Qué datos se recolectan
  - Por qué se recolectan
  - Cómo se protegen
  - Derechos del usuario
  - Cómo contactar
- **Lugar**: Accesible desde ProfilePage

---

## 📊 Matriz de Trazabilidad RF vs RNF

| RF / RNF | Rendimiento | Seguridad | Disponibilidad | Usabilidad | Compatibilidad |
|----------|-------------|-----------|----------------|-----------|----|
| RF1 (Auth) | - | **Alta** | - | Alta | Media |
| RF2 (Jugadores) | Alta | Media | - | **Alta** | Baja |
| RF3 (Partidos) | **Alta** | Media | **Alta** | Alta | Baja |
| RF4 (Entrenamientos) | Alta | Media | - | Alta | Baja |
| RF5 (Stats) | **Alta** | - | - | **Alta** | Baja |
| RF6 (Calendario) | Alta | - | - | **Alta** | Baja |
| RF7 (Cuenta) | Media | **Alta** | - | Alta | Baja |
| RF8 (Invitación) | Media | Alta | - | **Alta** | Media |
| RF9 (Notificaciones) | Media | **Alta** | **Alta** | Media | Alta |

---

## 🎯 Conclusión

**Total de Requisitos Funcionales**: 32 (RF1.1 - RF9.3)  
**Total de Requisitos No Funcionales**: 45+ (RNF1.1 - RNF10.4)

La arquitectura soporta todos estos requisitos con:
- **Backend**: Firebase (escalable, seguro, disponible)
- **Frontend**: Flutter (performante, responsive, mantenible)
- **i18n**: EasyLocalization (multiidioma)
- **Real-time**: Firestore listeners (StreamBuilder)
- **Notificaciones**: Firebase Cloud Messaging
- **Almacenamiento**: Cloud Storage + Firestore

---

**Versión**: 1.0  
**Fecha**: Diciembre 2024  
**Autores**: Equipo de Desarrollo TeamPulse
