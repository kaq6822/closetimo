// 설정 화면의 외부 링크(개인정보처리방침) 열기. 앱은 서버와 통신하지 않으므로
// 링크는 OS 기본 브라우저에 맡기고, 앱 안에서 네트워크 요청을 보내지 않는다.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 스토어 심사에 제출된 영구 URL이다. 경로를 바꾸지 않는다.
final Uri privacyPolicyUri = Uri.parse(
  'https://kaq6822.github.io/smulsmul/apps/closetimo/privacy/',
);

abstract interface class LinkOpener {
  /// [uri]를 OS 기본 브라우저로 연다. 열지 못하면 false.
  Future<bool> open(Uri uri);
}

class PlatformLinkOpener implements LinkOpener {
  const PlatformLinkOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (e) {
      debugPrint('Failed to open link: $e');
      return false;
    }
  }
}

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const PlatformLinkOpener(),
);
