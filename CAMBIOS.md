# Hay Equipo · reconstrucción de demo

## Entrega actual

- Se reemplazó el punto de entrada y la experiencia anteriores por una app
  local-first nueva, organizada en `lib/app/`.
- Se implementó persistencia propia para perfil, muro, historias, equipos,
  solicitudes, partidos, conversaciones, reportes y preferencias.
- La navegación es responsive: barra inferior en móvil y rail en pantallas
  amplias; los cinco destinos son Inicio, Partidos, Comunidad, Chats y Perfil.
- El muro crea publicaciones de texto/foto desde un compositor integrado.
- El audio se rehízo como una pista instrumental original de 32 segundos,
  discreta y apagada por defecto. No se reproducen efectos arcade.
- La demo declara el almacenamiento local y distingue la experiencia de muestra
  del modo conectado, que queda explícitamente pendiente.
- README documenta cómo ejecutarla, qué cubre y qué debe completar producción.

## Validación

- `dart analyze lib/app lib/main.dart test/rebuilt_demo_test.dart`: sin errores
  ni advertencias; el SDK puede mostrar avisos informativos de deprecación de
  `package:flutter/material.dart`.
- `flutter test test/rebuilt_demo_test.dart`: pasó (3 tests).
- Se generó un bundle web de perfil con `DEMO_MODE=true` para la vista de demo.
  La URL local de prueba es `http://127.0.0.1:7357/`.

## Límites deliberados de la demo

Los perfiles, publicaciones, fotos, equipos, solicitudes, partidos, chats y
reportes se guardan en este dispositivo. Los jugadores de muestra son ficticios;
no hay SMS, sincronización entre usuarios, subida a Storage, adjuntos de chat,
notificaciones ni envío de reportes. La integración segura de esos servicios,
las reglas y las pruebas de staging quedan para la entrega de producción.
