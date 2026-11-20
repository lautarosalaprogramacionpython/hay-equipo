# Hay Equipo · demo reconstruida

Aplicación Flutter para organizar fútbol amateur. Esta entrega reconstruye la
experiencia y la lógica de la demo como una app local-first, preparada para que
un equipo de producción conecte los servicios reales.

## Probar

Requisitos: Flutter estable y Android Studio/SDK para Android. Para iOS hace
falta macOS con Xcode.

```powershell
flutter pub get
flutter run --dart-define=DEMO_MODE=true
```

Vista web:

```powershell
flutter run -d chrome --web-port=7357 --dart-define=DEMO_MODE=true
```

`DEMO_MODE=true` es solo para depuración y la app rechaza esa configuración en
un build release. Sin esa bandera se muestra una pantalla de entrega que aclara
que el inicio conectado todavía necesita integración; no se simula una sesión
real.

## Qué se puede recorrer

- **Inicio:** muro con publicaciones de ejemplo, historias, favoritos y un
  compositor integrado para publicar texto o una foto.
- **Partidos:** crear cruces de fútbol 5 o 7, elegir zona/fecha/hora y cambiar
  el estado de la propuesta.
- **Comunidad:** crear equipo, solicitar un lugar, consultar planteles y buscar
  jugadores por nombre, posición o zona.
- **Chats:** iniciar conversaciones desde jugadores o equipos y enviar mensajes
  de texto.
- **Perfil:** editar nombre, descripción y foto; elegir tema claro/oscuro/sistema
  y activar una pista ambiental instrumental opcional.

Los cambios se guardan en `SharedPreferences` y no salen del dispositivo. Los
jugadores y equipos que no crea la persona son datos ficticios. El directorio,
las solicitudes, los reportes, los estados de partido y los chats no contactan a
otras personas ni notifican a soporte. Las fotos de perfil y del muro quedan en
la base local de la demo; el selector limita su tamaño.

La música es un loop instrumental original de 32 segundos, con capas suaves y
transiciones largas. Empieza apagada y a volumen bajo; no hay sonidos de toque
tipo arcade.

## Estructura nueva

```text
lib/
  main.dart
  app/
    app_shell.dart          # Navegación responsive
    app_theme.dart          # Tema, color y tipografía
    demo_store.dart         # Modelos y persistencia local de la demo
    home_screen.dart
    match_screen.dart
    community_screens.dart
    chat_screens.dart
    profile_screen.dart
    ui_kit.dart
```

`lib/main.dart` no importa las pantallas anteriores. La lógica nueva está en
`lib/app/` y no depende del cliente Firebase previo. Las reglas de Firestore,
Storage y la Cloud Function siguen en el repositorio como material de
referencia; esta demo no las inicializa ni las llama.

## Validación

```powershell
flutter analyze lib/app lib/main.dart
flutter test test/rebuilt_demo_test.dart test/widget_test.dart test/theme_contrast_test.dart
flutter build web --profile --dart-define=DEMO_MODE=true
```

`profile` sirve para validar web con la bandera local: los builds `release` no
permiten `DEMO_MODE`.

## Entrega a producción

Antes de habilitar usuarios reales, el equipo deberá:

1. Implementar onboarding y autenticación telefónica con Firebase Auth, y
   conectar el perfil al modelo de usuarios.
2. Sustituir `DemoStore` por repositorios tipados con Firestore para perfiles,
   equipos, solicitudes, invitaciones, partidos, publicaciones, historias y
   conversaciones.
3. Llevar imágenes y otros adjuntos a Firebase Storage con límites, permisos,
   moderación, retención y eliminación de cuenta definidos.
4. Completar salas de equipo/partido, adjuntos y notas de voz, paginación,
   notificaciones push y resolución real de invitaciones y propuestas.
5. Conectar reportes al backend, App Check y entrega de correo; un reporte de la
   demo solo se guarda localmente.
6. Aprobar privacidad, términos, accesibilidad y analítica; probar reglas,
   flujos SMS y fallos de red con Firebase Emulator Suite y un proyecto
   separado de staging.

No presentar los jugadores ficticios, publicaciones, cambios de estado ni
mensajes de esta demo como contenido compartido. La música y las preferencias
son únicamente locales.
