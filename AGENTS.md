# AGENTS.md — Control Ganancias / Registrador de Pedidos

> Fuente de verdad de estilo y arquitectura. Todo cambio de UI o código debe respetar este archivo.

## 1. Estilo propio elegido: "Nocturno Soft" (moderno, sin bordes)

Moderno oscuro tipo fintech: superficies elevadas con sombra suave, SIN bordes visibles en ningún widget. Nada de `BorderSide` ni `Border.all` en la app.

### 1.1 Tokens (no cambiar sin actualizar este archivo)
```dart
bg              = Color(0xFF0D0F14)  // fondo app
surface         = Color(0xFF171C26)  // cards elevadas
surfaceVariant  = Color(0xFF222936)  // chips inactivos, inputs, botones secundarios
textPrimary     = Color(0xFFF5F7FA)
textSecondary   = Color(0xFF9AA3B2)
accent          = Color(0xFF2DD4BF)  // total, tab activa, iconos
onAccent        = Color(0xFF06251F)  // texto sobre accent
danger          = Color(0xFFF87171)  // solo borrar
radius          = 20.0              // cards, diálogos
radiusSmall     = 14.0              // chips, botones, inputs
shadow          = BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: Offset(0, 6))
```

### 1.2 Reglas visuales obligatorias
1. Fondo siempre `bg`. Nunca blanco. PROHIBIDO cualquier borde: no usar `BorderSide`, `Border.all`, `OutlinedButton` ni `enabledBorder` con color. Todo se diferencia por tono + sombra.
2. Toda sección va en `Container` con `color: surface`, `borderRadius: 20` y `shadow`. Sin `Card` con borde.
3. Estructura vertical fija (de arriba a abajo, SIN sección movimientos):
   - `TopBar`: icono `menu` redondeado (fondo `surfaceVariant`, sin borde) que abre Drawer + título centrado.
   - Card `Registrar ingreso`: 3 filas-botón llenas (`surfaceVariant`, radio 14): icono en círculo tintado `accent 15%` + nombre app + chevron `>`. Tap abre el diálogo (día + monto).
   - Card `Resumen`: tabs pill + navegador fecha + filas por plataforma + total destacado en pastilla `accent 15%` + botón primario Exportar CSV (fondo `accent`, texto `onAccent`) + botón secundario Ver/editar (fondo `surfaceVariant`).
   - CRUD en `PaginaRegistros` (pantalla aparte con filtro Todos/app + editar + borrar por registro). Items como tarjetas `surface` con sombra, sin borde.
4. Tabs `Día | Semana | Año | Periodo` como pills: activa = fondo `accent` + texto `onAccent` bold; inactiva = fondo `surfaceVariant` + texto `textSecondary`. Sin bordes.
5. Navegador fecha formato: `< lun,20 - 2026 >` (día), `< lun 14 - dom 20 ene 2026 >`, `< 2026 >`, `< 01/02 - 10/03 >`. Botones `<` `>` como círculos `surfaceVariant`.
6. Filas resumen formato exacto:
   - `PedidosYa: $1234` / `Mercado Pago: $1234` / `Otros: $0`
   - `Total del día: $2468` (o semana/año/periodo) en pastilla destacada, `accent` bold 19.
7. Inputs (diálogo): `filled: true`, `fillColor: surfaceVariant`, `border: OutlineInputBorder(borderRadius: 14, borderSide: BorderSide.none)`. Sin bordes.
8. Sin emojis en UI. Solo Material Icons (`menu`, `delivery_dining`, `payments`, `more_horiz`, `chevron_right`, `calendar_today`, `download`, `edit`, `delete_outline`).
9. Textos en español rioplatense simple.

### 1.3 Plataformas canónicas
```dart
const plataformas = ['PedidosYa', 'Mercado Pago', 'Otros'];
```
- No crear nuevas sin migrar resumen. `Otros` atrapa todo lo no listado.
- Normalizar a estas 3 al guardar (case-insensitive contiene `pedidos` → PedidosYa, `mercado`/`mp` → Mercado Pago, resto → Otros).

## 2. Arquitectura
- `lib/main.dart` → solo UI + estado (StatefulWidget). Sin SQL crudo.
- `lib/db_helper.dart` → todo sqflite. Tablas: `viajes(id, plataforma TEXT, monto REAL, fecha TEXT ISO8601)`. DB: `control_repartos.db`. 100% offline, sin permisos de red.
- Web preview (Edge): `sqflite` NO soporta web, por eso `initDB()` usa `databaseFactoryFfiWeb` (IndexedDB) cuando `kIsWeb` (paquete `sqflite_common_ffi_web` + binarios `web/sqlite3.wasm` y `web/sqflite_sw.js` generados con `dart run sqflite_common_ffi_web:setup`). Si falla la DB, la UI muestra el error en el Resumen en vez de fallar en silencio. La DB web vive por puerto (localhost:8901 tiene sus propios datos).
- Nuevas queries obligatorias: `obtenerViajesPorRango(inicio, fin)` con `WHERE fecha BETWEEN ? AND ?`, `actualizarViaje(id, plataforma, monto, fecha)` para editar, `totalesPorPlataforma(inicio, fin)` calculado en Dart para evitar drift SQL.
- Se guardan TODOS los ingresos sin límite ni borrado automático (tabla `viajes` acumulativa).
- Exportar CSV: botón en Resumen exporta el rango visible a `id,plataforma,monto,fecha` vía `csv + path_provider + share_plus` (offline, comparte a WhatsApp/Drive/archivos).
- Rangos:
  - Día: `[00:00, 23:59:59]` de `fechaBase`.
  - Semana: lunes-domingo que contiene `fechaBase` (`fechaBase.weekday - 1` días atrás). Etiqueta `lun X - dom Y`.
  - Año: `[1-ene, 31-dic]` de `fechaBase.year`.
  - Periodo: `DateTimeRange` elegido por `showDateRangePicker` (estilo dark).
- Diálogo `mostrarDialogoRegistro()`: chips únicos de app + `showDatePicker` de día + campo monto. Reusado para crear y editar.

## 3. Flujo de trabajo en vivo (no romper)
- Dev en tiempo real: `flutter run` (celu USB con depuración o emulador) → Hot Reload `r`, Hot Restart `R`. En Android Studio: botón Run ▶ + `Ctrl+\` / Apply Changes.
- No agregar dependencias de red para ver cambios. Todo debe verse con `flutter run -d windows` o `-d edge` sin backend.
- Antes de commit: `flutter analyze` debe pasar limpio.

## 4. Build offline para celular
- `flutter build apk --release` genera `build/app/outputs/flutter-apk/app-release.apk` (funciona sin internet una vez instalado).
- Instalar: copiar APK por USB / Drive / WhatsApp → abrir en el celu → permitir "instalar apps desconocidas".
- O directo USB: `adb install -r build/app/outputs/flutter-apk/app-release.apk` con `adb` de `$ANDROID_SDK/platform-tools/adb.exe`.
- Nunca pedir login ni internet. Probar en modo avión.

## 5. Checklist del agente antes de entregar
- [ ] Registrar con 3 botones únicos (sin dropdown en home)
- [ ] Diálogo día + monto funciona para crear y editar
- [ ] Sin sección movimientos en home; CRUD en pantalla Registros
- [ ] Semana siempre lunes-domingo
- [ ] Exportar CSV genera archivo y abre compartir
- [ ] Resumen suma = suma de registros del rango
