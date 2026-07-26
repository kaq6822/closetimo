import 'package:closetimo/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy 탭 이름을 절대 경로로 정규화한다', () {
    expect(initialLocationForLastTab('wardrobe'), '/wardrobe');
    expect(initialLocationForLastTab('settings'), '/settings');
  });

  test('현재 절대 경로는 그대로 사용한다', () {
    expect(initialLocationForLastTab('/laundry'), '/laundry');
  });

  test('null, 빈 값, 알 수 없는 값은 홈으로 복구한다', () {
    expect(initialLocationForLastTab(null), '/home');
    expect(initialLocationForLastTab(''), '/home');
    expect(initialLocationForLastTab('unknown'), '/home');
  });
}
