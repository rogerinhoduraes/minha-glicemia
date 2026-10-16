import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mesmo ID na App Store e no Google Play (compra única, não consumível).
const produtoRemoverAnuncios = 'remover_anuncios';
const _chaveSemAnuncios = 'sem_anuncios';

/// Compra única que remove os anúncios, incluindo cupons das lojas
/// (códigos de oferta da Apple e promocionais do Google), que chegam como compras.
class CompraService with WidgetsBindingObserver {
  CompraService._();
  static final _instancia = CompraService._();

  /// `true` quando o usuário comprou (ou resgatou cupom). Persistido no aparelho.
  static final ValueNotifier<bool> semAnuncios = ValueNotifier(false);

  /// Produto com o preço da loja; `null` se a loja não respondeu.
  static final ValueNotifier<ProductDetails?> produto = ValueNotifier(null);

  static final _iap = InAppPurchase.instance;
  static Future<void>? _init;

  /// Lê o estado salvo e começa a ouvir a loja. Chamar no início do app.
  static Future<void> init() => _init ??= _iniciar();

  static Future<void> _iniciar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      semAnuncios.value = prefs.getBool(_chaveSemAnuncios) ?? false;
    } catch (_) {}

    _iap.purchaseStream.listen(_processar, onError: (_) {});
    WidgetsBinding.instance.addObserver(_instancia);
    unawaited(_carregarProduto());
    // No Android a consulta é silenciosa: recupera compras e cupons resgatados na Play Store.
    if (Platform.isAndroid) unawaited(_restaurarSilencioso());
  }

  static Future<void> _carregarProduto() async {
    try {
      if (!await _iap.isAvailable()) return;
      final resp = await _iap.queryProductDetails({produtoRemoverAnuncios});
      if (resp.productDetails.isNotEmpty) produto.value = resp.productDetails.first;
    } catch (_) {}
  }

  static Future<void> _restaurarSilencioso() async {
    try {
      if (await _iap.isAvailable()) await _iap.restorePurchases();
    } catch (_) {}
  }

  static Future<void> _processar(List<PurchaseDetails> compras) async {
    for (final c in compras) {
      if (c.productID == produtoRemoverAnuncios &&
          (c.status == PurchaseStatus.purchased || c.status == PurchaseStatus.restored)) {
        await _liberar();
      }
      // Sem isso o Google estorna a compra em 3 dias e a Apple a reentrega a cada abertura.
      if (c.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(c);
        } catch (_) {}
      }
    }
  }

  static Future<void> _liberar() async {
    semAnuncios.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chaveSemAnuncios, true);
    } catch (_) {}
  }

  /// Abre a compra da loja. Retorna `false` se o produto não está disponível.
  static Future<bool> comprar() async {
    final p = produto.value;
    if (p == null) {
      await _carregarProduto();
      if (produto.value == null) return false;
    }
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: produto.value!));
  }

  /// Pede à loja as compras já feitas nesta conta (obrigatório na Apple).
  static Future<void> restaurar() => _iap.restorePurchases();

  /// Abre o resgate de cupom da loja. O resultado chega como compra.
  static Future<void> resgatarCupom() async {
    if (Platform.isIOS) {
      await _iap
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
          .presentCodeRedemptionSheet();
    } else {
      await launchUrl(Uri.parse('https://play.google.com/redeem'),
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ao voltar da Play Store (cupom resgatado lá), confere as compras.
    if (state == AppLifecycleState.resumed && Platform.isAndroid && !semAnuncios.value) {
      unawaited(_restaurarSilencioso());
    }
  }
}
