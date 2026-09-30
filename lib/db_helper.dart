import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    if (kIsWeb) {
      // La vista previa en Edge/Chrome usa IndexedDB (ver AGENTS.md §2).
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        'control_repartos.db',
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
          CREATE TABLE viajes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plataforma TEXT,
            monto REAL,
            fecha TEXT
          )
        ''');
        },
      );
    }
    String ruta = join(await getDatabasesPath(), 'control_repartos.db');
    return await openDatabase(
      ruta,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE viajes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plataforma TEXT,
            monto REAL,
            fecha TEXT
          )
        ''');
      },
    );
  }

  /// Normaliza a las 3 plataformas canónicas (ver AGENTS.md).
  static String normalizarPlataforma(String input) {
    final v = input.trim().toLowerCase();
    if (v.contains('pedidos')) return 'PedidosYa';
    if (v.contains('mercado') || v == 'mp') return 'Mercado Pago';
    if (v == 'pedidosya') return 'PedidosYa';
    if (v == 'mercado pago') return 'Mercado Pago';
    // Si ya es una canónica con distinto case, devolver canónica.
    if (v == 'otros') return 'Otros';
    // Dropdown siempre manda canónica; texto libre cae a Otros.
    return 'Otros';
  }

  // CREATE
  static Future<int> insertarViaje(String plataforma, double monto,
      {DateTime? fecha}) async {
    final baseDatos = await db;
    return await baseDatos.insert('viajes', {
      'plataforma': normalizarPlataforma(plataforma),
      'monto': monto,
      'fecha': (fecha ?? DateTime.now()).toIso8601String(),
    });
  }

  // READ todos
  static Future<List<Map<String, dynamic>>> obtenerViajes() async {
    final baseDatos = await db;
    return await baseDatos.query('viajes', orderBy: 'id DESC');
  }

  // READ por rango [inicio, fin] inclusive. Fechas ISO8601 => BETWEEN lexicográfico válido.
  static Future<List<Map<String, dynamic>>> obtenerViajesPorRango(
      DateTime inicio, DateTime fin) async {
    final baseDatos = await db;
    return await baseDatos.query(
      'viajes',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
      orderBy: 'id DESC',
    );
  }

  // UPDATE (editar un registro: plataforma, monto y/o fecha)
  static Future<int> actualizarViaje(
      int id, String plataforma, double monto, DateTime fecha) async {
    final baseDatos = await db;
    return await baseDatos.update(
      'viajes',
      {
        'plataforma': normalizarPlataforma(plataforma),
        'monto': monto,
        'fecha': fecha.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE
  static Future<int> eliminarViaje(int id) async {
    final baseDatos = await db;
    return await baseDatos.delete('viajes', where: 'id = ?', whereArgs: [id]);
  }
}
