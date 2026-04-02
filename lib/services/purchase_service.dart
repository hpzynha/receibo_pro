// TODO: RevenueCat — substituir implementação stub pelo SDK real:
// 1. Adicionar purchases_flutter ao pubspec.yaml
// 2. Inicializar Purchases.configure() no main()
// 3. Substituir startPurchase() por Purchases.purchaseProduct()
// 4. Substituir checkPro() por Purchases.getCustomerInfo()

import '../providers/user_provider.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // TODO: RevenueCat — produtos configurados no dashboard
  // ignore: unused_field
  static const String _monthlyProductId = 'recibo_pro_monthly';
  // ignore: unused_field
  static const String _annualProductId = 'recibo_pro_annual';

  /// Stub para desenvolvimento: apenas seta isPro = true no provider.
  /// TODO: RevenueCat — chamar Purchases.purchaseProduct(_monthlyProductId)
  Future<bool> startPurchase(UserProvider userProvider) async {
    // Simula latência de rede
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: RevenueCat — substituir por chamada real de compra
    userProvider.setPro(true);
    return true;
  }

  /// Verifica se usuário é Pro ao abrir o app.
  /// TODO: RevenueCat — chamar Purchases.getCustomerInfo() e verificar entitlements
  Future<bool> checkPro() async {
    // TODO: RevenueCat — verificar entitlement 'pro'
    return false;
  }

  /// Restaura compras anteriores.
  /// TODO: RevenueCat — chamar Purchases.restorePurchases()
  Future<bool> restorePurchases(UserProvider userProvider) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // TODO: RevenueCat — implementar restore real
    return false;
  }
}
