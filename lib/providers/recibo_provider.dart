import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recibo.dart';
import '../services/database_service.dart';

class ReciboProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Recibo> _recibos = [];
  int _mesCount = 0;
  bool _loading = false;
  Recibo? _lastGenerated;

  List<Recibo> get recibos => _recibos;
  int get mesCount => _mesCount;
  bool get loading => _loading;
  Recibo? get lastGenerated => _lastGenerated;

  static const int freeLimit = 3;

  Future<void> loadRecibos() async {
    _loading = true;
    notifyListeners();
    _recibos = await _db.getAllRecibos();
    await _syncMonthCounter();
    _loading = false;
    notifyListeners();
  }

  Future<List<Recibo>> getRecibosByMonth(int year, int month) async {
    return _db.getRecibosByMonth(year, month);
  }

  /// Zera contador se o mês mudou desde o último uso.
  Future<void> _syncMonthCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final mesRef = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final savedRef = prefs.getString('recibos_mes_ref') ?? '';
    if (savedRef != mesRef) {
      await prefs.setString('recibos_mes_ref', mesRef);
      await prefs.setInt('recibos_mes_count', 0);
    }
    _mesCount = prefs.getInt('recibos_mes_count') ?? 0;
  }

  Future<void> _incrementMonthCounter() async {
    final prefs = await SharedPreferences.getInstance();
    _mesCount = (prefs.getInt('recibos_mes_count') ?? 0) + 1;
    await prefs.setInt('recibos_mes_count', _mesCount);
    notifyListeners();
  }

  bool get isAtFreeLimit => _mesCount >= freeLimit;

  Future<Recibo> saveRecibo(Recibo recibo) async {
    final id = await _db.insertRecibo(recibo);
    final saved = recibo.copyWith(id: id);
    _recibos.insert(0, saved);
    _lastGenerated = saved;
    await _incrementMonthCounter();
    notifyListeners();
    return saved;
  }

  Future<void> deleteRecibo(int id) async {
    await _db.deleteRecibo(id);
    _recibos.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<String> getNextNumeracao() async {
    final next = await _db.getNextNumeracao();
    return next.toString().padLeft(4, '0');
  }

  double get totalMes {
    final now = DateTime.now();
    return _recibos
        .where(
          (r) => r.criadoEm.year == now.year && r.criadoEm.month == now.month,
        )
        .fold(0.0, (sum, r) => sum + r.valor);
  }

  int get clientesUnicosMes {
    final now = DateTime.now();
    return _recibos
        .where(
          (r) => r.criadoEm.year == now.year && r.criadoEm.month == now.month,
        )
        .map((r) => r.clienteNome.toLowerCase())
        .toSet()
        .length;
  }
}
