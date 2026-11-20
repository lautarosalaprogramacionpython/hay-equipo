# Hay Equipo — Rediseño UX/UI y prompt para Copilot

Nov 20, 2026 · @lautisala

## Alcance y estado

No pude editar Hay Equipo en esta sesión: el proyecto no está disponible aquí, así que no hay ZIP y no se ejecutaron `flutter analyze` ni el build web. Este documento cubre la opción 3 de tu pedido: propuesta visual concreta y un prompt técnico para Copilot.

- El workspace estaba vacío, sin adjuntos y sin GitHub vinculado; no inspeccioné pantallas, tema ni navegación reales.
- Los nombres de archivos y clases del prompt son hipótesis habituales en Flutter. El prompt obliga a Copilot a inspeccionar primero y a ajustarse a lo que encuentre.
- La propuesta visual no depende del código: se aplica sobre cualquier estructura de widgets existente.
- Si adjuntas el proyecto (sin build ni credenciales) o conectas GitHub, puedo aplicar los cambios, validarlos y armar el ZIP yo.

## Propuesta visual: "Noche de cancha"

La dirección es un vestuario nocturno con marcador de estadio: fondo verde casi negro, verde cancha vivo como color de acción, naranja pelota como acento y tarjetas con jerarquía clara. Existe también una variante clara, "Día de potrero". Ambas se definen por roles semánticos para que los temas de color del usuario sigan mandando.

### Paleta (tema por defecto)

| Rol | Oscuro | Claro | Uso |
| --- | --- | --- | --- |
| Fondo | #0E1512 | #F5F8F4 | Scaffold de todas las pantallas |
| Superficie | #16211C | #FFFFFF | Tarjetas, listas, burbujas ajenas |
| Superficie elevada | #1F2E27 | #FFFFFF con sombra suave | Hojas inferiores, menús, campo de chat |
| Texto | #F2F7F4 | #0F1B15 | Títulos y cuerpo |
| Texto secundario | #A9BDB3 | #4A5E54 | Metadatos, horas, ayudas |
| Primario (cancha) | #2EE08A | #0A7A4B | Botón principal, ítem activo, burbujas propias |
| Sobre primario | #04140C | #FFFFFF | Texto e iconos sobre el primario |
| Acento (pelota) | #FF8A3D | #C2410C | Cupos que se agotan, novedades, llamadas a la acción secundarias |
| Sobre acento | #1A0A00 | #FFFFFF | Texto sobre el acento |
| Alerta (tarjeta amarilla) | #FFD23F | #FFD23F | Solo como relleno, con texto #1A1400; nunca como texto sobre claro |
| Peligro (tarjeta roja) | #FF6B6B | #C62828 | Reportes, acciones destructivas |
| Borde de controles | #4E6B5C | #7A8F84 | Campos, chips, tarjetas seleccionables |

Contraste calculado con la fórmula WCAG 2.x: todos los pares de texto de la tabla quedan en 5,0:1 o más (el mínimo es primario claro sobre fondo, 5,03:1) y los bordes de controles superan 3:1 (3,16:1 y 3,22:1). Nunca se comunica un estado solo con color: va acompañado de icono y texto.

### Temas de color del usuario

- Las pantallas no usan hexadecimales: leen `Theme.of(context).colorScheme` y una extensión de tema propia (`ThemeExtension`) para los roles que Material no cubre (acento, alerta, borde de control, superficie elevada).
- Cada tema de color existente sigue definiendo primario y acento. De ahí se derivan contenedores, bordes y el color "sobre" cada uno según luminancia, de modo que el texto sobre el color elegido por el usuario mantenga 4,5:1 sin cambiar el color elegido.
- La paleta de arriba es solo el tema por defecto; no reemplaza ni renombra las opciones que ya existen.

### Tipografía

- Titulares y marcadores: Barlow Condensed (SemiBold/Bold), licencia OFL. Aporta tono deportivo sin perder legibilidad.
- Cuerpo y etiquetas: Inter (Regular/Medium/SemiBold), licencia OFL.
- Escala: display 32/36, título 22/28, sección 18/24, cuerpo 16/24, etiqueta 13/16. Horas, cupos y contadores usan cifras tabulares (`FontFeature.tabularFigures()`).
- Las fuentes se incluyen como assets locales, sin descarga en ejecución, para que la demo web funcione sin red. Debe soportar escala de texto del sistema hasta 200 % sin desbordes.

### Componentes y forma

- Radios: 16 en tarjetas, 12 en chips y campos, botones de 48 de alto con forma de píldora.
- Profundidad: en oscuro, por tono de superficie; en claro, sombra suave de baja opacidad.
- Tarjeta de partido tipo marcador: hora grande, zona, formato, cupos con barra de progreso y estado.
- Avatar con anillo: gradiente primario a acento en stories sin ver, borde neutro en vistas.
- Escudos de equipo generados con `CustomPainter` a partir de iniciales y colores del tema, y fondo de cabeceras con trazos de cancha dibujados por código. Son recursos originales, sin escudos, logos ni marcas de terceros.
- Iconos: Material Icons (Apache 2.0), con un único grosor y estilo en toda la app.

### Movimiento

- Duraciones de 150 a 250 ms con `Curves.easeOutCubic`.
- Entrada escalonada de listas (40 ms entre ítems, máximo 8) y pulsación con escala 0,98 en tarjetas y botones.
- Indicador animado en la navegación y pulso suave en el botón de voz mientras se graba.
- Si el sistema pide reducir movimiento (`MediaQuery.disableAnimations`), todo pasa a fundidos de 100 ms o a cambio instantáneo.
