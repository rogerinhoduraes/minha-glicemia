import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';

const _adUnitIdAndroid = 'ca-app-pub-4791753177590529/4305778378';
const _adUnitIdIos = 'ca-app-pub-4791753177590529/5836379677';

// IDs de teste oficiais do Google — evitam tráfego inválido em debug.
const _testAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _testAdUnitIdIos = 'ca-app-pub-3940256099942544/2934735716';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _carregado = false;
  bool _iniciou = false;
  bool _pediu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciou) {
      _iniciou = true;
      AdsService.pronto.addListener(_aoFicarPronto);
      _aoFicarPronto();
    }
  }

  void _aoFicarPronto() {
    if (AdsService.pronto.value && !_pediu) {
      _pediu = true;
      _carregarAd();
    }
  }

  Future<void> _carregarAd() async {
    final largura = MediaQuery.of(context).size.width.truncate();
    final tamanho = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(largura);
    if (tamanho == null || !mounted) return;

    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final adUnitId = kDebugMode
        ? (isIos ? _testAdUnitIdIos : _testAdUnitIdAndroid)
        : (isIos ? _adUnitIdIos : _adUnitIdAndroid);

    _banner = BannerAd(
      adUnitId: adUnitId,
      size: tamanho,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _carregado = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _banner = null;
        },
      ),
    );
    await _banner!.load();
  }

  @override
  void dispose() {
    AdsService.pronto.removeListener(_aoFicarPronto);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_carregado || _banner == null) return const SizedBox.shrink();
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
