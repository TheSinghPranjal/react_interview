import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/ad_providers.dart';

/// Anchored adaptive banner. Renders nothing until an ad loads, and nothing
/// at all if ads are disabled or loading fails — it can never break layout.
///
/// Place it in `Scaffold.bottomNavigationBar` of content screens; never over
/// interactive answer buttons.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _ad;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  void _maybeLoad() {
    if (_requested || !ref.read(adsEnabledProvider)) return;
    _requested = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    ref.read(adServiceProvider).loadBanner(width).then((ad) {
      if (!mounted) {
        ad?.dispose();
        return;
      }
      setState(() => _ad = ad);
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load once ads become available (e.g. after consent completes).
    ref.listen(adsEnabledProvider, (_, enabled) {
      if (enabled) _maybeLoad();
    });
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Semantics(
        label: 'Advertisement',
        container: true,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
