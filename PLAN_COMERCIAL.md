# Hay Equipo — plan comercial revisado

## Decisiones de producto vigentes

- Sin AdMob ni anuncios personalizados.
- Solo promociones patrocinadas, claramente identificadas y revisadas antes
  de publicarse.
- Las consultas de patrocinio se coordinan manualmente por ahora; la app no
  promete publicación automática ni procesa pagos.
- Las sanciones monetarias quedan pausadas. Antes de diseñarlas hay que validar
  el mecanismo, la evidencia, las apelaciones, los pagos y el marco legal. La
  app no debe retener la seña de alquiler ni presentar una penalidad como
  cobrada si no existe un flujo real.
- Los partidos amistosos siguen siendo gratuitos. No se habilita el cobro de
  torneos hasta elegir y configurar el método de pago apropiado para cada tienda.

## Estado y brecha comercial

El proyecto tiene una demo local persistida en el dispositivo y funcionalidades
con integración Firebase. La demo no es una comunidad multiusuario y no prueba
retención, liquidez de partidos ni disposición a pagar. En el código actual no
hay un módulo de torneos pagos ni un sistema de campañas patrocinadas. Por eso
no corresponde proyectar ingresos como si ya existieran transacciones.

La app agrega un acceso de consulta de espacios patrocinados en el perfil. Es
un primer canal de contacto manual, no un marketplace, una campaña activa ni
un procesador de pagos. La salida comercial inicial consiste en conseguir un
patrocinador piloto y acordar manualmente alcance, precio, duración, contenido
y facturación.

## Revisión crítica de las proyecciones del informe recibido

Las cifras siguientes son hipótesis del documento adjunto, no datos verificados
ni una promesa de rentabilidad:

- USD 1.384 de pauta a USD 0,35–0,45 por registro equivale aproximadamente a
  3.076–3.954 registros pagos. El valor de 3.460 corresponde a un CPI medio de
  USD 0,40. Con conversión hipotética del 45% a usuario activo, serían unos
  1.385–1.779 usuarios activos atribuibles a esa pauta, no 15.000. El resto
  dependería de crecimiento orgánico aún no medido.
- La meta de 15.000 MAU representa cerca del 3,5% de un SAM de 430.000, pero
  tanto la tasa de práctica como el porcentaje digitalizado del SAM son
  supuestos del informe y requieren evidencia.
- La suma de los ingresos del escenario base (USD 1.260/mes) y el flujo de caja
  neto publicado (USD 963,33/mes) son aritméticamente consistentes con los
  rubros del documento. Sin embargo, incluyen USD 490/mes de AdMob, que queda
  fuera del modelo vigente, y excluyen el trabajo del fundador, impuestos,
  soporte, moderación, costos variables y la rampa de adquisición.
- Al quitar AdMob, el mismo escenario suma USD 770/mes brutos, antes de
  comisiones, impuestos y trabajo. El umbral de 2.500–3.000 MAU no queda
  demostrado sin explicar cuántas ventas de patrocinios y torneos se producirían
  por cada nivel de usuarios.
- Si se usa solo como ejemplo el precio hipotético de USD 25/mes por patrocinio
  y la comisión hipotética de 6,5% del informe, el ingreso previo a impuestos
  sería alrededor de USD 23,38 por patrocinador. Se necesitarían unos nueve
  patrocinadores activos para cubrir USD 191,67 de costos mensuales declarados;
  no es un precio validado ni un cálculo completo de punto de equilibrio.
- Las estimaciones de CPI, eCPM, conversiones, retención y competidores no
  incluyen enlaces a estudios específicos suficientes para reproducirlas.
  Deben sustituirse por datos de la beta, cotizaciones vigentes y fuentes
  primarias antes de tomar decisiones de inversión.

## Modelo recomendado

### 1. Promociones patrocinadas de venta manual

Priorizar espacios limitados por zona y deporte, etiquetados como
“Patrocinado”. No usar targeting basado en teléfono, geolocalización precisa,
mensajes, historial de reportes ni datos sensibles. Revisar manualmente el
contenido y la identidad del anunciante, definir fecha de vencimiento y llevar
registro de lo publicado y lo cobrado.

El primer piloto debe venderse de forma directa, sin automatizar pagos ni
publicación. Validar:

1. Si comercios u organizadores aceptan pagar por exposición local.
2. Qué zona, deporte y formato generan consultas o inscripciones.
3. Renovación al terminar la campaña.
4. Ingreso neto después de producción, atención, impuestos y comisiones.

### 2. Torneos como producto transaccional posterior

El módulo de fixture y tabla debe tener organizador, reglas, cupo, estados,
resultados auditables, soporte para correcciones y prevención de duplicados.
Primero probar la administración con torneos piloto gratuitos. Cobrar solo
después de medir el valor que reciben los organizadores y confirmar los
requisitos de facturación y pagos de Android/iOS. Un precio de USD 2 es una
hipótesis: evaluar el costo fijo por transacción, moneda local, impuestos y
comisión antes de fijarlo.

### 3. Seña de cancha

Mantener la transferencia directa entre participantes y capitán, sin afirmar
que Hay Equipo custodia, verifica o garantiza fondos. El comprobante requiere
acceso privado, retención definida y procedimientos para disputas. La app no
debe inferir que una transferencia se completó solo porque se adjuntó una
imagen.

### 4. Inasistencias

En esta etapa, limitarse a registrar incidencias con revisión, evidencia,
notificación al jugador y mecanismo de apelación. No cobrar multas ni bloquear
cuentas por reportes no validados. Una mayoría automática no elimina el riesgo
de colusión; definir controles y revisar legalmente antes de cualquier sanción
económica.

## Plan de validación de 90 días

### Días 1–30: preparación de beta

- Corregir y validar los flujos críticos existentes antes de comprar tráfico.
- Elegir un corredor geográfico y un deporte principal; agregar el segundo
  solo si hay organizadores activos.
- Instrumentar métricas consentidas de activación, partido publicado,
  participantes confirmados, partido realizado, cancelación y retorno.
- Acordar manualmente un patrocinio piloto sin mostrar campañas no pagadas.

### Días 31–60: liquidez

- Invitar capitanes y organizadores del mismo corredor.
- Medir partidos completados y tiempo hasta completar cupos; no usar descargas
  como métrica principal.
- Revisar semanalmente quejas, cancelaciones, reportes y retención.
- Probar una promoción patrocinada identificada y medir consultas atribuibles.

### Días 61–90: disposición a pagar

- Ofrecer más de un formato de patrocinio manual y registrar aceptación,
  precio acordado y renovación.
- Pilotear torneos sin cobro hasta tener fixture, resultados y soporte fiables.
- Decidir pagos en app solo con costos, políticas de tienda y requisitos
  fiscales revisados.
- No escalar pauta hasta obtener un costo por jugador que participa en un
  partido completado, no solo costo por instalación.

## Métricas que determinan la viabilidad

- Usuarios activos semanales por zona y deporte.
- Partidos publicados, con cupos completos y efectivamente realizados.
- Tiempo medio para encontrar reemplazo y tasa de cancelación.
- Retención D7/D30 por cohortes.
- CAC por participante que completa un partido.
- Patrocinios vendidos, renovación e ingreso neto por campaña.
- Torneos administrados, finalizados y disposición a pagar.
- Incidencias, falsos reportes y apelaciones.
- Costos de Firebase, almacenamiento, transferencias, soporte y moderación.

## Condiciones antes de automatizar monetización

- Definir quién factura y cómo se registra cada ingreso en Argentina.
- Confirmar políticas vigentes de Google Play y App Store para promociones,
  contenido digital, pagos y aportes.
- Definir tratamiento de datos, consentimiento, borrado y retención.
- Implementar permisos de servidor para crear/aprobar campañas y compras.
- Diseñar reembolsos, fallos de pago, vencimientos, comprobantes y auditoría.
- Configurar límites y alertas de costos de Firebase.

**Conclusión:** el camino de menor riesgo es validar primero una red deportiva
local que complete partidos y vender promociones patrocinadas manualmente. El
informe recibido muestra escenarios posibles, pero no evidencia suficiente
para afirmar que Hay Equipo ya sea rentable ni que alcance 15.000 MAU.
