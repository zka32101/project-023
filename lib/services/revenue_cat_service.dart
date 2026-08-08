import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/logger.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();

  factory RevenueCatService() {
    return _instance;
  }

  RevenueCatService._internal();

  static const String _productId = 'tsukuani_unlimited';
  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> initialize({required String apiKey}) async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(
        PurchasesConfiguration(apiKey)
          ..appUserID = null, // Anonymous user
      );

      _initialized = true;
    } catch (e) {
      AppLogger.error('RevenueCat initialization error', e);
      _initialized = false;
      rethrow;
    }
  }

  Future<bool> isPurchased() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_productId]?.isActive ?? false;
    } catch (e) {
      AppLogger.error('Error checking purchase status', e);
      return false;
    }
  }

  Future<void> purchase() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final package = offerings.current!.availablePackages.firstWhere(
          (p) => p.identifier == _productId,
          orElse: () => offerings.current!.availablePackages.first,
        );
        await Purchases.purchasePackage(package);
      }
    } catch (e) {
      AppLogger.error('Purchase error', e);
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      AppLogger.error('Restore purchases error', e);
      rethrow;
    }
  }

  Future<String?> getProductPrice() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final package = offerings.current!.availablePackages.firstWhere(
          (p) => p.identifier == _productId,
          orElse: () => offerings.current!.availablePackages.first,
        );
        return package.storeProduct.priceString;
      }
    } catch (e) {
      AppLogger.error('Error getting product price', e);
    }
    return null;
  }
}
