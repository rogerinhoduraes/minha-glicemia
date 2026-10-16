import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// IDs dos blocos intersticiais criados no console do AdMob.
// Vazios = intersticial desativado em release.
const _intersticialAndroid = 'ca-app-pub-4791753177590529/2039297321';
const _intersticialIos = 'ca-app-pub-4791753177590529/5451094576';

// IDs de teste oficiais do Google — evitam tráfego inválido em debug.
const _testIntersticialAndroid = 'ca-app-pub-3940256099942544/1033173712';
const _testIntersticialIos = 'ca-app-pub-3940256099942544/4411468910';

const _intervaloIntersticial = Duration(minutes: 3);

// `flutter run --dart-define=ADS_EEA=true` simula usuário europeu para testar o formulário.
const _forcarEea = bool.fromEnvironment('ADS_EEA');
// Em aparelho físico a simulação exige o ID de teste que o SDK imprime no log:
// `--dart-define=ADS_TEST_DEVICE=<id>` (emuladores e simuladores dispensam).
const _dispositivoTeste = String.fromEnvironment('ADS_TEST_DEVICE');

/// Consentimento (UMP), ATT e inicialização do SDK do AdMob, além do intersticial.
class AdsService {
  /// Vira `true` quando o SDK foi inicializado e o usuário permite anúncios.
  static final ValueNotifier<bool> pronto = ValueNotifier(false);

  /// Se o usuário precisa de acesso às opções de privacidade (ex.: GDPR).
  static bool precisaOpcoesPrivacidade = false;

  static bool _iniciou = false;
  static InterstitialAd? _intersticial;
  static DateTime? _ultimoIntersticial;

  /// Chamar com o app já visível (formulário de consentimento e ATT precisam de UI ativa).
  static Future<void> init() async {
    if (_iniciou) return;
    _iniciou = true;
    await _coletarConsentimento();
    if (Platform.isIOS &&
        await AppTrackingTransparency.trackingAuthorizationStatus ==
            TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    await _iniciarSdkSePermitido();
  }

  static Future<void> _coletarConsentimento() {
    final concluido = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        consentDebugSettings: kDebugMode && _forcarEea
            ? ConsentDebugSettings(
                debugGeography: DebugGeography.debugGeographyEea,
                testIdentifiers: [if (_dispositivoTeste.isNotEmpty) _dispositivoTeste],
              )
            : null,
      ),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) => concluido.complete()),
      (_) => concluido.complete(), // sem rede: segue com o consentimento já salvo
    );
    return concluido.future;
  }

  static Future<void> _iniciarSdkSePermitido() async {
    precisaOpcoesPrivacidade =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
    if (pronto.value || !await ConsentInformation.instance.canRequestAds()) return;
    await MobileAds.instance.initialize();
    pronto.value = true;
    _carregarIntersticial();
  }

  static Future<void> abrirOpcoesPrivacidade() async {
    final fechado = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) => fechado.complete());
    await fechado.future;
    await _iniciarSdkSePermitido();
  }

  static String get _intersticialId {
    if (kDebugMode) {
      return Platform.isIOS ? _testIntersticialIos : _testIntersticialAndroid;
    }
    return Platform.isIOS ? _intersticialIos : _intersticialAndroid;
  }

  static void _carregarIntersticial() {
    if (!pronto.value || _intersticial != null || _intersticialId.isEmpty) return;
    InterstitialAd.load(
      adUnitId: _intersticialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _intersticial = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  /// Mostra o intersticial se houver um carregado e o intervalo mínimo já passou.
  /// Completa quando o anúncio é fechado, ou na hora se nada for mostrado.
  static Future<void> mostrarIntersticial() async {
    final ad = _intersticial;
    final ultimo = _ultimoIntersticial;
    if (ad == null) {
      _carregarIntersticial();
      return;
    }
    if (ultimo != null && DateTime.now().difference(ultimo) < _intervaloIntersticial) return;

    _intersticial = null;
    _ultimoIntersticial = DateTime.now();
    final fechado = Completer<void>();
    void encerrar(InterstitialAd ad) {
      ad.dispose();
      if (!fechado.isCompleted) fechado.complete();
      _carregarIntersticial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: encerrar,
      onAdFailedToShowFullScreenContent: (ad, _) => encerrar(ad),
    );
    await ad.show();
    return fechado.future;
  }
}
