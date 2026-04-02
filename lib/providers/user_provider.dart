import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  bool _isPro = false;
  String? _logoPath; // TODO: PRO

  bool get isPro => _isPro;
  String? get logoPath => _logoPath; // TODO: PRO

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // TODO: RevenueCat — substituir por verificação de entitlement real
    _isPro = prefs.getBool('is_pro') ?? false;
    _logoPath = prefs.getString('logo_path'); // TODO: PRO
    notifyListeners();
  }

  void setPro(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    notifyListeners();
  }

  // TODO: PRO — chamado após upload de logo via image_picker
  void setLogoPath(String? path) async {
    _logoPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('logo_path', path);
    } else {
      await prefs.remove('logo_path');
    }
    notifyListeners();
  }
}
