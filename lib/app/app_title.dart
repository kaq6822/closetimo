// 앱 이름 로케일 규칙. 한국어는 "옷장이모", 그 외 로케일은 "Closetimo"를 쓴다.
// 플랫폼 런처 이름(Android values-ko/strings.xml, iOS ko.lproj/InfoPlist.strings)과 같은 규칙이다.

import 'dart:ui';

/// [locale]에 맞는 앱 이름을 돌려준다.
///
/// 앱 UI는 ko 단일 로케일이지만, OS가 보여주는 작업 이름(Android 최근 앱 화면)은
/// 기기 언어를 따라야 하므로 플랫폼 로케일을 넣어 호출한다.
String appTitleFor(Locale locale) =>
    locale.languageCode == 'ko' ? '옷장이모' : 'Closetimo';
