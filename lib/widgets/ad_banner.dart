import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// IDs de teste do AdMob — substitua pelos seus IDs reais antes de publicar
const _adUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _adUnitIdIos = 'ca-app-pub-3940256099942544/2934735716';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _carregado = false;
  bool _iniciou = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciou) {
      _iniciou = true;
      _carregarAd();
    }
  }

  Future<void> _carregarAd() async {
    final largura = MediaQuery.of(context).size.width.truncate();
    final tamanho = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(largura);
    if (tamanho == null || !mounted) return;

    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    _banner = BannerAd(
      adUnitId: isIos ? _adUnitIdIos : _adUnitIdAndroid,
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
