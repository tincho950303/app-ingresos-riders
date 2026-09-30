import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'db_helper.dart';

// Estilo "Nocturno Soft" — ver AGENTS.md (fuente de verdad). Sin bordes.
const _bg = Color(0xFF0D0F14);
const _surface = Color(0xFF171C26);
const _surfaceVariant = Color(0xFF222936);
const _textPrimary = Color(0xFFF5F7FA);
const _textSecondary = Color(0xFF9AA3B2);
const _accent = Color(0xFF2DD4BF);
const _onAccent = Color(0xFF06251F);
const _danger = Color(0xFFF87171);

const _plataformas = ['PedidosYa', 'Mercado Pago', 'Otros'];

const _shadow = [
  BoxShadow(
      color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 6)),
];

IconData iconoPlataforma(String p) {
  if (p == 'PedidosYa') return Icons.delivery_dining;
  if (p == 'Mercado Pago') return Icons.payments;
  return Icons.more_horiz;
}

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Ganancias',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        cardColor: _surface,
        primaryColor: _accent,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          surface: _surface,
          error: _danger,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: _textPrimary,
              displayColor: _textPrimary,
            ),
        datePickerTheme: const DatePickerThemeData(
          backgroundColor: _surface,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
        chipTheme: ThemeData.dark().chipTheme.copyWith(
              backgroundColor: _surfaceVariant,
              selectedColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              side: BorderSide.none,
            ),
      ),
      home: const PantallaPrincipal(),
    );
  }
}

enum _Tab { dia, semana, ano, periodo }

// ---------------------------------------------------------------------------
// Diálogo compartido: registrar (nuevo) o editar (existente). Sin bordes.
// Devuelve true si se guardó algo.
// ---------------------------------------------------------------------------
Future<bool> mostrarDialogoRegistro(
  BuildContext context, {
  String plataformaInit = 'PedidosYa',
  Map<String, dynamic>? existente,
}) async {
  String plataforma = existente != null
      ? DBHelper.normalizarPlataforma((existente['plataforma'] ?? '').toString())
      : plataformaInit;
  DateTime fecha = existente != null
      ? DateTime.tryParse(existente['fecha'].toString()) ?? DateTime.now()
      : DateTime.now();
  final montoCtrl = TextEditingController(
    text: existente != null ? (existente['monto'] as num).toString() : '',
  );

  InputDecoration inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textSecondary),
        filled: true,
        fillColor: _surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      );

  final guardado = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          existente != null ? 'Editar registro' : 'Registrar en $plataformaInit',
          style: const TextStyle(color: _textPrimary, fontSize: 17),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('App',
                  style:
                      TextStyle(color: _textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in _plataformas)
                    ChoiceChip(
                      label: Text(p),
                      selected: plataforma == p,
                      selectedColor: _accent,
                      backgroundColor: _surfaceVariant,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: plataforma == p
                            ? _onAccent
                            : _textSecondary,
                        fontWeight: plataforma == p
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) =>
                          setD(() => plataforma = p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Día',
                  style:
                      TextStyle(color: _textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Material(
                color: _surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate:
                          DateTime(DateTime.now().year + 2),
                      builder: (c, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme:
                              const ColorScheme.dark(
                                  primary: _accent,
                                  surface: _surface),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setD(() => fecha = picked);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: _accent),
                        const SizedBox(width: 10),
                        Text(
                          '${fecha.day}/${fecha.month}/${fecha.year}',
                          style: const TextStyle(
                              color: _textPrimary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Monto (\$)',
                  style:
                      TextStyle(color: _textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                style: const TextStyle(
                    color: _textPrimary, fontSize: 18),
                decoration: inputDec('Ej. 1500'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _onAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () async {
              final monto = double.tryParse(
                      montoCtrl.text.replaceAll(',', '.')) ??
                  0.0;
              final messenger = ScaffoldMessenger.of(context);
              if (monto <= 0) {
                messenger.showSnackBar(const SnackBar(
                  content:
                      Text('Ingresá un monto válido mayor a 0'),
                  backgroundColor: _surfaceVariant,
                ));
                return;
              }
              if (existente != null) {
                try {
                  await DBHelper.actualizarViaje(
                      existente['id'] as int,
                      plataforma,
                      monto,
                      fecha);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(
                    content: Text('No se pudo guardar: $e'),
                    backgroundColor: _danger,
                  ));
                  return;
                }
              } else {
                try {
                  await DBHelper.insertarViaje(plataforma, monto,
                      fecha: fecha);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(
                    content: Text('No se pudo guardar: $e'),
                    backgroundColor: _danger,
                  ));
                  return;
                }
              }
              montoCtrl.dispose();
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child:
                Text(existente != null ? 'Guardar cambios' : 'Guardar'),
          ),
        ],
      ),
    ),
  );
  return guardado ?? false;
}

// ---------------------------------------------------------------------------
// Pantalla principal: registrar + resumen + exportar. (Sin sección movimientos)
// ---------------------------------------------------------------------------
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  _Tab _tab = _Tab.dia;
  DateTime _fechaBase = DateTime.now();
  DateTimeRange? _periodo;

  List<Map<String, dynamic>> _viajesRango = [];
  bool _cargando = false;
  bool _exportando = false;
  String? _errorDb;

  @override
  void initState() {
    super.initState();
    _cargarRango();
  }

  // ---------- Rangos (semana = lunes a domingo) ----------
  (DateTime, DateTime) _rangoActual() {
    if (_tab == _Tab.dia) {
      final i =
          DateTime(_fechaBase.year, _fechaBase.month, _fechaBase.day);
      final f = i
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      return (i, f);
    }
    if (_tab == _Tab.semana) {
      final base =
          DateTime(_fechaBase.year, _fechaBase.month, _fechaBase.day);
      final inicio =
          base.subtract(Duration(days: base.weekday - 1));
      final fin = inicio
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      return (inicio, fin);
    }
    if (_tab == _Tab.ano) {
      return (
        DateTime(_fechaBase.year, 1, 1),
        DateTime(_fechaBase.year, 12, 31, 23, 59, 59)
      );
    }
    if (_periodo != null) {
      final i = DateTime(_periodo!.start.year,
          _periodo!.start.month, _periodo!.start.day);
      final f = DateTime(_periodo!.end.year,
          _periodo!.end.month, _periodo!.end.day, 23, 59, 59);
      return (i, f);
    }
    final hoy = DateTime.now();
    final i = DateTime(hoy.year, hoy.month, hoy.day);
    return (
      i,
      i.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1))
    );
  }

  String _tituloFecha() {
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final (ini, fin) = _rangoActual();
    if (_tab == _Tab.dia) {
      return '${dias[_fechaBase.weekday - 1]},${_fechaBase.day} - ${_fechaBase.year}';
    }
    if (_tab == _Tab.semana) {
      return '${dias[0]} ${ini.day} ${meses[ini.month - 1]} - ${dias[6]} ${fin.day} ${meses[fin.month - 1]} ${fin.year}';
    }
    if (_tab == _Tab.ano) return '${_fechaBase.year}';
    if (_periodo != null) {
      return '${_periodo!.start.day}/${_periodo!.start.month} - ${_periodo!.end.day}/${_periodo!.end.month} ${_periodo!.end.year}';
    }
    return 'Elegir periodo';
  }

  String _labelTotal() {
    switch (_tab) {
      case _Tab.dia:
        return 'Total del día:';
      case _Tab.semana:
        return 'Total semana:';
      case _Tab.ano:
        return 'Total del año:';
      case _Tab.periodo:
        return 'Total periodo:';
    }
  }

  void _moverFecha(int dir) {
    setState(() {
      if (_tab == _Tab.dia) {
        _fechaBase = _fechaBase.add(Duration(days: dir));
      } else if (_tab == _Tab.semana) {
        _fechaBase = _fechaBase.add(Duration(days: 7 * dir));
      } else {
        _fechaBase = DateTime(
            _fechaBase.year + dir, _fechaBase.month, _fechaBase.day);
      }
    });
    _cargarRango();
  }

  Future<void> _elegirPeriodo() async {
    final ahora = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(ahora.year + 2),
      initialDateRange: _periodo ??
          DateTimeRange(
            start: DateTime(ahora.year, ahora.month, ahora.day)
                .subtract(const Duration(days: 6)),
            end: DateTime(ahora.year, ahora.month, ahora.day),
          ),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: _accent, surface: _surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _periodo = picked);
      _cargarRango();
    }
  }

  // ---------- Datos (se guardan TODOS los ingresos, sin límite) ----------
  Future<void> _cargarRango() async {
    setState(() {
      _cargando = true;
      _errorDb = null;
    });
    try {
      final (ini, fin) = _rangoActual();
      final datos = await DBHelper.obtenerViajesPorRango(ini, fin);
      if (!mounted) return;
      setState(() {
        _viajesRango = datos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorDb = 'Error de base de datos: $e';
      });
    }
  }

  Map<String, double> _totales() {
    final t = {'PedidosYa': 0.0, 'Mercado Pago': 0.0, 'Otros': 0.0};
    for (final v in _viajesRango) {
      final p = DBHelper.normalizarPlataforma(
          (v['plataforma'] ?? '').toString());
      final m = (v['monto'] as num?)?.toDouble() ?? 0.0;
      t[p] = (t[p] ?? 0) + m;
    }
    return t;
  }

  Future<void> _nuevoRegistro(String plataforma) async {
    final ok = await mostrarDialogoRegistro(context,
        plataformaInit: plataforma);
    if (ok) {
      await _cargarRango();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(
          content: Text('Ingreso guardado'),
          backgroundColor: _surfaceVariant,
          duration: Duration(seconds: 2),
        ));
        FocusScope.of(context).unfocus();
      }
    }
  }

  // ---------- Exportar CSV del rango visible ----------
  Future<void> _exportarCsv() async {
    if (_viajesRango.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(
        content: Text('No hay registros en este rango para exportar'),
        backgroundColor: _surfaceVariant,
      ));
      return;
    }
    setState(() => _exportando = true);
    try {
      final filas = <List<dynamic>>[
        ['id', 'plataforma', 'monto', 'fecha'],
        for (final v in _viajesRango)
          [v['id'], v['plataforma'], v['monto'], v['fecha']],
      ];
      final csvStr = const ListToCsvConverter().convert(filas);
      final dir = await getTemporaryDirectory();
      final ahora = DateTime.now();
      final nombre =
          'ganancias_${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}_${ahora.hour.toString().padLeft(2, '0')}${ahora.minute.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}/$nombre');
      await file.writeAsString(csvStr);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        text: 'Mis ganancias (${_viajesRango.length} registros)',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: _danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final totales = _totales();
    final total = totales.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Builder(
          builder: (innerCtx) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // TopBar moderna: botón menú redondeado + título.
                Row(
                  children: [
                    Material(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 4,
                      shadowColor: Colors.black54,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () =>
                            Scaffold.of(innerCtx).openDrawer(),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.menu,
                              color: _textPrimary, size: 22),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text('Control de Ganancias',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
                const SizedBox(height: 14),
                // --- REGISTRAR ---
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Registrar ingreso',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Elegí la app y cargá día + monto',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12)),
                      const SizedBox(height: 14),
                      for (final p in _plataformas)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: _surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(14),
                              onTap: () =>
                                  _nuevoRegistro(p),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.all(
                                              10),
                                      decoration: BoxDecoration(
                                        color: _accent.withValues(
                                            alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(
                                                12),
                                      ),
                                      child: Icon(
                                          iconoPlataforma(p),
                                          color: _accent,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(p,
                                          style: const TextStyle(
                                              color: _textPrimary,
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w500)),
                                    ),
                                    const Icon(
                                        Icons.chevron_right,
                                        color: _textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // --- RESUMEN ---
                _card(
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _tabBtn('Día', _tab == _Tab.dia, () {
                            setState(() => _tab = _Tab.dia);
                            _cargarRango();
                          }),
                          _tabBtn('Semana', _tab == _Tab.semana,
                              () {
                            setState(() => _tab = _Tab.semana);
                            _cargarRango();
                          }),
                          _tabBtn('Año', _tab == _Tab.ano, () {
                            setState(() => _tab = _Tab.ano);
                            _cargarRango();
                          }),
                          _tabBtn('Periodo',
                              _tab == _Tab.periodo, () {
                            setState(
                                () => _tab = _Tab.periodo);
                            _elegirPeriodo();
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          if (_tab != _Tab.periodo)
                            _roundNav(
                                Icons.chevron_left,
                                () => _moverFecha(-1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: GestureDetector(
                              onTap: _tab == _Tab.periodo
                                  ? _elegirPeriodo
                                  : null,
                              child: Text(
                                _tituloFecha(),
                                style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w600),
                              ),
                            ),
                          ),
                          if (_tab != _Tab.periodo)
                            _roundNav(Icons.chevron_right,
                                () => _moverFecha(1)),
                          if (_tab == _Tab.periodo)
                            TextButton(
                              onPressed: _elegirPeriodo,
                              child: const Text('Cambiar',
                                  style: TextStyle(
                                      color: _accent)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_errorDb != null)
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 14),
                          decoration: BoxDecoration(
                            color: _danger.withValues(
                                alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Text(_errorDb!,
                              style: const TextStyle(
                                  color: _danger,
                                  fontSize: 13)),
                        ),
                      if (_cargando)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              color: _accent),
                        ),
                      if (!_cargando) ...[
                        _filaResumen('PedidosYa',
                            totales['PedidosYa']!),
                        _filaResumen('Mercado Pago',
                            totales['Mercado Pago']!),
                        _filaResumen(
                            'Otros', totales['Otros']!),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16),
                          decoration: BoxDecoration(
                            color: _accent.withValues(
                                alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(_labelTotal(),
                                  style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                  '\$${total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: _accent,
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _exportando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _onAccent))
                              : const Icon(
                                  Icons.download,
                                  size: 18),
                          label: Text(_exportando
                              ? 'Exportando...'
                              : 'Exportar CSV (${_viajesRango.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _onAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        14)),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: _exportando
                              ? null
                              : _exportarCsv,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          icon: const Icon(Icons.edit_note,
                              size: 18, color: _textPrimary),
                          label: const Text(
                              'Ver / editar registros',
                              style: TextStyle(
                                  color: _textPrimary)),
                          style: TextButton.styleFrom(
                            backgroundColor: _surfaceVariant,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        14)),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 14),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PaginaRegistros()),
                            );
                            _cargarRango();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _shadow,
      ),
      child: child,
    );
  }

  Widget _roundNav(IconData icon, VoidCallback onTap) {
    return Material(
      color: _surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: _textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Material(
      color: active ? _accent : _surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 10),
          child: Text(label,
              style: TextStyle(
                  color: active ? _onAccent : _textSecondary,
                  fontWeight: active
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _filaResumen(String label, double valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconoPlataforma(label == 'Otros'
                ? 'Otros'
                : label == 'Mercado Pago'
                    ? 'Mercado Pago'
                    : 'PedidosYa'),
                color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: _textPrimary, fontSize: 15)),
          ),
          Text('\$${valor.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20))),
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: _bg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Control de Ganancias',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('100% offline · tus ingresos siempre guardados',
                    style: TextStyle(
                        color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
          _drawerItem(Icons.today, 'Hoy', () {
            setState(() {
              _tab = _Tab.dia;
              _fechaBase = DateTime.now();
            });
            _cargarRango();
            Navigator.pop(context);
          }),
          _drawerItem(Icons.edit_note, 'Ver / editar registros',
              () async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PaginaRegistros()),
            );
            _cargarRango();
          }),
          _drawerItem(Icons.download, 'Exportar CSV', () {
            Navigator.pop(context);
            _exportarCsv();
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(
      IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: _accent, size: 20),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        color: _textPrimary, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Página CRUD: historial completo con editar y borrar por registro.
// ---------------------------------------------------------------------------
class PaginaRegistros extends StatefulWidget {
  const PaginaRegistros({super.key});

  @override
  State<PaginaRegistros> createState() => _PaginaRegistrosState();
}

class _PaginaRegistrosState extends State<PaginaRegistros> {
  List<Map<String, dynamic>> _todos = [];
  bool _cargando = true;
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final datos = await DBHelper.obtenerViajes();
      if (!mounted) return;
      setState(() {
        _todos = datos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error de base de datos: $e'),
        backgroundColor: _danger,
      ));
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_filtro == 'Todos') return _todos;
    return _todos
        .where((v) =>
            DBHelper.normalizarPlataforma(
                (v['plataforma'] ?? '').toString()) ==
            _filtro)
        .toList();
  }

  Future<void> _editar(Map<String, dynamic> v) async {
    final ok =
        await mostrarDialogoRegistro(context, existente: v);
    if (ok) _cargar();
  }

  Future<void> _borrar(Map<String, dynamic> v) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Borrar registro',
            style: TextStyle(color: _textPrimary)),
        content: Text(
          '¿Borrar ${v['plataforma']} \$${v['monto']}?',
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14)),
                elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (conf == true) {
      try {
        await DBHelper.eliminarViaje(v['id'] as int);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo borrar: $e'),
            backgroundColor: _danger,
          ));
        }
        return;
      }
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text('Registros',
            style: TextStyle(color: _textPrimary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in ['Todos', ..._plataformas])
                  ChoiceChip(
                    label: Text(f),
                    selected: _filtro == f,
                    selectedColor: _accent,
                    backgroundColor: _surfaceVariant,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14)),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: _filtro == f
                          ? _onAccent
                          : _textSecondary,
                      fontWeight: _filtro == f
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (_) =>
                        setState(() => _filtro = f),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _accent))
                : _filtrados.isEmpty
                    ? const Center(
                        child: Text(
                            'No hay registros guardados.',
                            style: TextStyle(
                                color: _textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) {
                          final v = _filtrados[i];
                          final p =
                              DBHelper.normalizarPlataforma(
                                  (v['plataforma'] ?? '')
                                      .toString());
                          final m = (v['monto'] as num?)
                                  ?.toDouble() ??
                              0.0;
                          String fecha = '';
                          try {
                            fecha = DateTime.parse(
                                    v['fecha'].toString())
                                .toString()
                                .split(' ')[0];
                          } catch (_) {
                            fecha = v['fecha'].toString();
                          }
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 10),
                            decoration: const BoxDecoration(
                              color: _surface,
                              borderRadius:
                                  BorderRadius.all(
                                      Radius.circular(16)),
                              boxShadow: _shadow,
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4),
                              leading: Container(
                                padding:
                                    const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(
                                      alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                                child: Icon(
                                    iconoPlataforma(p),
                                    color: _accent,
                                    size: 20),
                              ),
                              title: Text(p,
                                  style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight:
                                          FontWeight.w600)),
                              subtitle: Text(fecha,
                                  style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('\$$m',
                                      style: const TextStyle(
                                          color: _textPrimary,
                                          fontWeight:
                                              FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.edit,
                                        color: _accent,
                                        size: 20),
                                    onPressed: () =>
                                        _editar(v),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline,
                                        color: _danger,
                                        size: 20),
                                    onPressed: () =>
                                        _borrar(v),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
