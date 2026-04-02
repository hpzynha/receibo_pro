import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recibo.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recibo_pro.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recibos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numeracao TEXT NOT NULL,
        prestador_nome TEXT NOT NULL,
        prestador_cpf TEXT NOT NULL,
        cliente_nome TEXT NOT NULL,
        servico TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        observacoes TEXT,
        logo_path TEXT,
        tema TEXT NOT NULL DEFAULT 'minimalista',
        criado_em TEXT NOT NULL
      )
    ''');

    // TODO: Supabase — tabela local espelhará cloud futuramente
    await db.execute('''
      CREATE TABLE prestador (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        cpf TEXT NOT NULL,
        profissao TEXT
      )
    ''');
  }

  // ── Recibos ──────────────────────────────────────────────────────────────

  Future<int> insertRecibo(Recibo recibo) async {
    final db = await database;
    return db.insert('recibos', recibo.toMap()..remove('id'));
  }

  Future<List<Recibo>> getAllRecibos() async {
    final db = await database;
    final maps = await db.query('recibos', orderBy: 'criado_em DESC');
    return maps.map(Recibo.fromMap).toList();
  }

  Future<List<Recibo>> getRecibosByMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query(
      'recibos',
      where: 'criado_em >= ? AND criado_em < ?',
      whereArgs: [start, end],
      orderBy: 'criado_em DESC',
    );
    return maps.map(Recibo.fromMap).toList();
  }

  Future<int> getNextNumeracao() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(id) as max_id FROM recibos',
    );
    final maxId = result.first['max_id'] as int? ?? 0;
    return maxId + 1;
  }

  Future<void> deleteRecibo(int id) async {
    final db = await database;
    await db.delete('recibos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateRecibo(Recibo recibo) async {
    final db = await database;
    await db.update(
      'recibos',
      recibo.toMap(),
      where: 'id = ?',
      whereArgs: [recibo.id],
    );
  }

  // ── Prestador ─────────────────────────────────────────────────────────────

  Future<Map<String, String>?> getPrestador() async {
    final db = await database;
    final maps = await db.query('prestador', limit: 1);
    if (maps.isEmpty) return null;
    final row = maps.first;
    return {
      'nome': row['nome'] as String,
      'cpf': row['cpf'] as String,
      'profissao': row['profissao'] as String? ?? '',
    };
  }

  Future<void> savePrestador(String nome, String cpf,
      {String profissao = ''}) async {
    final db = await database;
    final existing = await db.query('prestador', limit: 1);
    if (existing.isEmpty) {
      await db.insert('prestador', {
        'id': 1,
        'nome': nome,
        'cpf': cpf,
        'profissao': profissao,
      });
    } else {
      await db.update(
        'prestador',
        {'nome': nome, 'cpf': cpf, 'profissao': profissao},
        where: 'id = ?',
        whereArgs: [1],
      );
    }
  }
}
